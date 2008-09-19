library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.EXT;

library work;
use work.kbd_pkg.in8;
use work.pace_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;
use work.target_pkg.all;

entity Game is
  port
  (
    -- clocking and reset
    clk_i           : in std_logic_vector(0 to 3);
    reset_i         : in std_logic;

    -- misc I/O
    buttons_i       : in from_BUTTONS_t;
    switches_i      : in from_SWITCHES_t;
    leds_o          : out to_LEDS_t;

    -- controller inputs
    inputs_i        : in from_INPUTS_t;
		
    -- micro buses
    upaddr          : out std_logic_vector(15 downto 0);   
    updatao         : out std_logic_vector(7 downto 0);    

    -- FLASH/SRAM
    flash_i         : in from_FLASH_t;
    flash_o         : out to_FLASH_t;
		sram_i					: in from_SRAM_t;
		sram_o					: out to_SRAM_t;

    -- SPI (flash)
    spi_i           : in from_SPI_t;
    spi_o           : out to_SPI_t;

    -- serial
    ser_i           : in from_SERIAL_t;
    ser_o           : out to_SERIAL_t;

    -- general purpose I/O
    gp_i            : in from_GP_t;
    gp_o            : out to_GP_t;
    
    --
    --
    --

    gfxextra_data   : out std_logic_vector(7 downto 0);
		palette_data		: out ByteArrayType(15 downto 0);

    -- graphics (bitmap)
    bitmap_addr			: in    std_logic_vector(15 downto 0);   
    bitmap_data			: out   std_logic_vector(7 downto 0);    

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
    spriteaddr      : in std_logic_vector(15 downto 0);   
    spritedata      : out std_logic_vector(31 downto 0);   
    spr0_hit        : in std_logic;

    -- graphics (control)
    vblank          : in std_logic;    
		xcentre					: out std_logic_vector(9 downto 0);
		ycentre					: out std_logic_vector(9 downto 0);

    -- OSD
    to_osd          : out to_OSD_t;
    from_osd        : in from_OSD_t;

    -- sound
    snd_rd          : out std_logic;                       
    snd_wr          : out std_logic;
    sndif_datai     : in std_logic_vector(7 downto 0)
  );
end Game;

