library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;

package project_pkg is

	--  
	-- PACE constants which *MUST* be defined
	--
	
  -- Reference clock is 24MHz
  constant PACE_CLK0_DIVIDE_BY        : natural := 8;
  constant PACE_CLK0_MULTIPLY_BY      : natural := 9;   -- 24*9/8 = 27MHz
  constant PACE_CLK1_DIVIDE_BY        : natural := 16;
  constant PACE_CLK1_MULTIPLY_BY      : natural := 9;		-- 24*9/16 = 13.5MHz
	
	constant PACE_VIDEO_H_SCALE         : integer := 2;
	constant PACE_VIDEO_V_SCALE         : integer := 1;

	constant PACE_ENABLE_ADV724					: std_logic := '1';
	constant PACE_ADV724_STD						: std_logic := ADV724_STD_PAL;

	-- Pacman-specific constants
			
	constant PACMAN_CPU_CLK_ENA_DIVIDE_BY		: natural := 9;
	constant PACMAN_1MHz_CLK0_COUNTS				: natural := 27;
	
	constant USE_VIDEO_VBLANK_INTERRUPT : boolean := false;
	
end;
