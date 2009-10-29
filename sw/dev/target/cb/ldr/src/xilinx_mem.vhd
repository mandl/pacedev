library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trs80_rom is
  port
  (
    clock     : in std_logic;
    address   : in std_logic_vector(10 downto 0);
    q         : out std_logic_vector(7 downto 0)
  );
end entity trs80_rom;

architecture SYN of trs80_rom is
  component xilinx_trs80_rom is
    port
    (
      clk     : in std_logic;
      addr    : in std_logic_vector(10 downto 0);
      dout    : out std_logic_vector(7 downto 0)
    );
  end component xilinx_trs80_rom;
begin
  rom_inst : xilinx_trs80_rom
    port map
    (
      clk     => clock,
      addr    => address,
      dout    => q
    );
end architecture SYN;
	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trs80_tile_rom is
  port
  (
    clock     : in std_logic;
    address   : in std_logic_vector(11 downto 0);
    q         : out std_logic_vector(7 downto 0)
  );
end entity trs80_tile_rom;

architecture SYN of trs80_tile_rom is
  component xilinx_trs80_tile_rom is
    port
    (
      clk     : in std_logic;
      addr    : in std_logic_vector(10 downto 0);
      dout    : out std_logic_vector(7 downto 0)
    );
  end component xilinx_trs80_tile_rom;
begin
  rom_inst : xilinx_trs80_tile_rom
    port map
    (
      clk     => clock,
      addr    => address(10 downto 0),
      dout    => q
    );
end architecture SYN;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VComponents.all;

entity trs80_vram is
  port
  (
    clock_b     : in std_logic;
    address_b   : in std_logic_vector(9 downto 0);
    wren_b      : in std_logic;
    data_b      : in std_logic_vector(7 downto 0);
    q_b         : out std_logic_vector(7 downto 0);
    
    clock_a     : in std_logic;
    address_a   : in std_logic_vector(9 downto 0);
    wren_a      : in std_logic;
    data_a      : in std_logic_vector(7 downto 0);
    q_a         : out std_logic_vector(7 downto 0)
  );
end entity trs80_vram;

