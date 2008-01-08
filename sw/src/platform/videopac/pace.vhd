Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use ieee.std_logic_arith.EXT;

library work;
use work.pace_pkg.all;
use work.kbd_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;

use work.board_misc_comp_pack.dac;
use work.vp_console_comp_pack.vp_console;
--use work.snespad_comp.snespad;
use work.i8244_col_pack.all;

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
    sram_i          : in from_SRAM_t;
    sram_o          : out to_SRAM_t;

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

  --component vp_pll
  --  PORT (
  --    inclk0 : IN STD_LOGIC  := '0';
  --    c0     : OUT STD_LOGIC ;
  --    locked : OUT STD_LOGIC 
  --  );
  --end component;

  component vp_por
    generic (
      delay_g     : integer := 4;
      cnt_width_g : integer := 2
    );
    port (
      clk_i   : in  std_logic;
      por_n_o : out std_logic
    );
  end component;

  component lpm_rom
    generic (
      LPM_WIDTH           : positive;
      LPM_WIDTHAD         : positive;
      LPM_NUMWORDS        : natural := 0;
      LPM_ADDRESS_CONTROL : string  := "REGISTERED";
      LPM_OUTDATA         : string  := "REGISTERED";
      LPM_FILE            : string;
      LPM_TYPE            : string  := "LPM_ROM";
      LPM_HINT            : string  := "UNUSED"
    );
    port (
      ADDRESS  : in STD_LOGIC_VECTOR(LPM_WIDTHAD-1 downto 0);
      INCLOCK  : in STD_LOGIC := '0';
      MEMENAB  : in STD_LOGIC := '1';
      Q        : out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0)
    );
  end component;

  signal clk_s          : std_logic;

  -- CPU clock = PLL clock / 6
  constant cnt_cpu_c    : unsigned(2 downto 0) := to_unsigned(5, 3);
  -- VDC clock = PLL clock / 5
  constant cnt_vdc_c    : unsigned(2 downto 0) := to_unsigned(4, 3);
  signal cnt_cpu_q      : unsigned(2 downto 0);
  signal cnt_vdc_q      : unsigned(2 downto 0);
  signal clk_cpu_en_s,
         clk_vdc_en_s   : std_logic;

  signal pll_locked_s   : std_logic;
  signal reset_n_s      : std_logic;
  signal por_n_s        : std_logic;

  signal cart_a_s       : std_logic_vector(11 downto 0);
  signal rom_a_s        : std_logic_vector(12 downto 0);
  signal cart_d_s,
         rom_d_s        : std_logic_vector( 7 downto 0);
  signal cart_bs0_s,
         cart_bs1_s,
         cart_psen_n_s  : std_logic;

  signal keyb_dec_s     : std_logic_vector( 6 downto 1);
  signal keyb_enc_s     : std_logic_vector(14 downto 7);

  signal r_s,
         g_s,
         b_s,
         l_s            : std_logic;
  signal hsync_n_s,
         vsync_n_s      : std_logic;

  signal snd_s          : std_logic;
  signal snd_vec_s      : std_logic_vector(3 downto 0);

  signal joy_up_n_s,
         joy_down_n_s,
         joy_left_n_s,
         joy_right_n_s,
         joy_action_n_s : std_logic_vector( 1 downto 0);
  signal but_a_s,
         but_b_s,
         but_x_s,
         but_y_s,
         but_start_s,
         but_sel_s,
         but_tl_s,
         but_tr_s       : std_logic_vector( 1 downto 0);
  signal but_up_s,
         but_down_s,
         but_left_s,
         but_right_s    : std_logic_vector( 1 downto 0);

  signal dac_audio_s    : std_logic_vector( 7 downto 0);
  signal audio_s        : std_logic;

  signal vdd_s          : std_logic;
  signal gnd_s          : std_logic;

	-- aliases for PACE
	alias ext_clk_i				: std_logic is clk(0);
	alias rgb_r_o					: std_logic_vector(2 downto 0) is red(9 downto 7);
	alias rgb_g_o					: std_logic_vector(2 downto 0) is green(9 downto 7);
	alias rgb_b_o					: std_logic_vector(2 downto 0) is blue(9 downto 7);
	alias txd_o						: std_logic is ser_tx;
	alias rxd_i						: std_logic is ser_rx;
	
	-- signals for PACE
	--signal comp_sync_n_o	: std_logic;
  signal audio_r_o			: std_logic;
  signal audio_l_o 			: std_logic;
  signal audio_o   			: std_logic_vector(dac_audio_s'range);
	signal rts_o					: std_logic;
	signal cts_i					: std_logic;
	signal keys_s					: std_logic_vector(15 downto 0);
	signal joy_s					: std_logic_vector(15 downto 0);
	
begin

  vdd_s <= '1';
  gnd_s <= '0';


  por_b : vp_por
    generic map (
       delay_g     => 4,
       cnt_width_g => 2
    )
    port map (
       clk_i   => clk_s,
       por_n_o => por_n_s
    );


  reset_n_s <= (but_tl_s(0) or but_tr_s(0)) and pll_locked_s and por_n_s;


  -----------------------------------------------------------------------------
  -- The PLL
  -----------------------------------------------------------------------------
  pll_b : entity work.vp_pll
    port map (
      inclk0 => ext_clk_i,
      c0     => clk_s,
      locked => pll_locked_s
    );
	

  -----------------------------------------------------------------------------
  -- Process clk_en
  --
  -- Purpose:
  --   Generates the CPU and VDC clock enables.
  --
  clk_en: process (clk_s, reset_n_s)
  begin
    if reset_n_s = '0' then
      cnt_cpu_q <= cnt_cpu_c;
      cnt_vdc_q <= cnt_vdc_c;
    elsif rising_edge(clk_s) then
      if clk_cpu_en_s = '1' then
        cnt_cpu_q <= cnt_cpu_c;
      else
        cnt_cpu_q <= cnt_cpu_q - 1;
      end if;
      --
      if clk_vdc_en_s = '1' then
        cnt_vdc_q <= cnt_vdc_c;
      else
        cnt_vdc_q <= cnt_vdc_q - 1;
      end if;
    end if;
  end process clk_en;
  --
  clk_cpu_en_s <= '1' when cnt_cpu_q = 0 else '0';
  clk_vdc_en_s <= '1' when cnt_vdc_q = 0 else '0';
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- The Videopac console
  -----------------------------------------------------------------------------
  vp_console_b : vp_console
    generic map (
      is_pal_g => 1
    )
    port map (
      clk_i          => clk_s,
      clk_cpu_en_i   => clk_cpu_en_s,
      clk_vdc_en_i   => clk_vdc_en_s,
      res_n_i        => reset_n_s,
      cart_cs_o      => open,
      cart_cs_n_o    => open,
      cart_wr_n_o    => open,
      cart_a_o       => cart_a_s,
      cart_d_i       => cart_d_s,
      cart_bs0_o     => cart_bs0_s,
      cart_bs1_o     => cart_bs1_s,
      cart_psen_n_o  => cart_psen_n_s,
      cart_t0_i      => gnd_s,
      cart_t0_o      => open,
      cart_t0_dir_o  => open,
      -- idx = 0 : left joystick
      -- idx = 1 : right joystick
      joy_up_n_i     => joy_up_n_s,
      joy_down_n_i   => joy_down_n_s,
      joy_left_n_i   => joy_left_n_s,
      joy_right_n_i  => joy_right_n_s,
      joy_action_n_i => joy_action_n_s,
      keyb_dec_o     => keyb_dec_s,
      keyb_enc_i     => keyb_enc_s,
      r_o            => r_s,
      g_o            => g_s,
      b_o            => b_s,
      l_o            => l_s,
      hsync_n_o      => hsync_n_s,
      vsync_n_o      => vsync_n_s,
      hbl_o          => open,
      vbl_o          => open,
      snd_o          => snd_s,
      snd_vec_o      => snd_vec_s
    );
  --
  rgb: process (clk_s, reset_n_s)
    variable col_v : natural range 0 to 15;
  begin
    if reset_n_s = '0' then
      rgb_r_o <= (others => '0');
      rgb_g_o <= (others => '0');
      rgb_b_o <= (others => '0');

    elsif rising_edge(clk_s) then
      col_v := to_integer(unsigned'(l_s & r_s & g_s & b_s));
      rgb_r_o <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(r_c), 8))(7 downto 5);
      rgb_g_o <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(g_c), 8))(7 downto 5);
      rgb_b_o <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(b_c), 8))(7 downto 5);
    end if;
  end process rgb;
  --
  --comp_sync_n_o <= hsync_n_s and vsync_n_s;
	hsync <= hsync_n_s;
	vsync <= vsync_n_s;
	
  -----------------------------------------------------------------------------
  -- The cartridge ROM
  -----------------------------------------------------------------------------
  rom_a_s <= ( 0 => cart_a_s( 0),
               1 => cart_a_s( 1),
               2 => cart_a_s( 2),
               3 => cart_a_s( 3),
               4 => cart_a_s( 4),
               5 => cart_a_s( 5),
               6 => cart_a_s( 6),
               7 => cart_a_s( 7),
               8 => cart_a_s( 8),
               9 => cart_a_s( 9),
              10 => cart_a_s(11),
              11 => cart_bs0_s,
              12 => cart_bs1_s);
  --
  cart_rom_b : lpm_rom
    generic map (
      LPM_WIDTH           =>  8,
      LPM_WIDTHAD         => 13,
      LPM_ADDRESS_CONTROL => "REGISTERED",
      LPM_OUTDATA         => "UNREGISTERED",
      LPM_FILE            => VIDEOPAC_SOURCE_ROOT_DIR & "carts/" & VIDEOPAC_CART_NAME,
      LPM_TYPE            => "LPM_ROM"
    )
    port map (
      ADDRESS  => rom_a_s(12 downto 0),
      INCLOCK  => clk_s,
      MEMENAB  => vdd_s,
      Q        => rom_d_s
    );
  --
  cart_d_s <=   rom_d_s
              when cart_psen_n_s = '0' else
                (others => '1');


