library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;
use work.kbd_pkg.all;

entity inputmapper is
	generic
	(
			NUM_INPUTS : positive := 2
	);
	port
	(
	    clk       : in std_logic;
	    rst_n     : in std_logic;

	    -- inputs from keyboard controller
	    reset     : in std_logic;
	    press     : in std_logic;
	    release   : in std_logic;
	    data      : in std_logic_vector(7 downto 0);
			-- inputs from jamma interface
			jamma			: in JAMMAInputsType;

	    -- user outputs
	    dips			: in std_logic_vector(7 downto 0);
	    inputs		: out in8(0 to NUM_INPUTS-1)
	);
end inputmapper;

architecture SYN of inputmapper is

begin

    latchInputs: process (clk, rst_n)
			variable jamma_v : in8(0 to NUM_INPUTS-1);
			variable keybd_v : in8(0 to NUM_INPUTS-1);
    begin
         -- note: all inputs are active LOW
        if rst_n = '0' then
					for i in 0 to NUM_INPUTS-2 loop
						jamma_v(i) := (others =>'1');
						keybd_v(i) := (others =>'1');
					end loop;
          -- special keys (active high)
          jamma_v(NUM_INPUTS-1) := (others => '1');	-- because we AND jamma,keybd
          keybd_v(NUM_INPUTS-1) := (others => '0');
        elsif rising_edge (clk) then

					-- handle JAMMA inputs
					jamma_v(0)(0) := jamma.p(1).button(1);
					jamma_v(0)(1) := jamma.p(1).button(2);
					jamma_v(1)(4) := jamma.service;
					jamma_v(1)(6) := jamma.p(2).start;
					jamma_v(1)(7) := jamma.p(1).start;

          -- handle PS2 inputs
          if (press or release) = '1' then
          	case data(7 downto 0) is
            	-- low byte
              when SCANCODE_LCTRL =>		-- button 1
              	keybd_v(0)(0) := release;
              when SCANCODE_LALT =>			-- button 2
                keybd_v(0)(1) := release;
              -- high byte
              when SCANCODE_9 =>				-- service 1
                keybd_v(1)(4) := release;
              when SCANCODE_2 =>				-- start2
                keybd_v(1)(6) := release;
              when SCANCODE_1 =>				-- start1
                keybd_v(1)(7) := release;
							-- special keys
							when SCANCODE_F3 =>				-- game reset
								keybd_v(NUM_INPUTS-1)(0) := press;
              when others =>
            end case;
          end if; -- press or release
          if (reset = '1') then
						for i in 0 to NUM_INPUTS-2 loop
							keybd_v(i) := (others =>'1');
						end loop;
            -- special keys (active high)
            keybd_v(NUM_INPUTS-1) := (others => '0');
          end if;
        end if; -- rising_edge (clk)

				-- assign outputs
				for i in 0 to NUM_INPUTS-1 loop
					inputs(i) <= keybd_v(i) and jamma_v(i);
				end loop;
				
    end process latchInputs;

end SYN;