architecture SYN of Game is

	-- need this for projects that don't have it!
	component FDC_1793 is 
		port
	   (
	     clk            : in    std_logic;
	     uPclk          : in    std_logic;
	     reset          : in    std_logic;

	     fdcaddr        : in    std_logic_vector(2 downto 0);
	     fdcdatai       : in    std_logic_vector(7 downto 0);
	     fdcdatao       : out   std_logic_vector(7 downto 0);
	     fdc_rd         : in    std_logic;
	     fdc_wr         : in    std_logic;
	     fdc_drq_int    : out   std_logic;
	     fdc_dto_int		: out   std_logic;

	     spi_clk        : out   std_logic;
	     spi_ena        : out   std_logic;
	     spi_mode       : out   std_logic;
	     spi_sel        : out   std_logic;
	     spi_din        : in    std_logic;
	     spi_dout       : out   std_logic;

	     ser_rx         : in    std_logic;
	     ser_tx         : out   std_logic;

	     debug          : out   std_logic_vector(7 downto 0)
	   );
	end component;

  component osd_controller is
    generic
    (
      WIDTH_GPIO  : natural := 8
    );
    port
    (
      clk         : in std_logic;
      clk_en      : in std_logic;
      reset       : in std_logic;

      osd_key     : in std_logic;

      to_osd      : out to_OSD_t;
      from_osd    : in from_OSD_t;

      gpio_i      : in std_logic_vector(WIDTH_GPIO-1 downto 0);
      gpio_o      : out std_logic_vector(WIDTH_GPIO-1 downto 0);
      gpio_oe     : out std_logic_vector(WIDTH_GPIO-1 downto 0)
    );
  end component osd_controller;

	alias clk_20M					: std_logic is clk_i(0);
	alias clk_video       : std_logic is clk_i(1);
	
  -- uP signals  
  signal clk_2M_en			: std_logic;
  signal uP_addr        : std_logic_vector(15 downto 0);
  signal uP_datai       : std_logic_vector(7 downto 0);
  signal uP_datao       : std_logic_vector(7 downto 0);
  signal uPmemrd        : std_logic;
  signal uPmemwr        : std_logic;
  signal uPiord         : std_logic;
  signal uPiowr         : std_logic;
  signal uPintreq       : std_logic;
  signal uPintvec       : std_logic_vector(7 downto 0);
  signal uPintack       : std_logic;
  signal uPnmireq       : std_logic;
	alias io_addr					: std_logic_vector(7 downto 0) is uP_addr(7 downto 0);
	                        
  -- ROM signals        
	signal rom_cs					: std_logic;
  signal rom_datao      : std_logic_vector(7 downto 0);
                        
  -- keyboard signals
	signal kbd_cs					: std_logic;
	signal kbd_data				: std_logic_vector(7 downto 0);
	                        
  -- VRAM signals       
	signal vram_cs				: std_logic;
  signal vram_wr        : std_logic;
  signal vram_datao     : std_logic_vector(7 downto 0);
                        
  -- RAM signals        
  signal ram_wr         : std_logic;
  alias ram_datao      	: std_logic_vector(7 downto 0) is sram_i.d(7 downto 0);

  -- interrupt signals
	signal int_cs					: std_logic;
  signal intena_wr      : std_logic;
  signal int_status     : std_logic_vector(7 downto 0);
  signal rtc_intrst     : std_logic;  -- clear RTC interrupt
	signal nmi_cs					: std_logic;
  signal nmiena_wr      : std_logic;
  signal nmi_status     : std_logic_vector(7 downto 0);
  signal nmirst         : std_logic;  -- clear NMI

  -- OSD GPIO signals
  signal gpio_to_osd    : std_logic_vector(7 downto 0);
  signal gpio_from_osd  : std_logic_vector(7 downto 0);

  -- fdc signals
	signal fdc_cs					: std_logic;
  signal fdc_rd         : std_logic;
  signal fdc_wr         : std_logic;
  signal fdc_datao      : std_logic_vector(7 downto 0);
  signal fdc_drq_int    : std_logic;
  signal fdc_dto_int    : std_logic;
                        
  -- other signals      
	signal inputs					: in8(0 to 8);  
	alias game_reset			: std_logic is inputs(8)(0);
	signal cpu_reset			: std_logic;  
	signal alpha_joy_cs		: std_logic;
	signal rtc_cs					: std_logic;
	signal snd_cs					: std_logic;
  signal uPmem_datai    : std_logic_vector(7 downto 0);
  signal uPio_datai     : std_logic_vector(7 downto 0);
	
