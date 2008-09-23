library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.project_pkg.all;
use work.target_pkg.all;

package platform_pkg is

	--  
	-- PACE constants which *MUST* be defined
	--

	constant PACE_VIDEO_NUM_BITMAPS 	  : natural := 1;
	constant PACE_VIDEO_NUM_TILEMAPS 	  : natural := 1;		-- used for video counter only
	constant PACE_VIDEO_NUM_SPRITES 	  : natural := 0;
	constant PACE_VIDEO_H_SIZE				  : integer := 304;
	constant PACE_VIDEO_V_SIZE				  : integer := 256;
	constant PACE_VIDEO_PIPELINE_DELAY  : integer := 3;
	
	--
	-- Platform-specific constants (optional)
	--

end;
