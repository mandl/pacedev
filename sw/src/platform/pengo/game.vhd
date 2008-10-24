library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.kbd_pkg.in8;
use work.project_pkg.all;

entity Game is
  port
  (
    -- clocking and reset
    clk							: in std_logic_vector(0 to 3);
    reset           : in std_logic;                       
    test_button     : in std_logic;                       

    -- inputs
    ps2clk          : inout std_logic;                       
    ps2data         : inout std_logic;                       
    dip             : in std_logic_vector(7 downto 0);    
		jamma						: in JAMMAInputsType;

    -- micro buses
    upaddr          : out std_logic_vector(15 downto 0);   
    updatao         : out std_logic_vector(7 downto 0);    

    -- SRAM
		sram_i					: in from_SRAM_t;
		sram_o					: out to_SRAM_t;

		gfxextra_data		: out std_logic_vector(7 downto 0);
		palette_data		: out ByteArrayType(15 downto 0);
		
    -- graphics (bitmap)
    bitmap_addr			: in std_logic_vector(15 downto 0);   
    bitmap_data			: out std_logic_vector(7 downto 0);    

    -- graphics (tilemap)
    tileaddr        : in std_logic_vector(15 downto 0);   
    tiledatao       : out std_logic_vector(7 downto 0);    
    tilemapaddr     : in std_logic_vector(15 downto 0);   
    tilemapdatao    : out std_logic_vector(15 downto 0);    
    attr_addr       : in std_logic_vector(9 downto 0);    
    attr_dout       : out std_logic_vector(15 downto 0);   

    -- graphics (sprite)
    sprite_reg_addr : out std_logic_vector(7 downto 0);    
    sprite_wr       : out std_logic;                       
    spriteaddr      : in  std_logic_vector(15 downto 0);   
    spritedata      : out std_logic_vector(31 downto 0);   
    spr0_hit        : in std_logic;

    -- graphics (control)
    vblank					: in std_logic;    
		xcentre					: out	std_logic_vector(9 downto 0);
		ycentre					: out	std_logic_vector(9 downto 0);

    -- OSD
    to_osd          : out to_OSD_t;
    from_osd        : in from_OSD_t;

    -- sound
    snd_rd          : out std_logic;                       
    snd_wr          : out std_logic;
    sndif_datai     : in std_logic_vector(7 downto 0);    

    -- spi interface
    spi_clk         : out std_logic;                       
    spi_din         : in std_logic;                       
    spi_dout        : out std_logic;                       
    spi_ena         : out std_logic;                       
    spi_mode        : out std_logic;                       
    spi_sel         : out std_logic;                       

    -- serial
    ser_rx          : in std_logic;                       
    ser_tx          : out std_logic;                       

    -- on-board leds
    leds            : out std_logic_vector(7 downto 0)    
  );

end Game;

architecture SYN of Game is

	alias clk_30M					: std_logic is clk(0);
	alias clk_40M					: std_logic is clk(1);
	signal cpu_reset			: std_logic;
	
  -- uP signals  
  signal clk_3M_en			: std_logic;
  signal uP_addr        : std_logic_vector(15 downto 0);
  signal uP_datai       : std_logic_vector(7 downto 0);
  signal uP_datao       : std_logic_vector(7 downto 0);
  signal uPmemwr        : std_logic;
	signal uPiowr					: std_logic;
  signal uPintreq       : std_logic;
	signal uPintack				: std_logic;
	signal uPintvec				: std_logic_vector(7 downto 0);
	                        
  -- ROM signals        
	signal rom_cs					: std_logic;
  signal rom_datao      : std_logic_vector(7 downto 0);
                        
  -- keyboard signals
	                        
  -- VRAM signals       
	signal vram_cs				: std_logic;
	signal vram_wr				: std_logic;
	signal vram_addr			: std_logic_vector(9 downto 0);
  signal vram_datao     : std_logic_vector(7 downto 0);
                        
  -- RAM signals        
  signal wram_cs        : std_logic;
  signal wram_wr        : std_logic;
  signal wram_datao     : std_logic_vector(7 downto 0);

  -- RAM signals        
  signal cram_cs        : std_logic;
  signal cram_wr        : std_logic;
	signal cram_up_data		: std_logic_vector(7 downto 0);
	signal cram_data			: std_logic_vector(7 downto 0);
	
  -- interrupt signals
  signal intena_wr      : std_logic;

  -- other signals      
  signal inZero_cs      : std_logic;
  signal inOne_cs       : std_logic;
  signal dip0_cs        : std_logic;
  signal dip1_cs        : std_logic;
	signal inputs					: in8(0 to 2);
	alias game_reset			: std_logic is inputs(2)(0);
	signal newTileAddr		: std_logic_vector(11 downto 0);
  signal sprite_4_wr    : std_logic;
	signal palette_bank		: std_logic;
	signal clut_bank			: std_logic;
	signal gfx_bank				: std_logic;
	
