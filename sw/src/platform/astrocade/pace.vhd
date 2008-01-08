Library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;
use work.platform_pkg.all;
use work.project_pkg.all;

entity PACE is
  port
  (
  	-- clocks and resets
    clk             : in std_logic_vector(0 to 3);
    test_button     : in std_logic;
    reset           : in std_logic;

    -- game I/O
    ps2clk          : inout std_logic;
    ps2data         : inout std_logic;
    dip             : in std_logic_vector(7 downto 0);
		jamma						: in JAMMAInputsType;

    -- external RAM
    sram_i       		: in from_SRAM_t;
		sram_o					: out to_SRAM_t;

    -- VGA video
		vga_clk					: out std_logic;
    red             : out std_logic_vector(9 downto 0);
    green           : out std_logic_vector(9 downto 0);
    blue            : out std_logic_vector(9 downto 0);
		lcm_data				:	out std_logic_vector(9 downto 0);
    hsync           : out std_logic;
    vsync           : out std_logic;

    -- composite video
    BW_CVBS         : out std_logic_vector(1 downto 0);
    GS_CVBS         : out std_logic_vector(7 downto 0);

    -- sound
    snd_clk         : out std_logic;
    snd_data_l      : out std_logic_vector(15 downto 0);
    snd_data_r      : out std_logic_vector(15 downto 0);

    -- SPI (flash)
    spi_clk         : out std_logic;
    spi_mode        : out std_logic;
    spi_sel         : out std_logic;
    spi_din         : in std_logic;
    spi_dout        : out std_logic;

    -- serial
    ser_tx          : out std_logic;
    ser_rx          : in std_logic;

    -- debug
    leds            : out std_logic_vector(7 downto 0)
  );

end PACE;

