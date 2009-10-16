library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
--use work.sdram_pkg.all;
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

    bus_dmaout        : in std_logic;
    bus_intout        : in std_logic;
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
    n_bus_io_sel

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
    extspi_cs_n0      : out std_logic;
    extspi_cs_n1      : out std_logic;
    sdio_detect       : out std_logic;
    sdio_protect      : out std_logic;
    
    -- vga interface
    clk_ext2          : out std_logic;

    -- IDE interface
    dmarq             : in std_logic;
    intrq             : in std_logic;
    iordy             : in std_logic;

    -- soft JTAG
    tck_soft          : out std_logic;
    tdi_soft          : out std_logic;
    tdo_soft          : out std_logic;
    tms_soft          : out std_logic
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

begin

  BLK_INIT : block
    signal init : std_logic := '0';
  begin
    -- FPGA STARTUP
  	-- should extend power-on reset if registers init to '0'
  	process (clk_14M31818)
	  	variable count : std_logic_vector (11 downto 0) := (others => '0');
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

  -- no buttons or switches on the CB
  buttons_i <= (others => '0');
  switches_i <= (others => '0');

  BLK_INPUTS : block
  begin

    inputs_i.ps2_kclk <= '1';
    inputs_i.ps2_kdat <= '1';
    inputs_i.ps2_mclk <= '1';
    inputs_i.ps2_mdat <= '1';

		inputs_i.jamma_n.coin(1) <= '1';
		inputs_i.jamma_n.p(1).start <= '1';
		inputs_i.jamma_n.p(1).up <= '1';
		inputs_i.jamma_n.p(1).down <= '1';
		inputs_i.jamma_n.p(1).left <= '1';
		inputs_i.jamma_n.p(1).right <= '1';
		inputs_i.jamma_n.p(1).button <= (others => '1');

  	-- not currently wired to any inputs
  	inputs_i.jamma_n.coin_cnt <= (others => '1');
  	inputs_i.jamma_n.coin(2) <= '1';
  	inputs_i.jamma_n.p(2).start <= '1';
    inputs_i.jamma_n.p(2).up <= '1';
    inputs_i.jamma_n.p(2).down <= '1';
  	inputs_i.jamma_n.p(2).left <= '1';
  	inputs_i.jamma_n.p(2).right <= '1';
  	inputs_i.jamma_n.p(2).button <= (others => '1');
  
  	inputs_i.jamma_n.service <= '1';
  	inputs_i.jamma_n.tilt <= '1';
  	inputs_i.jamma_n.test <= '1';

  end block BLK_INPUTS;

  -- no flash
  flash_i.d <= (others => 'X');

  BLK_SRAM : block

    GEN_SRAM : if PACE_HAS_SRAM generate
      sram_a <= sram_o.a(sram_a'range);
      sram_d <= sram_o.d(sram_d'range) when sram_o.cs = '1' and sram_o.we = '1' else (others => 'Z');
      sram_ncs <= not sram_o.cs;
      sram_noe <= not sram_o.oe;
      sram_nwe <= not sram_o.we;
      sram_i.d <= std_logic_vector(resize(sram_d),sram_i.d'length);
    end generate GEN_SRAM;

    GEN_NO_SRAM : if not PACE_HAS_SRAM generate
      sram_a <= (others => 'Z');
      sram_d <= (others => 'Z');
      sram_ncs <= '1';
      sram_noe <= '1';
      sram_new <= '1';
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
  
  BLK_AUDIO : block
  begin
  end block BLK_AUDIO;

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

end architecture SYN;