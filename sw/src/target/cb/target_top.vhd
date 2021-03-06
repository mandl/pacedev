library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.pace_pkg.all;
use work.sdram_pkg.all;
use work.video_controller_pkg.all;
--use work.maple_pkg.all;
--use work.gamecube_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;
use work.target_pkg.all;

entity target_top is
port
  (
    -- primary system clock
    sysclk            : in std_logic;

    -- apple ii bus interface    

    bus_dmaout        : out std_logic;
    bus_intout        : out std_logic;
    bus_nmi           : in std_logic;
    bus_irq           : in std_logic;
    bus_reset         : in std_logic;
    bus_inh           : in std_logic;

    bus_3m58          : in std_logic;
    bus_7m            : in std_logic;
    bus_q3            : in std_logic;
    bus_phase1        : in std_logic;
    bus_user1         : in std_logic;
    bus_phase0        : in std_logic;
    n_bus_dev_sel     : in std_logic;
    bus_d             : inout std_logic_vector(7 downto 0);

    bus_dmain         : in std_logic;
    bus_intin         : in std_logic;
    bus_dma           : in std_logic;
    bus_rdy           : in std_logic;
    bus_iostrobe      : in std_logic;
    bus_sync          : in std_logic;
    bus_r_w           : in std_logic;
    bus_a             : in std_logic_vector(15 downto 0);
    n_bus_io_sel      : in std_logic;

    -- boot flash interface
    prom_cs           : out std_logic;
    extspi_din        : out std_logic;  -- one of these is wrong
    extspi_dout       : out std_logic;
    extspi_sclk       : out std_logic;
    
    -- SRAM
    sram_a            : out std_logic_vector(16 downto 0);
    sram_d            : inout std_logic_vector(7 downto 0);
    sram_ncs          : out std_logic_vector(1 downto 0);
    sram_noe          : out std_logic;
    sram_nwe          : out std_logic;

    -- peripheral board clocks    
    clk_en            : out std_logic;
    clk_ext0          : out std_logic;
    clk_ext1          : out std_logic;
    
    -- peripheral board i/o
    pbio              : inout std_logic_vector(49 downto 0);

    -- peripheral board one wire interface
    one_wire_id       : inout std_logic;

    -- peripheral board i2c
    scl               : inout std_logic;
    sda               : inout std_logic;

    -- peripheral board sp interface
    extspi_cs_n       : out std_logic_vector(1 downto 0);
    sdio_detect       : in std_logic;
    sdio_protect      : in std_logic;
    
    -- vga interface
    clk_ext2          : out std_logic;

    -- IDE interface
    dmarq             : in std_logic;
    intrq             : in std_logic;
    iordy             : in std_logic;

    -- soft JTAG
    tck_soft          : in std_logic;
    tdi_soft          : in std_logic;
    tdo_soft          : in std_logic;
    tms_soft          : in std_logic
  );
end target_top;

architecture SYN of target_top is

  alias clk_14M31818    : std_logic is sysclk;

  -- sigma-delta audio interface
  alias audio_left      : std_logic is sda;
  alias audio_right     : std_logic is scl;
                        
  -- vga interface      
  alias vga_r0          : std_logic is clk_ext2;
  alias vga_r1          : std_logic is pbio(4);
  alias vga_g0          : std_logic is pbio(0);
  alias vga_g1          : std_logic is pbio(1);
  alias vga_b0          : std_logic is pbio(2);
  alias vga_b1          : std_logic is pbio(3);
  alias vga_hs          : std_logic is pbio(45);
  alias vga_vs          : std_logic is pbio(46);
                        
  -- sd card interface  
  alias data1           : std_logic is pbio(47);
  alias data2           : std_logic is pbio(48);
  alias data3           : std_logic is pbio(49);

  -- PACE stuff

	signal clk_i			    : std_logic_vector(0 to 3);
  signal init       	  : std_logic := '1';
  signal reset_i     	  : std_logic := '1';
	signal reset_n			  : std_logic := '0';

  signal buttons_i      : from_BUTTONS_t;
  signal switches_i     : from_SWITCHES_t;
  signal leds_o         : to_LEDS_t;
  signal inputs_i       : from_INPUTS_t;
  signal flash_i        : from_FLASH_t;
  signal flash_o        : to_FLASH_t;
	signal sram_i			    : from_SRAM_t;
	signal sram_o			    : to_SRAM_t;	
	signal sdram_i        : from_SDRAM_t;
	signal sdram_o        : to_SDRAM_t;
	signal video_i        : from_VIDEO_t;
  signal video_o        : to_VIDEO_t;
  signal audio_i        : from_AUDIO_t;
  signal audio_o        : to_AUDIO_t;
  signal ser_i          : from_SERIAL_t;
  signal ser_o          : to_SERIAL_t;
  signal project_i      : from_PROJECT_IO_t;
  signal project_o      : to_PROJECT_IO_t;
  signal platform_i     : from_PLATFORM_IO_t;
  signal platform_o     : to_PLATFORM_IO_t;
  signal target_i       : from_TARGET_IO_t;
  signal target_o       : to_TARGET_IO_t;

  signal d_C000         : std_logic_vector(7 downto 0) := (others => '0');
  signal d_C010         : std_logic_vector(7 downto 0) := (others => '0');
  alias key_strobe      : std_logic is d_C000(7);
  alias key_code        : std_logic_vector(6 downto 0) is d_C000(6 downto 0);
  alias any_key         : std_logic is d_C010(7);

  signal key_f          : std_logic := '0';
  