architecture SYN of PACE is

    signal I_RESET_L        : std_logic;
    signal reset_s          : std_logic;
    signal reset_l          : std_logic;
    signal sw_reg           : std_logic_vector(3 downto 0);
    --
    signal ena_x2           : std_logic;
    signal ena              : std_logic;
    signal clk_14           : std_logic;
    signal clk_ref          : std_logic;
    --
    signal switch_col       : std_logic_vector(7 downto 0);
    signal switch_row       : std_logic_vector(7 downto 0);
    signal ps2_1mhz_ena     : std_logic;
    signal ps2_1mhz_cnt     : std_logic_vector(5 downto 0);
    --
    signal video_r          : std_logic_vector(3 downto 0);
    signal video_g          : std_logic_vector(3 downto 0);
    signal video_b          : std_logic_vector(3 downto 0);
    signal hsync_s          : std_logic;
    signal vsync_s          : std_logic;
    signal fpsync           : std_logic;
    --
    signal video_r_x2       : std_logic_vector(3 downto 0);
    signal video_g_x2       : std_logic_vector(3 downto 0);
    signal video_b_x2       : std_logic_vector(3 downto 0);
    signal hsync_x2         : std_logic;
    signal vsync_x2         : std_logic;
    --
    signal audio            : std_logic_vector(7 downto 0);
    signal audio_pwm        : std_logic;

    signal exp_addr         : std_logic_vector(15 downto 0);
    signal exp_data_out     : std_logic_vector(7 downto 0);
    signal exp_data_in      : std_logic_vector(7 downto 0);
    signal exp_oe_l         : std_logic;

    signal exp_m1_l         : std_logic;
    signal exp_mreq_l       : std_logic;
    signal exp_iorq_l       : std_logic;
    signal exp_wr_l         : std_logic;
    signal exp_rd_l         : std_logic;
    --
    signal check_cart_msb   : std_logic_vector(3 downto 0);
    signal check_cart_lsb   : std_logic_vector(7 downto 4);
    --
    signal cas_addr         : std_logic_vector(12 downto 0);
    signal cas_data         : std_logic_vector( 7 downto 0);
    signal cas_cs_l         : std_logic;

	-- aliases for PACE compatibility
	alias I_RESET							: std_logic is reset;
	alias I_CLK_REF						: std_logic is clk(0);
	alias I_PS2_CLK						: std_logic is ps2clk;
	alias I_PS2_DATA					: std_logic is ps2data;
	alias O_VIDEO_R						: std_logic_vector(3 downto 0) is red(9 downto 6);
	alias O_VIDEO_G						: std_logic_vector(3 downto 0) is green(9 downto 6);
	alias O_VIDEO_B						: std_logic_vector(3 downto 0) is blue(9 downto 6);
	alias O_HSYNC							: std_logic is hsync;
	alias O_VSYNC							: std_logic is vsync;
	alias O_LED								: std_logic_vector is leds(3 downto 0);
	
	signal I_SW								: std_logic_vector(sw_reg'range);
	signal O_AUDIO_L					: std_logic;
	signal O_AUDIO_R					: std_logic;
				
begin

  --
  I_RESET_L <= not I_RESET;
  --
  u_clocks : entity work.BALLY_CLOCKS
    port map (
       I_CLK_REF  => I_CLK_REF,
       I_RESET_L  => I_RESET_L,
       --
       O_CLK_REF  => clk_ref,
       --
       O_ENA_X2   => ena_x2,
       O_ENA      => ena,
       O_CLK      => clk_14, -- ~14 MHz
       O_RESET    => reset_s
     );

  p_ena1mhz : process
  begin
    wait until rising_edge(clk_14);
    -- divide by 14
    ps2_1mhz_ena <= '0';
    if (ps2_1mhz_cnt = "001101") then
      ps2_1mhz_cnt <= "000000";
      ps2_1mhz_ena <= '1';
    else
      ps2_1mhz_cnt <= ps2_1mhz_cnt + '1';
    end if;
  end process;

  reset_l <= not reset_s;

  u_bally : entity work.BALLY
    port map (
      O_AUDIO        => audio,
      --
      O_VIDEO_R      => video_r,
      O_VIDEO_G      => video_g,
      O_VIDEO_B      => video_b,

      O_HSYNC        => hsync_s,
      O_VSYNC        => vsync_s,
      O_COMP_SYNC_L  => open,
      O_FPSYNC       => fpsync,
      --
      -- cart slot
      O_CAS_ADDR     => cas_addr,
      O_CAS_DATA     => open,
      I_CAS_DATA     => cas_data,
      O_CAS_CS_L     => cas_cs_l,

      -- exp slot (subset for now)
      O_EXP_ADDR     => exp_addr,
      O_EXP_DATA     => exp_data_out,
      I_EXP_DATA     => exp_data_in,
      I_EXP_OE_L     => exp_oe_l,

      O_EXP_M1_L     => exp_m1_l,
      O_EXP_MREQ_L   => exp_mreq_l,
      O_EXP_IORQ_L   => exp_iorq_l,
      O_EXP_WR_L     => exp_wr_l,
      O_EXP_RD_L     => exp_rd_l,
      --
      O_SWITCH_COL   => switch_col,
      I_SWITCH_ROW   => switch_row,
      I_RESET_L      => reset_l,
      ENA            => ena,
      CLK            => clk_14
      );

  u_ps2 : entity work.BALLY_PS2_IF
    port map (

      I_PS2_CLK         => I_PS2_CLK,
      I_PS2_DATA        => I_PS2_DATA,

      I_COL             => switch_col,
      O_ROW             => switch_row,

      I_RESET_L         => reset_l,
      I_1MHZ_ENA        => ps2_1mhz_ena,
      CLK               => clk_14
      );

  --u_check_cart : entity work.BALLY_CHECK_CART
    --port map (
      --I_EXP_ADDR         => exp_addr,
      --I_EXP_DATA         => exp_data_out,
      --O_EXP_DATA         => exp_data_in,
      --O_EXP_OE_L         => exp_oe_l,

      --I_EXP_M1_L         => exp_m1_l,
      --I_EXP_MREQ_L       => exp_mreq_l,
      --I_EXP_IORQ_L       => exp_iorq_l,
      --I_EXP_WR_L         => exp_wr_l,
      --I_EXP_RD_L         => exp_rd_l,
      ----
      --O_CHAR_MSB         => check_cart_msb,
      --O_CHAR_LSB         => check_cart_lsb,
      ----
      --I_RESET_L          => reset_l,
      --ENA                => ena,
      --CLK                => clk_14
      --);

  -- if no expansion cart
  exp_data_in <= x"ff";
  exp_oe_l <= '1';
  --
  -- scan doubler
  --
  u_dblscan : entity work.BALLY_DBLSCAN
    port map (
      I_R               => video_r,
      I_G               => video_g,
      I_B               => video_b,
      I_HSYNC           => hsync_s,
      I_VSYNC           => vsync_s,
      --
      I_FPSYNC          => fpsync,
      --
      O_R               => video_r_x2,
      O_G               => video_g_x2,
      O_B               => video_b_x2,
      O_HSYNC           => hsync_x2,
      O_VSYNC           => vsync_x2,
      --
      I_RESET           => reset_s,
      ENA_X2            => ena_x2,
      ENA               => ena,
      CLK               => clk_14
    );
  --
	I_SW <= (others => '1'); -- VGA
  p_video_ouput : process
  begin
    wait until rising_edge(clk_14);
    -- switch is on (up) use scan converter and light led
    sw_reg <= I_SW;

    if (sw_reg(0) = '1') then
      O_LED(0) <= '1';
      O_VIDEO_R <= video_r_x2;
      O_VIDEO_G <= video_g_x2;
      O_VIDEO_B <= video_b_x2;
      O_HSYNC   <= hSync_X2;
      O_VSYNC   <= vSync_X2;
    else
      O_LED(0) <= '0';
      O_VIDEO_R <= video_r;
      O_VIDEO_G <= video_g;
      O_VIDEO_B <= video_b;
      O_HSYNC   <= hSync_s;
      O_VSYNC   <= vSync_s;
    end if;
  end process;
	vga_clk <= clk_14; -- needed for DE2
	red(5 downto 0) <= (others => '0');
	green(5 downto 0) <= (others => '0');
	blue(5 downto 0) <= (others => '0');
	
  --
  -- Audio
  --
  u_dac : entity work.dac
    generic map(
      msbi_g => 7
    )
    port  map(
      clk_i   => clk_ref,
      res_n_i => reset_l,
      dac_i   => audio,
      dac_o   => audio_pwm
    );

  O_AUDIO_L <= audio_pwm;
  O_AUDIO_R <= audio_pwm;

	-- feed directly to top-level DAC
	snd_data_l(15 downto 8) <= audio;
	snd_data_l(7 downto 0) <= (others => '0');
	snd_data_r(15 downto 8) <= audio;
	snd_data_r(7 downto 0) <= (others => '0');

  --
  -- cart slot
  --
  --p_flash : process
  --begin
  --  wait until rising_edge(clk_14);
  --  O_LED(3 downto 1) <= sw_reg(3 downto 1);

  --  O_STRATAFLASH_CE_L <= '1';
  --  if (sw_reg(1) = '0') then -- unplug card
  --    O_STRATAFLASH_CE_L <= cas_cs_l;
  --  end if;
  --  O_STRATAFLASH_OE_L <= '0';
  --  O_STRATAFLASH_WE_L <= '1';
  --  O_STRATAFLASH_BYTE <= '0';

  --  O_STRATAFLASH_ADDR(23 downto 15) <= (others => '0');

  --  O_STRATAFLASH_ADDR(14 downto 13) <= sw_reg(3 downto 2);
  --  O_STRATAFLASH_ADDR(12 downto  0) <= cas_addr(12 downto 0);
  --  B_STRATAFLASH_DATA <= (others => 'Z');
    -- should really sample and latch this at the correct point, but it seems to work
  --  cas_data <= B_STRATAFLASH_DATA;
  --end process;

	GEN_CART : if ASTROCADE_HAS_CART generate
	
		cart_inst : entity work.sprom
			generic map
			(
				INIT_FILE 	=> ASTROCADE_SRC_DIR & "/carts/" & ASTROCADE_CART_NAME & ".hex",
				NUMWORDS_A 	=> 8192,
				WIDTHAD_A 	=> 13
			)
			port map
			(
				clock				=> clk_14,
				address			=> cas_addr(12 downto 0),
				q						=> cas_data
			);
	
	end generate GEN_CART;
	
  spi_clk <= 'Z';
  spi_dout <= 'Z';
  spi_mode <= 'Z';
  spi_sel <= 'Z';
  
	leds(7 downto 4) <= (others => '0');
	  
end SYN;

