library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity mc6883 is
	port
	(
		clk			: in std_logic;
		clk_ena : in std_logic;
		reset		: in std_logic;
		
		-- input
		a				: in std_logic_vector(15 downto 0);
		rw_n		: in std_logic;

		-- vdg signals
		da0			: in std_logic;
		hs_n		: in std_logic;
		vclk		: out std_logic;
		
		-- peripheral address selects		
		s				: out std_logic_vector(2 downto 0);
		
		-- dynamic addresses
		z			  : out std_logic_vector(7 downto 0);

		-- ram
		ras0_n 	: out std_logic;
		cas_n		: out std_logic;
		we_n		: out std_logic;
		
		-- clock generation
		q				: out std_logic;
		e				: out std_logic
	);
end mc6883;

architecture SYN of mc6883 is

	subtype DivisorType is integer range 1 to 12;
	type DivisorArrayType is array (natural range <>) of DivisorType;
	-- Division variables for V0=0, V2..V1=sel
	constant y_divisor		: DivisorArrayType(0 to 3) := (12, 3, 2, 1);
	-- Division variable for V0=1, v2..V1=sel
	constant x_divisor		: DivisorArrayType(0 to 3) := (3, 2, 1, 1);
	
  -- clocks
  signal clk_7M15909    : std_logic;
  signal clk_3M579545   : std_logic;
  signal clk_1M769772   : std_logic;
  signal clk_0M894866   : std_logic;
  signal q_int          : std_logic;
  signal e_int          : std_logic;

  -- some rising_edge pulses
  signal rising_edge_hs : std_logic;
  signal rising_edge_q  : std_logic;
  signal rising_edge_e  : std_logic;

  -- internal versions of pin signals
  signal vclk_int       : std_logic;
  signal z_int          : std_logic_vector(7 downto 0);
  signal cas_int        : std_logic;
  signal ras_int        : std_logic_vector(1 downto 0);
  signal we_int         : std_logic;

  -- video counter
  signal b_int          : std_logic_vector(15 downto 0);

	-- control register (CR)
	signal cr				: std_logic_vector(15 downto 0);
	signal sel_cr		: std_logic;
	
	alias ty				: std_logic 										is cr(15);
	alias m 				: std_logic_vector(1 downto 0) 	is cr(14 downto 13);
	alias r					: std_logic_vector(1 downto 0) 	is cr(12 downto 11);
	alias p 				: std_logic 										is cr(10);
	alias f 				: std_logic_vector(6 downto 0) 	is cr(9 downto 3);
	alias v 				: std_logic_vector(2 downto 0) 	is cr(2 downto 0);
	
	alias flag			: std_logic 										is a(0);

	-- internal chipselect vectors
	signal s_ty0		: std_logic_vector(2 downto 0);
	signal s_ty1		: std_logic_vector(2 downto 0);

  signal debug    : std_logic_vector(1 downto 0);

  shared variable yscale   : integer;
		