--  -----------------------------------------------------------------------------
--  -- Process sram_ctrl
--  --
--  -- Purpose:
--  --   Maps the external SRAM to the cartridge interface.
--  --
--  sram_ctrl: process (cart_a_s,
--                      rama_d_b)
--  begin
--    rama_lb_n_o <= '1';
--    rama_ub_n_o <= '1';
--    rama_a_o(17 downto 11) <= (others => '0');
--    rama_a_o(10 downto  0) <= cart_a_s(11 downto 1);
--
--    if cart_a_s(0) = '0' then
--      rama_lb_n_o <= '0';
--      cart_d_s <= rama_d_b( 7 downto 0);
--    else
--      rama_ub_n_o <= '0';
--      cart_d_s <= rama_d_b(15 downto 8);
--    end if;
--  end process sram_ctrl;
--  --
--  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- SNES Gamepads
  -----------------------------------------------------------------------------
--  snespads_b : snespad
--    generic map (
--      num_pads_g       => 2,
--      reset_level_g    => 0,
--      button_level_g   => 0,
--      clocks_per_6us_g => 198
--    )
--    port map (
--      clk_i            => clk_s,
--      reset_i          => por_n_s,
--      pad_clk_o        => pad_clk_o,
--      pad_latch_o      => pad_latch_o,
--      pad_data_i       => pad_data_i,
--      but_a_o          => but_a_s,
--      but_b_o          => but_b_s,
--      but_x_o          => but_x_s,
--      but_y_o          => but_y_s,
--      but_start_o      => but_start_s,
--      but_sel_o        => but_sel_s,
--      but_tl_o         => but_tl_s,
--      but_tr_o         => but_tr_s,
--      but_up_o         => but_up_s,
--      but_down_o       => but_down_s,
--      but_left_o       => but_left_s,
--      but_right_o      => but_right_s
--    );

	inputs_inst : entity work.videopacKeyboard
	port map
	(
	    clk       	=> clk_s,
	    reset     	=> reset,

			-- inputs from PS/2 port
	    ps2_clk  		=> ps2clk,
	    ps2_data 		=> ps2data,

	    -- user outputs
			keys				=> keys_s,
			joy					=> joy_s
	);

	-- map 'joystick' inputs to videopac joystick inputs
	but_up_s <= (0 => not joy_s(0), 1=> '1');
	but_down_s <= (0 => not joy_s(1), 1=> '1');
	but_left_s <= (0 => not joy_s(2), 1=> '1');
	but_right_s <= (0 => not joy_s(3), 1=> '1');
	but_a_s <= (0 => not joy_s(4), 1=> '1');
	but_tl_s <= (0 => not joy_s(5), 1=> '1');
	but_tr_s <= (0 => not joy_s(6), 1=> '1');
		
  -- just connect the single gamepad to both joysticks
  joy_up_n_s     <= (0 => but_up_s(0),
                     1 => but_up_s(0));
  joy_down_n_s   <= (0 => but_down_s(0),
                     1 => but_down_s(0));
  joy_left_n_s   <= (0 => but_left_s(0),
                     1 => but_left_s(0));
  joy_right_n_s  <= (0 => but_right_s(0),
                     1 => but_right_s(0));
  joy_action_n_s <= (0 => but_a_s(0),
                     1 => but_a_s(0));
  --
  keyb_enc_s( 7) <= '1';
  keyb_enc_s( 8) <= keyb_dec_s(1) or but_tl_s(0) or but_a_s(0);
  keyb_enc_s( 9) <= '1';
  keyb_enc_s(10) <= '1';
  keyb_enc_s(11) <= '1';
  keyb_enc_s(12) <= '1';
  keyb_enc_s(13) <= '1';
  keyb_enc_s(14) <= '1';
                   

  -----------------------------------------------------------------------------
  -- Digital-analog audio converter
  -----------------------------------------------------------------------------
  dac_audio_s(7 downto 4) <= snd_vec_s;
  dac_audio_s(3 downto 0) <= (others => '0');
  --
  dac_b : dac
    generic map (
      msbi_g => 7
    )
    port map (
      clk_i   => clk_s,
      res_n_i => por_n_s,
      dac_i   => dac_audio_s,
      dac_o   => audio_s
    );
  --
  audio_r_o <= audio_s;
  audio_l_o <= audio_s;
  audio_o   <= dac_audio_s;


  -----------------------------------------------------------------------------
  -- JOP pin defaults
  -----------------------------------------------------------------------------
  -- UART
  txd_o       <= '1';
  rts_o       <= '1';
  -- RAMA
  --rama_a_o    <= (others => '0');
  --rama_cs_n_o <= '0';
  --rama_oe_n_o <= '0';
  --rama_we_n_o <= '1';
  --rama_lb_n_o <= '1';
  --rama_ub_n_o <= '1';
  -- RAMB
  --ramb_a_o    <= (others => '0');
  --ramb_cs_n_o <= '1';
  --ramb_oe_n_o <= '1';
  --ramb_we_n_o <= '1';
  --ramb_lb_n_o <= '1';
  --ramb_ub_n_o <= '1';
  -- Flash
  --fl_a_o      <= (others => '0');
  --fl_we_n_o   <= '1';
  --fl_oe_n_o   <= '1';
  --fl_cs_n_o   <= '1';
  --fl_cs2_n_o  <= '1';

	-- not used by videopac
	sram_o.a <= (others => 'Z');
	sram_o.d <= (others => 'Z');
	sram_o.be <= (others => 'Z');
	sram_o.cs <= '0';
	sram_o.we <= '0';
	sram_o.oe <= '0';
	vga_clk <= 'Z';
	red(red'left-rgb_r_o'length downto 0) <= (others => '0');
	green(green'left-rgb_g_o'length downto 0) <= (others => '0');
	blue(blue'left-rgb_b_o'length downto 0) <= (others => '0');
	lcm_data <= (others => 'X');
	bw_cvbs <= (others => 'X');
	gs_cvbs <= (others => 'X');
	spi_clk <= 'Z';
	spi_mode <= 'Z';
	spi_sel <= 'Z';
	spi_dout <= 'Z';
	leds<= (others => '1');
	
	-- TBD
	snd_clk <= 'Z';
	snd_data_l <= (others => 'X');
	snd_data_r <= (others => 'X');
	
end SYN;

