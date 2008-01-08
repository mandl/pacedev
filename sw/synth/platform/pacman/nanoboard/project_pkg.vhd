library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;

package project_pkg is

	--  
	-- PACE constants which *MUST* be defined
	--
	
  constant PACE_CLK0_DIVIDE_BY        : natural := 2;
  constant PACE_CLK0_MULTIPLY_BY      : natural := 3;   -- 20*3/2 = 30MHz
  constant PACE_CLK1_DIVIDE_BY        : natural := 1;
  constant PACE_CLK1_MULTIPLY_BY      : natural := 2;   -- 20*2/1 = 40MHz

	constant PACE_VIDEO_H_SCALE       	: integer := 2;
	constant PACE_VIDEO_V_SCALE       	: integer := 2;

	constant USE_VIDEO_VBLANK_INTERRUPT : boolean := true;
	
end;