begin

	cpu_reset <= reset_i or game_reset;
	
  -- not used for now
  uPintvec <= (others => '0');

  -- read mux
  uP_datai <= uPmem_datai when (uPmemrd = '1') else uPio_datai;

  -- SRAM signals (may or may not be used)
  sram_o.a <= EXT(uP_addr, sram_o.a'length);
  sram_o.d <= EXT(uP_datao, sram_o.d'length);
	sram_o.be <= EXT("1", sram_o.be'length);
  sram_o.cs <= '1';
  sram_o.oe <= not ram_wr;
  sram_o.we <= ram_wr;

	-- memory chip selects
	-- ROM $0000-$37FF
	rom_cs <= '1' when uP_addr(15 downto 14) = "00" and uP_addr(13 downto 11) /= "111" else '0';
	-- KEYBOARD $3800-$38FF
	kbd_cs <= '1' when uP_addr(15 downto 10) = (X"3" & "10") else '0';
	-- RAM (everything else)
	vram_cs <= '1' when uP_addr(15 downto 10) = (X"3" & "11") else '0';
	
	-- memory write enables
	vram_wr <= vram_cs and uPmemwr;
	-- always write thru to RAM
	ram_wr <= uPmemwr;

	-- I/O chip selects
	-- Alpha Joystick $00 (active low)
	alpha_joy_cs <= '1' when io_addr = X"00" else '0';
	-- RDINTSTATUS $E0-E3 (active low)
	int_cs <= '1' when io_addr(7 downto 2) = "111000" else '0';
	-- NMI STATUS $E4
	nmi_cs <= '1' when io_addr = X"E4" else '0';
  -- reset RTC any read $EC-EF
  rtc_cs <= '1' when io_addr(7 downto 2) = "111011" else '0';
	-- FDC $F0-$F7
	fdc_cs <= '1' when io_addr(7 downto 3) = "11110" else '0';
  -- SOUND $FC-FF (Model I is $FF only)
	snd_cs <= '1' when io_addr(7 downto 2) = "111111" else '0';
	
	-- io read strobes
	fdc_rd <= fdc_cs and uPiord;
	nmirst <= nmi_cs and uPiord;
	rtc_intrst <= rtc_cs and uPiord;
	
	-- io write enables
	-- WRINTMASKREQ $E0-E3
  intena_wr <= int_cs and uPiowr;
  -- NMIMASKREQ $E4
  nmiena_wr <= nmi_cs and uPiowr;
  -- FDC $F0-$F7
  fdc_wr <= fdc_cs and uPiowr;
	-- SOUND OUTPUT $FC-FF (Model I is $FF only)
  snd_wr <= snd_cs and uPiowr;
		
	-- memory read mux
	uPmem_datai <= 	rom_datao when rom_cs = '1' else
									kbd_data when kbd_cs = '1' else
									vram_datao when vram_cs = '1' else
									ram_datao;
	
	-- io read mux
	uPio_datai <= X"FF" when alpha_joy_cs = '1' else
								(not int_status) when int_cs = '1' else
								(not nmi_status) when nmi_cs = '1' else
								fdc_datao when fdc_cs = '1' else
								X"FF";
		
	KBD_MUX : process (uP_addr, inputs)
  	variable kbd_data_v : std_logic_vector(7 downto 0);
	begin
    
  	kbd_data_v := X"00";
		for i in 0 to 7 loop
	 		if uP_addr(i) = '1' then
			  kbd_data_v := kbd_data_v or inputs(i);
		  end if;
		end loop;

  	-- assign the output
		kbd_data <= kbd_data_v;

  end process KBD_MUX;

	xcentre <= (others => '0');
	ycentre <= (others => '0');
	
  gfxextra_data <= (others => '0');
	GEN_PAL_DAT : for i in palette_data'range generate
		palette_data(i) <= (others => '0');
	end generate GEN_PAL_DAT;

    -- unused outputs
	upaddr <= uP_addr;
	updatao <= uP_datao;
	bitmap_data <= (others => '0');
  sprite_reg_addr <= (others => '0');
  sprite_wr <= '0';
  spriteData <= (others => '0');
  attr_dout <= X"00" & switches_i(7 downto 0);
  snd_rd <= '0';

	clk_en_inst : entity work.clk_div
		generic map
		(
			DIVISOR		=> 10
		)
		port map
		(
			clk				=> clk_20M,
			reset			=> reset_i,
			clk_en		=> clk_2M_en
		);

  up_inst : entity work.Z80                                                
    port map
    (
      clk			=> clk_20M,                                   
      clk_en	=> clk_2M_en,
      reset  	=> cpu_reset,                                     

      addr   	=> uP_addr,
      datai  	=> uP_datai,
      datao  	=> uP_datao,

      mem_rd 	=> uPmemrd,
      mem_wr 	=> uPmemwr,
      io_rd  	=> uPiord,
      io_wr  	=> uPiowr,

      intreq 	=> uPintreq,
      intvec 	=> uPintvec,
      intack 	=> uPintack,
      nmi    	=> uPnmireq
    );

	inputs_inst : entity work.Inputs
		generic map
		(
			NUM_INPUTS	=> inputs'length
		)
	  port map
	  (
	    clk     		=> clk_20M,
	    reset   		=> reset_i,
	    ps2clk  	=> inputs_i.ps2_kclk,
	    ps2data 	=> inputs_i.ps2_kdat,
			jamma			=> inputs_i.jamma_n,
			
	    dips				=> switches_i(7 downto 0),
	    inputs			=> inputs
	  );

	rom_inst : entity work.sprom
		generic map
		(
			init_file		=> "../../../../../src/platform/trs80/m3/roms/m3rom.hex",
			numwords_a	=> 16384,
			widthad_a		=> 14
		)
		port map
		(
			clock			=> clk_20M,
			address		=> up_addr(13 downto 0),
			q					=> rom_datao
		);
	
	tilerom_inst : entity work.sprom
		generic map
		(
			init_file		    => "../../../../../src/platform/trs80/m3/roms/trstile.hex",
			numwords_a	    => 4096,
			widthad_a		    => 12
			--outdata_reg_a   => "CLOCK0"
		)
		port map
		(
			clock			=> clk_video,
			address		=> tileaddr(11 downto 0),
			q					=> tileDatao
		);
	
	-- wren_a *MUST* be GND for CYCLONEII_SAFE_WRITE=VERIFIED_SAFE
	vram_inst : entity work.dpram
		generic map
		(
			init_file		=> "../../../../../src/platform/trs80/m3/roms/trsvram.hex",
			numwords_a	=> 1024,
			widthad_a		=> 10
		)
		port map
		(
			clock_b			=> clk_20M,
			address_b		=> uP_addr(9 downto 0),
			wren_b			=> vram_wr,
			data_b			=> uP_datao,
			q_b					=> vram_datao,

			clock_a			=> clk_video,
			address_a		=> tilemapaddr(9 downto 0),
			wren_a			=> '0',
			data_a			=> (others => 'X'),
			q_a					=> tileMapDatao(7 downto 0)
		);

    interrupts_inst : entity work.TRS80_Interrupts                    
      port map
      (
        clk           => clk_20M,
        reset         => cpu_reset,

        -- enable inputs                    
        z80_data      => uP_datao,
        intena_wr     => intena_wr,                  
        nmiena_wr     => nmiena_wr,
                    
        -- IRQ inputs
        reset_btn_int => '0',
        fdc_drq_int   => fdc_drq_int,                    
        fdc_dto_int   => fdc_dto_int,

        -- IRQ/status outputs
        int_status    => int_status,
        int_req       => uPintreq,
        nmi_status    => nmi_status,
        nmi_req       => uPnmireq,

        -- interrupt clear inputs
        rtc_reset     => rtc_intrst,
        nmi_reset     => nmirst
      );

		GEN_FDC : if INCLUDE_FDC_SUPPORT generate
		
			GEN_SPI_FDC : if PACE_TARGET = PACE_TARGET_NANOBOARD_NB1 generate
			
		    fdc_inst : FDC_1793                                    
		      port map
		      (
		        clk         => clk_20M,
		        upclk       => clk_2M_en,
		        reset       => cpu_reset,
		                    
		        fdcaddr     => uP_addr(2 downto 0),          
		        fdcdatai    => uP_datao,
		        fdcdatao    => fdc_datao,
		        fdc_rd      => fdc_rd,                      
		        fdc_wr      => fdc_wr,                      
		        fdc_drq_int => fdc_drq_int,   
		        fdc_dto_int => fdc_dto_int,         

		        spi_clk     => spi_o.clk,
		        spi_din     => spi_i.din,
		        spi_dout    => spi_o.dout,
		        spi_ena     => spi_o.ena,            
		        spi_mode    => spi_o.mode,           
		        spi_sel     => spi_o.sel,            
		                    
		        ser_rx      => ser_i.rxd,                                  
		        ser_tx      => ser_o.txd,

		        debug       => leds_o(7 downto 0)
		      );
		
			end generate GEN_SPI_FDC;
		
		end generate GEN_FDC;

		GEN_NO_FDC : 	if 	not INCLUDE_FDC_SUPPORT or 
											PACE_TARGET /= PACE_TARGET_NANOBOARD_NB1 
									generate
									
			fdc_datao <= X"FF";
			fdc_drq_int <= '0';
			fdc_dto_int <= '0';
			leds_o <= (others => '0');
					
		end generate GEN_NO_FDC;

  -- wire some keys to the osd module
  gpio_to_osd(0) <= inputs(6)(3); -- UP
  gpio_to_osd(1) <= inputs(6)(4); -- DOWN
  gpio_to_osd(2) <= inputs(6)(5); -- LEFT
  gpio_to_osd(3) <= inputs(6)(6); -- RIGHT
  gpio_to_osd(4) <= inputs(6)(0); -- ENTER
  gpio_to_osd(7 downto 5) <= (others => '0');

  GEN_OSD : if PACE_HAS_OSD generate

    osd_inst : osd_controller
      generic map
      (
        WIDTH_GPIO  => gpio_to_osd'length
      )
      port map
      (
        clk         => clk_20M,
        clk_en      => '1',
        reset       => cpu_reset,

        osd_key     => inputs(8)(1),

        to_osd      => to_osd,
        from_osd    => from_osd,

        gpio_i      => gpio_to_osd,
        gpio_o      => gpio_from_osd
      );

  end generate GEN_OSD;
  
end SYN;