architecture SYN of trs80_vram is
begin
   -- RAMB16_S9_S9: Virtex-II/II-Pro, Spartan-3/3E 2k x 8 + 1 Parity bit Dual-Port RAM
   -- Xilinx  HDL Language Template version 8.2.2i

   RAMB16_S9_S9_inst : RAMB16_S9_S9
   generic map (
      INIT_A => X"000", --  Value of output RAM registers on Port A at startup
      INIT_B => X"000", --  Value of output RAM registers on Port B at startup
      SRVAL_A => X"000", --  Port A ouput value upon SSR assertion
      SRVAL_B => X"000", --  Port B ouput value upon SSR assertion
      WRITE_MODE_A => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      WRITE_MODE_B => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      SIM_COLLISION_CHECK => "ALL", -- "NONE", "WARNING", "GENERATE_X_ONLY", "ALL
      -- The following INIT_xx declarations specify the initial contents of the RAM
      -- Address 0 to 511
      INIT_00 => X"1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100",
      INIT_01 => X"3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A29282726252423222120",
      INIT_02 => X"5F5E5D5C5B5A595857565554535251504F4E4D4C4B4A49484746454443424140",
      INIT_03 => X"7F7E7D7C7B7A797877767574737271706F6E6D6C6B6A69686766656463626160",
      INIT_04 => X"9F9E9D9C9B9A999897969594939291908F8E8D8C8B8A89888786858483828180",
      INIT_05 => X"BFBEBDBCBBBAB9B8B7B6B5B4B3B2B1B0AFAEADACABAAA9A8A7A6A5A4A3A2A1A0",
      INIT_06 => X"DFDEDDDCDBDAD9D8D7D6D5D4D3D2D1D0CFCECDCCCBCAC9C8C7C6C5C4C3C2C1C0",
      INIT_07 => X"FFFEFDFCFBFAF9F8F7F6F5F4F3F2F1F0EFEEEDECEBEAE9E8E7E6E5E4E3E2E1E0",
      INIT_08 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_09 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_0A => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_0B => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_0C => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_0D => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_0E => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_0F => X"2020202020202020202020202020202020202020202020202020202020202020",
      -- Address 512 to 1023
      INIT_10 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_11 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_12 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_13 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_14 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_15 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_16 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_17 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_18 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_19 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_1A => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_1B => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_1C => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_1D => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_1E => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_1F => X"2020202020202020202020202020202020202020202020202020202020202020",
      -- Address 1024 to 1535
      INIT_20 => X"1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100",
      INIT_21 => X"3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A29282726252423222120",
      INIT_22 => X"5F5E5D5C5B5A595857565554535251504F4E4D4C4B4A49484746454443424140",
      INIT_23 => X"7F7E7D7C7B7A797877767574737271706F6E6D6C6B6A69686766656463626160",
      INIT_24 => X"9F9E9D9C9B9A999897969594939291908F8E8D8C8B8A89888786858483828180",
      INIT_25 => X"BFBEBDBCBBBAB9B8B7B6B5B4B3B2B1B0AFAEADACABAAA9A8A7A6A5A4A3A2A1A0",
      INIT_26 => X"DFDEDDDCDBDAD9D8D7D6D5D4D3D2D1D0CFCECDCCCBCAC9C8C7C6C5C4C3C2C1C0",
      INIT_27 => X"FFFEFDFCFBFAF9F8F7F6F5F4F3F2F1F0EFEEEDECEBEAE9E8E7E6E5E4E3E2E1E0",
      INIT_28 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_29 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_2A => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_2B => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_2C => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_2D => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_2E => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_2F => X"2020202020202020202020202020202020202020202020202020202020202020",
      -- Address 1536 to 2047
      INIT_30 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_31 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_32 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_33 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_34 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_35 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_36 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_37 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_38 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_39 => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_3A => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_3B => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_3C => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_3D => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_3E => X"2020202020202020202020202020202020202020202020202020202020202020",
      INIT_3F => X"2020202020202020202020202020202020202020202020202020202020202020",
      -- The next set of INITP_xx are for the parity bits
      -- Address 0 to 511
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 512 to 1023
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 1024 to 1535
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 1536 to 2047
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
   port map (
      DOA => q_a,      -- Port A 8-bit Data Output
      DOB => q_b,      -- Port B 8-bit Data Output
      DOPA => open,    -- Port A 1-bit Parity Output
      DOPB => open,    -- Port B 1-bit Parity Output
      ADDRA(10) => '0',  -- Port A 11-bit Address Input
      ADDRA(9 downto 0) => address_a,  -- Port A 11-bit Address Input
      ADDRB(10) => '0',  -- Port B 11-bit Address Input
      ADDRB(9 downto 0) => address_b,  -- Port B 11-bit Address Input
      CLKA => clock_a,    -- Port A Clock
      CLKB => clock_b,    -- Port B Clock
      DIA => data_a,      -- Port A 8-bit Data Input
      DIB => data_b,      -- Port B 8-bit Data Input
      DIPA => "0",    -- Port A 1-bit parity Input
      DIPB => "0",    -- Port-B 1-bit parity Input
      ENA => '1',      -- Port A RAM Enable Input
      ENB => '1',      -- PortB RAM Enable Input
      SSRA => '0',    -- Port A Synchronous Set/Reset Input
      SSRB => '0',    -- Port B Synchronous Set/Reset Input
      WEA => wren_a,      -- Port A Write Enable Input
      WEB => wren_b       -- Port B Write Enable Input
   );
end architecture SYN;

--
-- ************************************************************************
--    Here are all the guest roms
--    - only one will be instantiated in the platform
-- ************************************************************************
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY pacman_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END entity pacman_rom;

architecture SYN of pacman_rom is
  component xilinx_pacrom is
    port
    (
      clk     : in std_logic;
      addr    : in std_logic_vector(13 downto 0);
      dout    : out std_logic_vector(7 downto 0)
    );
  end component xilinx_pacrom;
begin
  rom_inst : xilinx_pacrom
    port map
    (
      clk     => clock,
      addr    => address,
      dout    => q
    );
end architecture SYN;
