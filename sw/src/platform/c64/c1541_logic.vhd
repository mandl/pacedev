library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

library work;
use work.platform_pkg.all;
use work.project_pkg.all;

--
-- Model 1541B
--

entity c1541_logic is
	generic
	(
		DEVICE_SELECT		: std_logic_vector(1 downto 0)
	);
	port
	(
		clk_32M					: in std_logic;
		reset						: in std_logic;

		-- serial bus
		sb_data_oe			: out std_logic;
		sb_data_in			: in std_logic;
		sb_clk_oe				: out std_logic;
		sb_clk_in				: in std_logic;
		sb_atn_oe				: out std_logic;
		sb_atn_in				: in std_logic;
		
		-- drive-side interface
		ds							: in std_logic_vector(1 downto 0);		-- device select
		di							: in std_logic_vector(7 downto 0);		-- disk write data
		do							: out std_logic_vector(7 downto 0);		-- disk read data
		mode						: out std_logic;											-- read/write
		stp							: out std_logic_vector(1 downto 0);		-- stepper motor control
		mtr							: out std_logic;											-- stepper motor on/off
		freq						: out std_logic_vector(1 downto 0);		-- motor frequency
		sync_n					: in std_logic;												-- reading SYNC bytes
		byte_n					: in std_logic;												-- byte ready
		wps_n						: in std_logic;												-- write-protect sense
		tr00_sense_n		: in std_logic;												-- track 0 sense (unused?)
		act							: out std_logic												-- activity LED
	);
end c1541_logic;

