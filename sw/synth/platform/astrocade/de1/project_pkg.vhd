library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;
use work.target_pkg.all;

package project_pkg is

	--  
	-- PACE constants which *MUST* be defined
	--
	
  -- Reference clock is 50MHz
	constant PACE_HAS_PLL										: boolean := false;
  constant PACE_CLK0_DIVIDE_BY        		: natural := 1; -- not used
  constant PACE_CLK0_MULTIPLY_BY      		: natural := 1; -- not used
  constant PACE_CLK1_DIVIDE_BY        		: natural := 1; -- not used
  constant PACE_CLK1_MULTIPLY_BY      		: natural := 1; -- not used

  -- DE1-specific constants
  constant DE1_JAMMA_IS_MAPLE             : boolean := false;
  constant DE1_JAMMA_IS_NGC               : boolean := true;

	-- Astrocade-specific constants
	constant ASTROCADE_HAS_CART							: boolean := true;
	constant ASTROCADE_CART_NAME						: string := "muncher";
	--constant ASTROCADE_CART_NAME						: string := "treasure";
	
end;