begin

	cpu_reset <= reset or game_reset;
	
	GEN_EXTERNAL_WRAM : if not PENGO_USE_INTERNAL_WRAM generate
	
	  -- SRAM signals (may or may not be used)
	  sram_o.a <= std_logic_vector(resize(unsigned(uP_addr), sram_o.a'length));
	  sram_o.d <= std_logic_vector(resize(unsigned(uP_datao), sram_o.d'length));
		wram_datao <= sram_i.d(wram_datao'range);
		sram_o.be <= std_logic_vector(to_unsigned(1, sram_o.be'length));
	  sram_o.cs <= '1';
	  sram_o.oe <= wram_cs and not uPmemwr;
	  sram_o.we <= wram_wr;

	end generate GEN_EXTERNAL_WRAM;

	GEN_NO_SRAM : if PENGO_USE_INTERNAL_WRAM generate

		sram_o.a <= (others => 'X');
		sram_o.d <= (others => 'X');
		sram_o.be <= (others => '0');
		sram_o.cs <= '0';
		sram_o.oe <= '0';
		sram_o.we <= '0';
			
	end generate GEN_NO_SRAM;
	
  -- chip select logic
	-- ROM $0000-$7FFF
  rom_cs <= 		'1' when STD_MATCH(uP_addr, "0---------------") else '0';
  -- VRAM $8000-$83FF
  vram_cs <= 		'1' when STD_MATCH(uP_addr, "100000----------") else '0';
  -- CRAM $8400-$87FF
  cram_cs <= 		'1' when STD_MATCH(uP_addr, "100001----------") else '0';
	-- WRAM $8800-$8FFF
  wram_cs <= 		'1' when STD_MATCH(uP_addr, "10001-----------") else '0';
	-- DIP1 $9000
  dip1_cs <= 		'1' when STD_MATCH(uP_addr, X"90"  &"00------") else '0';
	-- DIP0 $9040
  dip0_cs <= 		'1' when STD_MATCH(uP_addr, X"90"  &"01------") else '0';
	-- IN1 $9080
  inOne_cs <= 	'1' when STD_MATCH(uP_addr, X"90"  &"10------") else '0';
	-- IN0 $90C0
  inZero_cs <= 	'1' when STD_MATCH(uP_addr, X"90"  &"11------") else '0';

	-- memory read mux
	uP_datai <= rom_datao when rom_cs = '1' else
							wram_datao when wram_cs = '1' else
							vram_datao when vram_cs = '1' else
							cram_up_data when cram_cs = '1' else
              inputs(0) when inzero_cs = '1' else
              inputs(1) when inone_cs = '1' else
              not dip when dip0_cs = '1' else
     					-- 1C/1C for both coin mechs
							"11001100" when dip1_cs = '1' else
							(others => 'X');
	
	vram_wr <= uPmemwr and vram_cs;
	cram_wr <= cram_cs and uPmemwr;
	wram_wr <= wram_cs and uPmemwr;
	
  -- INTENA $9040
  intena_wr <= uPmemwr when STD_MATCH(uP_addr, X"9040") else '0';
  -- SPRITE_WR $8FF2-$8FFD, $9022-$902D
  -- $8FFX or $902X
  sprite_wr <= uPmemwr when STD_MATCH(uP_addr, X"8FF"&"----") else
               uPmemwr when STD_MATCH(uP_addr, X"902"&"----") else
               '0';
  -- SOUND $9000-$901F
	snd_wr <= uPmemwr when STD_MATCH(uP_addr, X"90"&"000-----") else '0';

	-- bank latches
	process (clk_30M, clk_3M_en, cpu_reset)
	begin
		if cpu_reset = '1' then
			gfx_bank <= '0';
		elsif rising_edge(clk_30M) and clk_3M_en = '1' then
			if uPmemwr = '1' then
				if STD_MATCH(uP_addr, X"9042") then
					palette_bank <= uP_datao(0);
				elsif STD_MATCH(uP_addr, X"9046") then
					clut_bank <= uP_datao(0);
				elsif STD_MATCH(uP_addr, X"9047") then
					gfx_bank <= uP_datao(0);
				end if;
			end if;
		end if;
	end process;
	
	upaddr <= uP_addr;
	updatao <= uP_datao;
  sprite_reg_addr(7 downto 2) <= "000" & uP_addr(3 downto 1);
	-- since we only care about sprite register address when we'r writing
	-- for bit 1 we need '0' when 902X is addressed, or '1' when 8FFX is addressed
	-- - so just use bit 11 of address!
  sprite_reg_addr(1 downto 0) <= uP_addr(11) & uP_addr(0);

	attr_dout <= EXT(palette_bank & clut_bank & cram_data(4 downto 0), attr_dout'length);
	gfxextra_data <= EXT(palette_bank & clut_bank, gfxextra_data'length);
		
  -- unused outputs
	bitmap_data <= (others => '0');
	spi_clk <= '0';
	spi_dout <= '0';
	spi_ena <= '0';
	spi_mode <= '0';
	spi_sel <= '0';
	ser_tx <= 'X';
  snd_rd <= '0';

	xcentre <= (others => '0');
	ycentre <= (others => '0');
	leds <= (others => '0');
	
  --
  -- COMPONENT INSTANTIATION
  --

	clk_en_inst : entity work.clk_div
		generic map
		(
			DIVISOR		=> 10
		)
		port map
		(
			clk				=> clk_30M,
			reset			=> reset,
			clk_en		=> clk_3M_en
		);

  U_uP : entity work.uPse                                                
    port map
    (
      clk 		=> clk_30M,                                   
      clk_en	=> clk_3M_en,
      reset  	=> cpu_reset,                                     

      addr   	=> uP_addr,
      datai  	=> uP_datai,
      datao  	=> uP_datao,

      mem_rd 	=> open,
      mem_wr 	=> uPmemwr,
      io_rd  	=> open,
      io_wr  	=> uPiowr,

      intreq 	=> uPintreq,
      intvec 	=> uPintvec,
      intack 	=> uPintack,
      nmi    	=> '0'
    );

	rom_inst : entity work.prg_rom
		port map
		(
			clock			=> clk_30M,
			address		=> up_addr(14 downto 0),
			q					=> rom_datao
		);
	
	vram_inst : entity work.vram
		port map
		(
			clock_b			=> clk_30M,
			address_b		=> uP_addr(9 downto 0),
			wren_b			=> vram_wr,
			data_b			=> uP_datao,
			q_b					=> vram_datao,
			
			-- wren_a *MUST* be GND for CYCLONEII_SAFE_WRITE=VERIFIED_SAFE
			clock_a			=> clk_40M,
			address_a		=> vram_addr,
			wren_a			=> '0',
			data_a			=> (others => 'X'),
			q_a					=> tileMapDatao(7 downto 0)
		);

	vrammapper_inst : entity work.vramMapper
		port map
		(
	    clk     => clk_40M,

	    inAddr  => tileMapAddr(11 downto 0),
	    outAddr => vram_addr
		);

	-- wren_a *MUST* be GND for CYCLONEII_SAFE_WRITE=VERIFIED_SAFE
	cram_inst : entity work.cram
		port map
		(
			clock_b			=> clk_30M,
			address_b		=> uP_addr(9 downto 0),
			wren_b			=> cram_wr,
			data_b			=> uP_datao,
			q_b					=> cram_up_data,
			
			clock_a			=> clk_40M,
			address_a		=> vram_addr(9 downto 0),
			wren_a			=> '0',
			data_a			=> (others => 'X'),
			q_a					=> cram_data
		);

	inputs_inst : entity work.Inputs
		generic map
		(
			NUM_INPUTS	=> inputs'length
		)
	  port map
	  (
	    clk     		=> clk_30M,
	    reset   		=> reset,
	    ps2clk  		=> ps2clk,
	    ps2data 		=> ps2data,
			jamma				=> jamma,

	    dips				=> dip,
	    inputs			=> inputs
	  );

  interrupts_inst : entity work.Pacman_Interrupts
	  port map
	  (
	    clk               => clk_30M,
	    reset             => cpu_reset,

	    z80_data          => uP_datao,
			Z80_addr					=> uP_addr(1 downto 0),
			io_wr							=> uPiowr,
	    intena_wr         => intena_wr,

			vblank						=> vblank,
			
	    -- interrupt status & request lines
			int_ack						=> uPintack,
	    int_req           => uPintreq,
			int_vec						=> uPintvec
	  );

	tilerom_inst : entity work.tile_rom
		port map
		(
			clock									=> clk_40M,
			address(12)						=> gfx_bank,
			address(11 downto 0)	=> tileAddr(11 downto 0),
			q											=> tiledatao
		);
	
	spriterom_inst : entity work.sprite_rom
		port map
		(
			clock								=> clk_40M,
			address(10)					=> gfx_bank,
			address(9 downto 0)	=> SpriteAddr(9 downto 0),
			q										=> spriteData
		);
	
  GEN_INTERNAL_WRAM : if PENGO_USE_INTERNAL_WRAM generate
  
    wram_inst : entity work.wram
      port map
      (
        clock				=> clk_30M,
        address			=> uP_addr(10 downto 0),
        data				=> up_datao,
        wren				=> wram_wr,
        q						=> wram_datao
      );
  
  end generate GEN_INTERNAL_WRAM;
		
end SYN;