begin

  BLK_INIT : block
    signal init : std_logic := '0';
  begin
    -- FPGA STARTUP
  	-- should extend power-on reset if registers init to '0'
  	process (clk_14M31818)
	  	variable count : unsigned (11 downto 0) := (others => '0');
	  begin
  		if rising_edge(clk_14M31818) then
  			if count = X"FFF" then
  				init <= '0';
  			else
  				count := count + 1;
  				init <= '1';
  			end if;
  		end if;
  	end process;

    reset_i <= init;
  	reset_n <= not reset_i;

	end block BLK_INIT;

  BLK_PLL : block
  begin

    pll_inst : entity work.pll
      generic map
      (
        -- CLK0
        CLK0_DIVIDE_BY          => PACE_CLK0_DIVIDE_BY,
        CLK0_MULTIPLY_BY        => PACE_CLK0_MULTIPLY_BY,
    
        -- CLK1
        CLK1_DIVIDE_BY          => PACE_CLK1_DIVIDE_BY,
        CLK1_MULTIPLY_BY        => PACE_CLK1_MULTIPLY_BY
      )
      port map
      (
        inclk0		=> clk_14M31818,
        c0		    => clk_i(0),
        c1		    => clk_i(1)
      );
  
  end block BLK_PLL;
  
  -- no buttons or switches on the CB
  buttons_i <= (others => '0');
  switches_i <= (others => '0');

  BLK_INPUTS : block
  
    signal ps2_fifo_data    : std_logic_vector(7 downto 0) := (others => '0');
    signal ps2_fifo_wrreq   : std_logic := '0';
    signal ps2_fifo_full    : std_logic := '0';
  
  begin

    GEN_PS2 : if PACE_JAMMA /= PACE_JAMMA_PS2 generate
    begin
    
      inputs_i.ps2_mclk <= '1';
      inputs_i.ps2_mdat <= '1';

      process (clk_14M31818, reset_i)
        --variable key_strobe_r : std_logic := '0';
        --variable key_code_r   : std_logic_vector(key_code'range) := (others => '0');
      begin
        if reset_i = '1' then
          ps2_fifo_wrreq <= '0';
          --key_strobe_r := '0';
          --key_code_r := (others => '0');
        elsif rising_edge(clk_14M31818) then
          ps2_fifo_wrreq <= '0';  -- default
          -- assume there's a new key each time $C000 is read by BASIC
          if key_f = '1' and key_strobe = '1' then
            if ps2_fifo_full = '0' then
              ps2_fifo_data <= '0' & key_code;
              ps2_fifo_wrreq <= '1';
            end if;
          end if;
          --key_strobe_r := key_strobe;
          --key_code_r := key_code;
        end if;
      end process;
      
      ps2_host_inst : entity work.apple_ii_ps2_host
        generic map
        (
          CLK_HZ          => 14318181
        )
        port map
        (
          clk             => clk_14M31818,
          reset           => reset_i,
      
          -- FIFO interface
          fifo_data       => ps2_fifo_data,
          fifo_wrreq      => ps2_fifo_wrreq,
          fifo_full       => ps2_fifo_full,
              
          -- PS/2 lines
          ps2_kclk        => inputs_i.ps2_kclk,
          ps2_kdat        => inputs_i.ps2_kdat
        );

    end generate GEN_PS2;
    
    GEN_PS2_JAMMA : if PACE_JAMMA = PACE_JAMMA_PS2 generate
    
      -- fudge - extend keypress for 1 frame
      process (clk_14M31818, reset_i)
        subtype count_t is integer range 0 to 14318181/59;
        variable count : count_t;
      begin
        if reset_i = '1' then
          inputs_i.jamma_n.p(1).start <= '1';
          inputs_i.jamma_n.p(2).start <= '1';
          inputs_i.jamma_n.coin(1) <= '1';
          inputs_i.jamma_n.coin(2) <= '1';
          inputs_i.jamma_n.p(1).button(1) <= '1';
          inputs_i.jamma_n.p(1).left <= '1';
          inputs_i.jamma_n.p(1).right <= '1';
          inputs_i.jamma_n.p(1).up <= '1';
          inputs_i.jamma_n.p(1).down <= '1';
          count := 0;
        elsif rising_edge(clk_14M31818) then
          if key_strobe = '1' then
            -- any key releases left/right
            inputs_i.jamma_n.p(1).left <= '1';
            inputs_i.jamma_n.p(1).right <= '1';
            inputs_i.jamma_n.p(1).up <= '1';
            inputs_i.jamma_n.p(1).down <= '1';
            count := count_t'high;
            case key_code is
              when "0110001" =>
                inputs_i.jamma_n.p(1).start <= '0';
              when "0110010" =>
                inputs_i.jamma_n.p(2).start <= '0';
              when "0110101" =>
                inputs_i.jamma_n.coin(1) <= '0';
              when "0110110" =>
                inputs_i.jamma_n.coin(2) <= '0';
              when "0100000" =>
                inputs_i.jamma_n.p(1).button(1) <= '0';
              when "0001000" | "1011010" | "1111010" =>
                inputs_i.jamma_n.p(1).left <= '0';
              when "0010101" | "1011000" | "1111000" =>
                inputs_i.jamma_n.p(1).right <= '0';
              when "0001011" | "1010001" | "1110001" =>
                inputs_i.jamma_n.p(1).up <= '0';
              when "0001010" | "1000001" | "1100001" =>
                inputs_i.jamma_n.p(1).down <= '0';
              when others =>
                null;
            end case;
          else
            if count = 0 then
              -- clear all except left/right/up/down
              inputs_i.jamma_n.p(1).start <= '1';
              inputs_i.jamma_n.p(2).start <= '1';
              inputs_i.jamma_n.coin(1) <= '1';
              inputs_i.jamma_n.coin(2) <= '1';
              inputs_i.jamma_n.p(1).button(1) <= '1';
            else
              count := count - 1;
            end if;
          end if;
        end if;
      end process;

  		inputs_i.jamma_n.p(1).button(2 to 5) <= (others => '1');
  
    	-- not currently wired to any inputs
    	inputs_i.jamma_n.coin_cnt <= (others => '1');
      inputs_i.jamma_n.p(2).up <= '1';
      inputs_i.jamma_n.p(2).down <= '1';
    	inputs_i.jamma_n.p(2).left <= '1';
    	inputs_i.jamma_n.p(2).right <= '1';
    	inputs_i.jamma_n.p(2).button <= (others => '1');

    end generate GEN_PS2_JAMMA;

    GEN_NO_JAMMA : if PACE_JAMMA = PACE_JAMMA_NONE generate
            
  		inputs_i.jamma_n.coin(1) <= '1';
  		inputs_i.jamma_n.p(1).start <= '1';
  		inputs_i.jamma_n.p(1).up <= '1';
  		inputs_i.jamma_n.p(1).down <= '1';
  		inputs_i.jamma_n.p(1).left <= '1';
  		inputs_i.jamma_n.p(1).right <= '1';
  		inputs_i.jamma_n.p(1).button <= (others => '1');
  
    	-- not currently wired to any inputs
    	inputs_i.jamma_n.coin(2) <= '1';
    	inputs_i.jamma_n.p(2).start <= '1';
      inputs_i.jamma_n.p(2).up <= '1';
      inputs_i.jamma_n.p(2).down <= '1';
    	inputs_i.jamma_n.p(2).left <= '1';
    	inputs_i.jamma_n.p(2).right <= '1';
    	inputs_i.jamma_n.p(2).button <= (others => '1');

    end generate GEN_NO_JAMMA;
      
    inputs_i.jamma_n.coin_cnt <= (others => '1');
  	inputs_i.jamma_n.service <= '1';
  	inputs_i.jamma_n.tilt <= '1';
  	inputs_i.jamma_n.test <= '1';

  end block BLK_INPUTS;

  -- no flash
  flash_i.d <= (others => 'X');

  BLK_SRAM : block
  begin
  
    GEN_SRAM : if PACE_HAS_SRAM generate
      signal we_r : std_logic_vector(1 downto 0) := "00";
    begin
      sram_a <= sram_o.a(sram_a'range);
      sram_d <= sram_o.d(sram_d'range) when sram_o.cs = '1' and sram_o.we = '1' else (others => 'Z');
      sram_ncs <= '1' & not sram_o.cs;
      sram_noe <= not sram_o.oe;
      sram_nwe <= not sram_o.we;
      --sram_i.d <= std_logic_vector(resize(unsigned(sram_d),sram_i.d'length));
      
      -- pulse the we for 2 clocks
      process (clk_i(0), reset_i)
        --variable we_r : std_logic_vector(1 downto 0) := "00";
      begin
        if reset_i = '1' then
          we_r <= (others => '0');
        elsif rising_edge(clk_i(0)) then
          --sram_nwe <= '1';  -- default
          if we_r(1) = '0' and sram_o.we = '1' then
            --sram_nwe <= '0';
          end if;
          we_r <= we_r(0) & sram_o.we;
          -- latch data in
          sram_i.d <= std_logic_vector(resize(unsigned(sram_d),sram_i.d'length));
        end if;
      end process;
      
    end generate GEN_SRAM;

    GEN_NO_SRAM : if not PACE_HAS_SRAM generate
      sram_a <= (others => 'Z');
      sram_d <= (others => 'Z');
      sram_ncs <= (others => '1');
      sram_noe <= '1';
      sram_nwe <= '1';
      sram_i.d <= (others => 'X');
    end generate GEN_NO_SRAM;

  end block BLK_SRAM;

  -- no sdram
  sdram_o.d <= (others => 'X');

  BLK_VIDEO : block
  begin

    video_i.clk <= clk_i(1);    -- by convention
    video_i.clk_ena <= '1';
    video_i.reset <= reset_i;

    vga_r1 <= video_o.rgb.r(video_o.rgb.r'left);
    vga_r0 <= video_o.rgb.r(video_o.rgb.r'left-1);
    vga_g1 <= video_o.rgb.g(video_o.rgb.g'left);
    vga_g0 <= video_o.rgb.g(video_o.rgb.g'left-1);
    vga_b1 <= video_o.rgb.b(video_o.rgb.b'left);
    vga_b0 <= video_o.rgb.b(video_o.rgb.b'left-1);
    vga_hs <= video_o.hsync;
    vga_vs <= video_o.vsync;

  end block BLK_VIDEO;
  
  -- check the generic in the project package
  -- because not everyone has an audio board
  GEN_AUDIO : if PACE_HAS_AUDIO generate
  
    component sigma_delta_dac is
      port
      (
        clk     : in std_logic;
        din     : in std_logic_vector(7 downto 0);
        
        dout    : out std_logic
      );
    end component sigma_delta_dac;
    
    signal CLKIN_BUFG   : std_logic;
    signal CLKFX        : std_logic;
    signal dac_clk      : std_logic := '0';
    
  begin
  
    -- buffer from pin to DCM clock input
    CLKIN_BUFG_INST : BUFG
      port map (I=>clk_14M31818, O=>CLKIN_BUFG);
  
    -- buffer from CLKFX output to FPGA logic
    CLKFX_0_BUFG_INST : BUFG
      port map (I=>CLKFX, O=>dac_clk);
      
    AUDIO_DCM_inst : DCM
    generic map 
    (
      CLKDV_DIVIDE => 2.0, --  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                       --     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      CLKFX_DIVIDE => 1,   --  Can be any interger from 1 to 32
      CLKFX_MULTIPLY => 7, --  Can be any integer from 1 to 32
      CLKIN_DIVIDE_BY_2 => FALSE, --  TRUE/FALSE to enable CLKIN divide by two feature
      CLKIN_PERIOD => 69.841,          --  Specify period of input clock
      CLKOUT_PHASE_SHIFT => "NONE", --  Specify phase shift of NONE, FIXED or VARIABLE
      CLK_FEEDBACK => "NONE",         --  Specify clock feedback of NONE, 1X or 2X
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", --  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                         --     an integer from 0 to 15
      DFS_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for frequency synthesis
      DLL_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for DLL
      DUTY_CYCLE_CORRECTION => TRUE, --  Duty cycle correction, TRUE or FALSE
      FACTORY_JF => X"C080",          --  FACTORY JF Values
      PHASE_SHIFT => 0,        --  Amount of fixed phase shift from -255 to 255
      STARTUP_WAIT => FALSE --  Delay configuration DONE until DCM LOCK, TRUE/FALSE
    )
    port map 
    (
      CLKFX => CLKFX,   -- DCM CLK synthesis out (M/D)
      CLKIN => CLKIN_BUFG   -- Clock input (from IBUFG, BUFG or DCM)
    );
  
    dac_l_inst : sigma_delta_dac
      port map
      (
        clk     => dac_clk,
        din     => audio_o.ldata(15 downto 8),
        
        dout    => audio_left
      );

    dac_r_inst : sigma_delta_dac
      port map
      (
        clk     => dac_clk,
        din     => audio_o.rdata(15 downto 8),
        
        dout    => audio_right
      );
  end generate GEN_AUDIO;

  -- no serial (atm)
  ser_i.rxd <= '0';

  pace_inst : entity work.pace                                            
    port map
    (
    	-- clocks and resets
	  	clk_i							=> clk_i,
      reset_i          	=> reset_i,

      -- misc inputs and outputs
      buttons_i         => buttons_i,
      switches_i        => switches_i,
      leds_o            => leds_o,
      
      -- controller inputs
      inputs_i          => inputs_i,

     	-- external ROM/RAM
     	flash_i           => flash_i,
      flash_o           => flash_o,
      sram_i        		=> sram_i,
      sram_o        		=> sram_o,
     	sdram_i           => sdram_i,
     	sdram_o           => sdram_o,
  
      -- VGA video
      video_i           => video_i,
      video_o           => video_o,
      
      -- sound
      audio_i           => audio_i,
      audio_o           => audio_o,

      -- SPI (flash)
      spi_i.din         => '0',
      spi_o             => open,
  
      -- serial
      ser_i             => ser_i,
      ser_o             => ser_o,
      
      -- custom i/o
      project_i         => project_i,
      project_o         => project_o,
      platform_i        => platform_i,
      platform_o        => platform_o,
      target_i          => target_i,
      target_o          => target_o
    );

  BLK_SNOOP : block
  begin
    process (clk_14M31818, reset_i)
      variable snoop_a  : std_logic_vector(15 downto 0) := (others => '0');
      variable ph0_r    : std_logic := '0';
    begin
      if reset_i = '1' then
        snoop_a := (others => '0');
        ph0_r := '0';
        d_C000 <= (others => '0');
        d_C010 <= (others => '0');
        key_f <= '0';
      elsif rising_edge(clk_14M31818) then
        key_f <= '0';
        if ph0_r = '0' and bus_phase0 = '1' then
          snoop_a := bus_a;
        elsif ph0_r = '1' and bus_phase0 = '0' then
          if snoop_a(15 downto 0) = X"C000" then
            d_C000 <= bus_d;
            -- signal a new key is ready
            key_f <= '1';
          elsif snoop_a(15 downto 0) = X"C010" then
            d_C010 <= bus_d;
          end if;
        end if;
        ph0_r := bus_phase0;
      end if;
    end process;
    -- tri-state data bus
    bus_d <= (others => 'Z');
  end block BLK_SNOOP;

  -- let's play nice with the apple bus
  bus_dmaout <= '0' when bus_dmain = '0' else 'Z';
  bus_intout <= '0' when bus_intin = '0' else 'Z';

end architecture SYN;
