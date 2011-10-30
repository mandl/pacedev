library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package platform_variant_pkg is

	--
	-- Platform-variant-specific constants (optional)
	--

  -- MAME says 231x292
	constant WILLIAMS_VIDEO_H_SIZE		: integer := 256;
	constant WILLIAMS_VIDEO_V_SIZE		: integer := 292;

  constant WILLIAMS_HAS_BLITTER     : boolean := true;
  constant WILLIAMS_SC02_REVISION   : integer := 1;
  constant WILLIAMS_SC02_CLIP_ADDR  : unsigned(15 downto 0) := X"C000";

  constant WILLIAMS_NVRAM_WIDTH     : integer := 4;
  
  constant PLATFORM_VARIANT         : string := "playball";
  
end;