architecture SYN of c1541_logic is

	-- clocks, reset
	signal reset_n				: std_logic;
	signal clk_4M_en			: std_logic;
	signal p2_h						: std_logic;
  signal clk_1M_pulse   : std_logic;
		
	-- cpu signals	
	signal cpu_a					: std_logic_vector(23 downto 0);
	signal cpu_di					: std_logic_vector(7 downto 0);
	signal cpu_do					: std_logic_vector(7 downto 0);
	signal cpu_rw_n				: std_logic;
	signal cpu_irq_n			: std_logic;
	signal cpu_so_n				: std_logic;

	-- rom signals
	signal rom_cs					: std_logic;
	signal rom_do					: std_logic_vector(cpu_di'range);	

	-- ram signals
	signal ram_cs					: std_logic;
	signal ram_wr					: std_logic;
	signal ram_do					: std_logic_vector(cpu_di'range);
	
	-- UC1 (VIA6522) signals
	signal uc1_do					: std_logic_vector(7 downto 0);
	signal uc1_do_oe_n		: std_logic;
	signal uc1_cs1				: std_logic;
	signal uc1_cs2_n			: std_logic;
	signal uc1_irq_n			: std_logic;
	signal uc1_ca1_i			: std_logic;
	signal uc1_pa_i				: std_logic_vector(7 downto 0);
	signal uc1_pb_i				: std_logic_vector(7 downto 0);
	signal uc1_pb_o				: std_logic_vector(7 downto 0);
	signal uc1_pb_oe_n		: std_logic_vector(7 downto 0);
		
	-- UC3 (VIA6522) signals
	signal uc3_do					: std_logic_vector(7 downto 0);
	signal uc3_do_oe_n		: std_logic;
	signal uc3_cs1				: std_logic;
	signal uc3_cs2_n			: std_logic;
	signal uc3_irq_n			: std_logic;
	signal uc3_ca1_i			: std_logic;
	signal uc3_ca2_o			: std_logic;
	signal uc3_ca2_oe_n		: std_logic;
	signal uc3_pa_i				: std_logic_vector(7 downto 0);
	signal uc3_pa_o				: std_logic_vector(7 downto 0);
	signal uc3_cb2_o			: std_logic;
	signal uc3_cb2_oe_n		: std_logic;
	signal uc3_pa_oe_n		: std_logic_vector(7 downto 0);
	signal uc3_pb_i				: std_logic_vector(7 downto 0);
	signal uc3_pb_o				: std_logic_vector(7 downto 0);
	signal uc3_pb_oe_n		: std_logic_vector(7 downto 0);

	-- internal signals
	signal atna						: std_logic; -- ATN ACK - input gate array
	signal atn						: std_logic; -- attention
	signal soe						: std_logic; -- set overflow enable
	
begin

	reset_n <= not reset;
	
  process (clk_32M, reset)
    variable count  : std_logic_vector(8 downto 0) := (others => '0');
    alias hcnt : std_logic_vector(1 downto 0) is count(4 downto 3);
  begin
    if rising_edge(clk_32M) then
      -- generate 1MHz pulse
      clk_1M_pulse <= '0';
      --if count(4 downto 0) = "00111" then
      if count(4 downto 0) = "01000" then
        clk_1M_pulse <= '1';
      end if;
      count := count + 1;
    end if;
    p2_h <= not hcnt(1);
    clk_4M_en <= not count(2);
  end process;

	-- decode logic
	-- RAM $0000-$07FF (2KB)
	ram_cs <= '1' when STD_MATCH(cpu_a(15 downto 0), "00000-----------") else '0';
	-- UC1 (VIA6522) $1800-$180F
	uc1_cs2_n <= '0' when STD_MATCH(cpu_a(15 downto 0), "000110000000----") else '1';
	-- UC3 (VIA6522) $1C00-$1C0F
	uc3_cs2_n <= '0' when STD_MATCH(cpu_a(15 downto 0), "000111000000----") else '1';
	-- ROM $C000-$FFFF (16KB)
	rom_cs <= '1' when STD_MATCH(cpu_a(15 downto 0), "11--------------") else '0';

	-- qualified write signals
	ram_wr <= '1' when ram_cs = '1' and cpu_rw_n = '0' else '0';

	--
	-- hook up UC1 ports
	--
	
	uc1_cs1 <= cpu_a(11);
	--uc1_cs2_n: see decode logic above
	-- CA1
	uc1_ca1_i <= not sb_atn_in;
	-- PA
	uc1_pa_i(0) <= tr00_sense_n;
	uc1_pa_i(7 downto 1) <= (others => '0');	-- NC
	-- PB
	uc1_pb_i(0) <= 	'1' when sb_data_in = '0' else
									'1' when (uc1_pb_o(1) = '1' and uc1_pb_oe_n(1) = '0') else
									'1' when atn = '1' else
									'0';
	sb_data_oe <= 	'1' when (uc1_pb_o(1) = '1' and uc1_pb_oe_n(1) = '0') else
									'1' when atn = '1' else
									'0';
	uc1_pb_i(2) <= 	'1' when sb_clk_in = '0' else
									'1' when (uc1_pb_o(3) = '1' and uc1_pb_oe_n(3) = '0') else
									'0';
	sb_clk_oe <= 		'1' when (uc1_pb_o(3) = '1' and uc1_pb_oe_n(3) = '0') else '0';
	atna <= uc1_pb_o(4); -- when uc1_pc_oe = '1'
	uc1_pb_i(6 downto 5) <= DEVICE_SELECT xor ds;			-- allows override
	uc1_pb_i(7) <= not sb_atn_in;

	--
	-- hook up UC3 ports
	--
	
	uc3_cs1 <= cpu_a(11);
	--uc3_cs2_n: see decode logic above
	-- CA1
	uc3_ca1_i <= cpu_so_n; -- byte ready gated with soe
	-- CA2
	soe <= uc3_ca2_o; -- when ca2_oe_n = '0'
	-- PA
	uc3_pa_i <= di;
	do <= uc3_pa_o; -- when pa_oe_n = '0'
	-- CB2
	mode <= uc3_cb2_o; -- when cb2_oe_n = '0'
	-- PB
	stp(1) <= uc3_pb_o(0); -- when pb_o_oe(0) = '1'
	stp(0) <= uc3_pb_o(1); -- when pb_o_oe(1) = '1'
	mtr <= uc3_pb_o(2); -- when pb_o_oe(2) = '1'
	act <= uc3_pb_o(3); -- when pb_o_oe(3) = '1'
	freq <= uc3_pb_o(6 downto 5); -- when pb_o_oe(6 downto 5) = '1'
	uc3_pb_i <= sync_n & "11" & wps_n & "1111";
	
	--
	-- CPU connections
	--
	cpu_di <= rom_do when rom_cs = '1' else
						ram_do when ram_cs = '1' else
						uc1_do when (uc1_cs1 = '1' and uc1_cs2_n = '0') else
						uc3_do when (uc3_cs1 = '1' and uc3_cs2_n = '0') else
						(others => '1');
	cpu_irq_n <= uc1_irq_n and uc3_irq_n;
	cpu_so_n <= byte_n or not soe;
	
	-- internal connections
	atn <= atna xor (not sb_atn_in);
	
	-- external connections
	-- ATN never driven by the 1541
	sb_atn_oe <= '0';
			
	cpu_inst : entity work.T65
		port map
		(
			Mode    		=> "00",	-- 6502
			Res_n   		=> reset_n,
			Enable  		=> clk_1M_pulse,
			Clk     		=> clk_32M,
			Rdy     		=> '1',
			Abort_n 		=> '1',
			IRQ_n   		=> cpu_irq_n,
			NMI_n   		=> '1',
			SO_n    		=> cpu_so_n,
			R_W_n   		=> cpu_rw_n,
			Sync    		=> open,
			EF      		=> open,
			MF      		=> open,
			XF      		=> open,
			ML_n    		=> open,
			VP_n    		=> open,
			VDA     		=> open,
			VPA     		=> open,
			A       		=> cpu_a,
			DI      		=> cpu_di,
			DO      		=> cpu_do
		);

	rom_inst : entity work.sprom
		generic map
		(
			init_file		=> PLATFORM_SRC_DIR & "/roms/" & C64_1541_ROM_NAME & ".hex",
			numwords_a	=> 16384,
			widthad_a		=> 14
		)
		port map
		(
			clock			=> clk_32M,
			address		=> cpu_a(13 downto 0),
			q					=> rom_do
		);

	ram_inst : entity work.spram
		generic map
		(
			numwords_a	=> 2048,
			widthad_a		=> 11
		)
		port map
		(
			clock			=> clk_32M,
			address		=> cpu_a(10 downto 0),
			wren			=> ram_wr,
			data			=> cpu_do,
			q					=> ram_do
		);

	uc1_via6522_inst : entity work.M6522
	  port map
		(
	    RS              => cpu_a(3 downto 0),
	    DATA_IN         => cpu_do,
	    DATA_OUT        => uc1_do,
	    DATA_OUT_OE_L   => uc1_do_oe_n,

	    RW_L            => cpu_rw_n,
	    CS1             => uc1_cs1,
	    CS2_L           => uc1_cs2_n,

	   	IRQ_L           => uc1_irq_n,

	    -- port a
	   	CA1_IN          => uc1_ca1_i,
	   	CA2_IN          => '0',
	   	CA2_OUT         => open,
	   	CA2_OUT_OE_L    => open,

	   	PA_IN           => uc1_pa_i,
	   	PA_OUT          => open,
	   	PA_OUT_OE_L     => open,

	    -- port b
	   	CB1_IN          => '0',
	   	CB1_OUT         => open,
	   	CB1_OUT_OE_L    => open,

	   	CB2_IN          => '0',
	   	CB2_OUT         => open,
	   	CB2_OUT_OE_L    => open,

	   	PB_IN           => uc1_pb_i,
	   	PB_OUT          => uc1_pb_o,
	   	PB_OUT_OE_L     => uc1_pb_oe_n,

	   	RESET_L         => reset_n,
	   	P2_H            => p2_h,					-- high for phase 2 clock  ____----__
	   	CLK_4           => clk_4M_en			-- 4x system clock (4HZ)   _-_-_-_-_-
		);

	uc3_via6522_inst : entity work.M6522
	  port map
		(
	    RS              => cpu_a(3 downto 0),
	    DATA_IN         => cpu_do,
	    DATA_OUT        => uc3_do,
	    DATA_OUT_OE_L   => uc3_do_oe_n,

	    RW_L            => cpu_rw_n,
	    CS1             => cpu_a(11),
	    CS2_L           => uc3_cs2_n,

	   	IRQ_L           => uc3_irq_n,

	    -- port a
	   	CA1_IN          => uc3_ca1_i,
	   	CA2_IN          => '0',
	   	CA2_OUT         => uc3_ca2_o,
	   	CA2_OUT_OE_L    => uc3_ca2_oe_n,

	   	PA_IN           => uc3_pa_i,
	   	PA_OUT          => uc3_pa_o,
	   	PA_OUT_OE_L     => uc3_pa_oe_n,

	    -- port b
	   	CB1_IN          => '0',
	   	CB1_OUT         => open,
	   	CB1_OUT_OE_L    => open,

	   	CB2_IN          => '0',
	   	CB2_OUT         => uc3_cb2_o,
	   	CB2_OUT_OE_L    => uc3_cb2_oe_n,

	   	PB_IN           => uc3_pb_i,
	   	PB_OUT          => uc3_pb_o,
	   	PB_OUT_OE_L     => uc3_pb_oe_n,

	   	RESET_L         => reset_n,
	   	P2_H            => p2_h,					-- high for phase 2 clock  ____----__
	   	CLK_4           => clk_4M_en			-- 4x system clock (4HZ)   _-_-_-_-_-
		);

end SYN;
