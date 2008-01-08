library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;

ENTITY nes_wram IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END nes_wram;

architecture SYN of nes_wram is
begin
   -- RAMB16_S9: Virtex-II/II-Pro, Spartan-3/3E 2k x 8 + 1 Parity bit Single-Port RAM
   -- Xilinx  HDL Language Template version 8.2.2i

   RAMB16_S9_inst : RAMB16_S9
   generic map (
      INIT => X"000", --  Value of output RAM registers at startup
      SRVAL => X"000", --  Ouput value upon SSR assertion
      WRITE_MODE => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      -- The following INIT_xx declarations specify the initial contents of the RAM
      -- Address 0 to 511
      INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 512 to 1023
      INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 1024 to 1535
      INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 1536 to 2047
      INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
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
      DO => q,      -- 8-bit Data Output
      DOP => open,    -- 1-bit parity Output
      ADDR => address,  -- 11-bit Address Input
      CLK => clock,    -- Clock
      DI => data,      -- 8-bit Data Input
      DIP => "0",    -- 1-bit parity Input
      EN => '1',      -- RAM Enable Input
      SSR => '0',    -- Synchronous Set/Reset Input
      WE => wren       -- Write Enable Input
   );
							
end SYN;

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.STD_MATCH;
use ieee.std_logic_arith.EXT;

library UNISIM;
use UNISIM.VComponents.all;

ENTITY dblscan_ram IS
	GENERIC
	(
		WIDTH	: natural
	);
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock_a		: IN STD_LOGIC ;
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '1';
		wren_b		: IN STD_LOGIC  := '1';
		q_a		: OUT STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0)
	);
END dblscan_ram;

architecture SYN of dblscan_ram is
  component xilinx_dblscan_ram is
    port
    (
      clka    : in std_logic;
      addra   : in std_logic_vector(10 downto 0);
      douta   : out std_logic_vector(17 downto 0);
      
      clkb    : in std_logic;
      addrb   : in std_logic_vector(10 downto 0);
      dinb    : in std_logic_vector(17 downto 0);
      web     : in std_logic
    );
  end component xilinx_dblscan_ram;
begin
  ram_inst : xilinx_dblscan_ram
    port map
    (
      clka    => clock_a,
      addra   => address_a,
      douta   => q_a,
      
      clkb    => clock_b,
      addrb   => address_b,
      dinb    => data_b,
      web     => wren_b
    );
end SYN;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;

ENTITY ppu_ciram IS
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock_a		: IN STD_LOGIC ;
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '1';
		wren_b		: IN STD_LOGIC  := '1';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END ppu_ciram;

