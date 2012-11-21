library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;

package target_pkg is

	--  
	-- PACE constants which *MUST* be defined
	--
	
	constant PACE_TARGET 				: PACETargetType := PACE_TARGET_DE2;

	constant PACE_FPGA_VENDOR		: PACEFpgaVendor_t := PACE_FPGA_VENDOR_ALTERA;
	constant PACE_FPGA_FAMILY		: PACEFpgaFamily_t := PACE_FPGA_FAMILY_CYCLONE2;

  constant PACE_CLKIN0      : natural := 50;
  constant PACE_CLKIN1      : natural := 27;
  constant PACE_HAS_SPI     : boolean := false;

	--
	-- DE2-specific constants
	--
	
	constant DE2_LCD_LINE1							: string := "   PACE  2009   ";		-- 16 chars exactly
	
  type from_TARGET_IO_t is record
    read_data_n         : std_logic;
    write_protect_n     : std_logic;
    index_pulse_n       : std_logic;
    track_zero_n        : std_logic;
    rclk                : std_logic;
  end record;

  type to_TARGET_IO_t is record
    ds_n                : std_logic_vector(3 downto 0);
    motor_on            : std_logic;
    step_n              : std_logic;
    direction_select_n  : std_logic;
    write_gate_n        : std_logic;
    write_data_n        : std_logic;
  end record;

end;