begin

  -- clock generation, ras/cas generation
  process (clk, reset, rw_n)
    variable count : std_logic_vector(3 downto 0);
  begin
    if reset = '1' then
      count := (others => '0');
      z_int <= (others => '0');
      ras_int <= (others => '1');
      cas_int <= '1';
      we_int <= '1';
    elsif rising_edge (clk) then
      if clk_ena = '1' then
        clk_7M15909 <= count(0);
        clk_3M579545 <= count(1);
        clk_1M769772 <= count(2);
        clk_0M894866 <= count(3);
        vclk_int <= not clk_3M579545;
        case count is
          when "0000" =>
            -- valid VDG address (row)
            -- z(7) is RAS1# or B(7)
            z_int <= b_int(7 downto 0);
            cas_int <= '1';
          when "0001" =>
            ras_int(0) <= '0';
            ras_int(1) <= '0';
          when "0010" =>
          when "0011" =>
            q_int <= '1';
            -- valid VDG address (col)
            case m is
              when "00" =>
                z_int <= "00" & b_int(11 downto 6);
              when "01" =>
                z_int <= '0' & b_int(13 downto 7);
              when others =>
                z_int <= b_int(15 downto 8);
            end case;
            cas_int <= '0';
          when "0100" =>
          when "0101" =>
          when "0110" =>
            ras_int(1) <= '1';
            ras_int(0) <= '1';
          when "0111" =>
            e_int <= '1';
            we_int <= rw_n;
          when "1000" =>
            -- valid MPU address (row)
            -- z(7) is RAS1# or A(7)
            z_int <= a(7 downto 0);
            cas_int <= '1';
          when "1001" =>
            ras_int(1) <= '0';
            ras_int(0) <= '0';
          when "1010" =>
          when "1011" =>
            q_int <= '0';
            -- valid MPU address (col)
            case m is
              when "00" =>
                z_int <= "00" & a(11 downto 6);
              when "01" =>
                -- z(7) is P or don't care
                z_int <= p & a(13 downto 7);
              when others =>
                if ty = '0' then
                  z_int <= p & a(14 downto 8);
                else
                  z_int <= a(15 downto 8);
                end if;
            end case;
            cas_int <= '0';
          when "1100" =>
          when "1101" =>
          when "1110" =>
            ras_int(0) <= '1';
            ras_int(1) <= '1';
          when others =>
            e_int <= '0';
            we_int <= '1';
        end case;
        count := count + 1;
     end if; -- clk_ena
    end if;
  end process;

  -- assign clock outputs
  q <= q_int;
  e <= e_int;
  vclk <= vclk_int;

  -- rising edge pulses
  process (clk, reset)
    variable old_hs : std_logic;
    variable old_q  : std_logic;
    variable old_e  : std_logic;
  begin
    if reset = '1' then
      old_hs := '0';
      rising_edge_hs <= '0';
      old_q := '0';
      rising_edge_q <= '0';
      old_e := '0';
      rising_edge_e <= '0';
    elsif rising_edge (clk) then
      if clk_ena = '1' then
        rising_edge_hs <= '0';
        if old_hs = '0' and hs_n = '1' then
          rising_edge_hs <= '1';
        end if;
        old_hs := hs_n;
        rising_edge_q <= '0';
        if old_q = '0' and q_int = '1' then
          rising_edge_q <= '1';
        end if;
        old_q := q_int;
        rising_edge_e <= '0';
        if old_e = '0' and e_int = '1' then
          rising_edge_e <= '1';
        end if;
        old_e := e_int;
     end if; -- clk_ena
    end if;
  end process;

  -- video address generation
  -- normally, da0 clocks the internal counter
  -- but we want a synchronous design
  -- so sample da0 each internal clock
  process (clk, reset, da0, hs_n)
    variable old_hs   : std_logic;
    variable old_da0  : std_logic;
    --variable yscale   : integer;
    variable saved_b : std_logic_vector(15 downto 0);
  begin
    if reset = '1' then
      b_int <= (others => '0');
      old_hs := '1';
      old_da0 := '1';
      yscale := 0;
      saved_b := (others => '0');
    elsif rising_edge (clk) then
      if clk_ena = '1' then
        -- vertical blanking - HS rises when DA0 is high
        -- resets bits B9-15, clear B1-B8
        if rising_edge_hs = '1' and da0 = '1' then
          b_int(15 downto 9) <= f(6 downto 0);
          b_int(8 downto 0) <= (others => '0');
          yscale := y_divisor(conv_integer(v(2 downto 1)));
          saved_b := f(6 downto 0) & "000000000";
        -- horizontal blanking - HS low
        -- resets bits B1-B3/4
        elsif hs_n = '0' then
          if v(0) = '0' then
            b_int(4) <= '0';
          end if;
          b_int(3 downto 1) <= (others => '0');
          -- coming out of HS?
          if old_hs = '1' then
            if yscale = y_divisor(conv_integer(v(2 downto 1))) then
              yscale := 0;
              saved_b := b_int;
            else
              yscale := yscale + 1;
              b_int <= saved_b;
            end if;
          end if;
        -- transition on da is the video clock
        elsif da0 /= old_da0 then
          b_int <= b_int + 1;
        end if;
        old_hs := hs_n;
        old_da0 := da0;
        debug <= old_hs & old_da0;
      end if; -- clk_ena
    end if;
  end process;

	-- select control register (CR)
	sel_cr <= '1' when a(15 downto 5) = "11111111110" else '0';
	
	--
	--	Memory decode logic
	--	- combinatorial - needs to be gated
	--
	s_ty0 <= 	"010" when 	-- $FFF2-$FFFF (6809 vectors)
												-- $FFE0-$FFF1 (reserved)
												a(15 downto 5) = "11111111111"
									else
						"111" when	-- $FFC0-$FFDF (SAM control register)
												-- $FF60-$FFBF (reserved)
												sel_cr = '1' or 
												(a(15 downto 8) = "11111111" and (a(7) = '1' or a(6 downto 5) = "11"))
									else
						"110" when	-- $FF40-$FF5F (IO2)
												a(15 downto 5) = "11111111010"
									else
						"101" when	-- $FF20-$FF3F (IO1)
												a(15 downto 5) = "11111111001"
									else
						"100" when	-- $FF00-$FF1F (IO0)
												a(15 downto 5) = "11111111000"
									else
						"011" when	-- $C000-$FEFF (rom2)
												a(15 downto 14) = "11"
									else
						"010" when	-- $A000-$BFFF (rom1)
												a(15 downto 13) = "101"
									else
						"001" when	-- $8000-$9FFF (rom0)
												a(15 downto 13) = "100"
									else
						"000"	when	-- $0000-$7FFF (32K) RW_N=1
												a(15) = '0' and rw_n = '1'
									else
						"111" when	-- $0000-$7FFF (32K) RW_N=0
												a(15) = '0' and rw_n = '0';

	-- fudge for now
	s_ty1 <= s_ty0;
	
	s <= 	s_ty0 when ty = '0' else
				s_ty1;
				
	--
	--	Handle update of the control register (CR)
	--
	WRITE_CR : process (clk, reset, a, rw_n)
	begin
		if reset = '1' then
			cr <= (others => '0');
		elsif falling_edge (clk) then
      if clk_ena = '1' then
        if rising_edge_e = '1' and sel_cr = '1' and rw_n = '0' then
          case a(4 downto 1) is
            when "0000" =>
              v(0) <= flag;
            when "0001" =>
              v(1) <= flag;
            when "0010" =>
              v(2) <= flag;
            when "0011" =>
              f(0) <= flag;
            when "0100" =>
              f(1) <= flag;
            when "0101" =>
              f(2) <= flag;
            when "0110" =>
              f(3) <= flag;
            when "0111" =>
              f(4) <= flag;
            when "1000" =>
              f(5) <= flag;
            when "1001" =>
              f(6) <= flag;
            when "1010" =>
              p <= flag;
            when "1011" =>
              r(0) <= flag;
            when "1100" =>
              r(1) <= flag;
            when "1101" =>
              m(0) <= flag;
            when "1110" =>
              m(1) <= flag;
            when others =>    -- "1111"
              ty <= flag;
          end case;
        end if;
			end if; -- clk_ena
		end if;
	end process WRITE_CR;

  -- assign outputs
  z <= z_int;
  ras0_n <= ras_int(0);
  cas_n <= cas_int;
  we_n <= we_int;
		
end SYN;