architecture SYN of ppu_ciram is
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
      INIT_00 => X"2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F",
      INIT_01 => X"2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E",
      INIT_02 => X"2E2F2E2F4E79504D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4F782D2E2F2E2F",
      INIT_03 => X"2F2E4E794D4D504D4D4D4D4D4D4D4D4D4D4D4D7574737271704F4D4D782D2F2E",
      INIT_04 => X"4E794D4D4D7C24242424242424242424242424242424242424247B4D4D4D782D",
      INIT_05 => X"4D4D4D4D7C242424242424242424242424242424242424242424247B4D4D4D4D",
      INIT_06 => X"4D4D4D7C242424242436353232323234333232323231306B6A6A6A6A654D4D4D",
      INIT_07 => X"4D4D7C2424242424243A394D4D4D4D4D4D4D4D4D4D38376F0076FF146C7B4D4D",
      INIT_08 => X"4D7C242424242424243E3D4D4D4D4D4D4D4D4D4D4D3C3B6F767676766C247B4D",
      INIT_09 => X"7C2424AF7D24242424444332323232424132323232403F6F0076110F6C24247B",
      INIT_0A => X"242424B0AA2424244A49484D4D4D4D6E6D4D4D4D4D47468C8888888886242424",
      INIT_0B => X"242424B1AB2424249E93924D4D4D4D6E6D4D4D4D4D91909B2424242424242424",
      INIT_0C => X"242424B2AC245C5B5A5956555756554B58565557565554535251242424242424",
      INIT_0D => X"24241AB3AD246968676662616362614C646261636261605F5E5D242424242424",
      INIT_0E => X"242423241324249A99A14D4D4D4D4D6E6D4D4D4D4D4DA0969524242424242424",
      INIT_0F => X"242424242424249E4D8E4D4D4D4D4D6E6D4D4D4D4D4D8D4D9B24242424242424",
      -- Address 512 to 1023
      INIT_10 => X"24242424242424A293924D4D4D4D4D6E6D4D4D4D4D4D91909F24242424242424",
      INIT_11 => X"2424242424242494984D4D4D4D4D4D6E6D4D4D4D4D4D4D978F24242424242424",
      INIT_12 => X"2424242424249A999D4D4D4D4D4D4D6E6D4D4D4D4D4D4D9C9695242424242424",
      INIT_13 => X"2424242424249E4D8BA4A4A4A4A4A48A89A4A4A4A4A4A4874D9B242424242424",
      INIT_14 => X"242424242424A24D8E4D4D4D4D4D4D4D4D4D4D4D4D4D4D8D4D9F242424242424",
      INIT_15 => X"2424242424249493924D4D4D4D4D4D4D4D4D4D4D4D4D4D91908F242424242424",
      INIT_16 => X"24242424249A99984D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D9796952424242424",
      INIT_17 => X"24242424249E4D9D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D9C4D9B2424242424",
      INIT_18 => X"2424242424A24DA14D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4DA04D9F2424242424",
      INIT_19 => X"2424242424A9A4A8A4A4A4A4A4A4A4A7A6A4A4A4A4A4A4A4A5A4A32424242424",
      INIT_1A => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_1B => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_1C => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_1D => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_1E => X"00000000000000001944000000000002BB0C0000000002EAAAAAAAAAAAAAAAAA",
      INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 1024 to 1535
      INIT_20 => X"2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F",
      INIT_21 => X"2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E2F2E",
      INIT_22 => X"2E2F2E2F4E79504D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4F782D2E2F2E2F",
      INIT_23 => X"2F2E4E794D4D504D4D4D4D4D4D4D4D4D4D4D4D7574737271704F4D4D782D2F2E",
      INIT_24 => X"4E794D4D4D7C24242424242424242424242424242424242424247B4D4D4D782D",
      INIT_25 => X"4D4D4D4D7C242424242424242424242424242424242424242424247B4D4D4D4D",
      INIT_26 => X"4D4D4D7C242424242436353232323234333232323231306B6A6A6A6A654D4D4D",
      INIT_27 => X"4D4D7C2424242424243A394D4D4D4D4D4D4D4D4D4D38376F0076FF146C7B4D4D",
      INIT_28 => X"4D7C242424242424243E3D4D4D4D4D4D4D4D4D4D4D3C3B6F767676766C247B4D",
      INIT_29 => X"7C2424AF7D24242424444332323232424132323232403F6F0076110F6C24247B",
      INIT_2A => X"242424B0AA2424244A49484D4D4D4D6E6D4D4D4D4D47468C8888888886242424",
      INIT_2B => X"242424B1AB2424249E93924D4D4D4D6E6D4D4D4D4D91909B2424242424242424",
      INIT_2C => X"242424B2AC245C5B5A5956555756554B58565557565554535251242424242424",
      INIT_2D => X"24241AB3AD246968676662616362614C646261636261605F5E5D242424242424",
      INIT_2E => X"242423241324249A99A14D4D4D4D4D6E6D4D4D4D4D4DA0969524242424242424",
      INIT_2F => X"242424242424249E4D8E4D4D4D4D4D6E6D4D4D4D4D4D8D4D9B24242424242424",
      -- Address 1536 to 2047
      INIT_30 => X"24242424242424A293924D4D4D4D4D6E6D4D4D4D4D4D91909F24242424242424",
      INIT_31 => X"2424242424242494984D4D4D4D4D4D6E6D4D4D4D4D4D4D978F24242424242424",
      INIT_32 => X"2424242424249A999D4D4D4D4D4D4D6E6D4D4D4D4D4D4D9C9695242424242424",
      INIT_33 => X"2424242424249E4D8BA4A4A4A4A4A48A89A4A4A4A4A4A4874D9B242424242424",
      INIT_34 => X"242424242424A24D8E4D4D4D4D4D4D4D4D4D4D4D4D4D4D8D4D9F242424242424",
      INIT_35 => X"2424242424249493924D4D4D4D4D4D4D4D4D4D4D4D4D4D91908F242424242424",
      INIT_36 => X"24242424249A99984D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D9796952424242424",
      INIT_37 => X"24242424249E4D9D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D9C4D9B2424242424",
      INIT_38 => X"2424242424A24DA14D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4DA04D9F2424242424",
      INIT_39 => X"2424242424A9A4A8A4A4A4A4A4A4A4A7A6A4A4A4A4A4A4A4A5A4A32424242424",
      INIT_3A => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_3B => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_3C => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_3D => X"2424242424242424242424242424242424242424242424242424242424242424",
      INIT_3E => X"00000000000000001944000000000002BB0C0000000002EAAAAAAAAAAAAAAAAA",
      INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
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
      ADDRA => address_a,  -- Port A 11-bit Address Input
      ADDRB => address_b,  -- Port B 11-bit Address Input
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
end SYN;
