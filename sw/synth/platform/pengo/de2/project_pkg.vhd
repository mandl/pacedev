library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;

package project_pkg is

	--  
	-- PACE constants which *MUST* be defined
	--
	
  -- Reference clock is 50MHz
	constant PACE_HAS_PLL								      : boolean := true;
  --constant PACE_HAS_SRAM                    : boolean := true;
  constant PACE_HAS_SDRAM                   : boolean := false;
  --constant PACE_HAS_FLASH                   : boolean := false;
  constant PACE_HAS_SERIAL                  : boolean := false;
  
	constant PACE_JAMMA	                      : PACEJamma_t := PACE_JAMMA_NONE;

  constant PACE_VIDEO_CONTROLLER_TYPE       : PACEVideoController_t := PACE_VIDEO_VGA_800x600_60Hz;
  constant PACE_CLK0_DIVIDE_BY        		  : natural := 5;
  constant PACE_CLK0_MULTIPLY_BY      		  : natural := 3;   -- 50*3/5 = 30MHz
  constant PACE_CLK1_DIVIDE_BY        		  : natural := 5;
  constant PACE_CLK1_MULTIPLY_BY      		  : natural := 4;  	-- 50*4/5 = 40MHz
	constant PACE_VIDEO_H_SCALE         		  : integer := 2;
	constant PACE_VIDEO_V_SCALE         		  : integer := 2;
  constant PACE_VIDEO_H_SYNC_POLARITY       : std_logic := '1';
  constant PACE_VIDEO_V_SYNC_POLARITY       : std_logic := '1';

  constant PACE_VIDEO_BORDER_RGB            : RGB_t := RGB_GREEN;

  constant PACE_HAS_OSD                     : boolean := false;
  constant PACE_OSD_XPOS                    : natural := 0;
  constant PACE_OSD_YPOS                    : natural := 0;

	-- DE2 constants which *MUST* be defined
	
	constant DE2_LCD_LINE2							      : string := "   PENGO-LCD    ";
		
	-- Pengo-specific constants
			
  constant PENGO_ROMS_IN_FLASH              : boolean := false;
	constant PENGO_USE_VIDEO_VBLANK           : boolean := true;
	constant PENGO_USE_INTERNAL_WRAM				  : boolean := false;

  -- derived
  constant PACE_HAS_FLASH                   : boolean := PENGO_ROMS_IN_FLASH;
  constant PACE_HAS_SRAM                    : boolean := not PENGO_USE_INTERNAL_WRAM;

  type from_PROJECT_IO_t is record
    not_used  : std_logic;
  end record;

  type to_PROJECT_IO_t is record
    not_used  : std_logic;
  end record;

end;
