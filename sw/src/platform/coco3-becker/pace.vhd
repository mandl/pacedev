Library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;
use work.sprite_pkg.all;
use work.platform_pkg.all;
use work.target_pkg.all;
use work.project_pkg.all;

entity PACE is
  port
  (
  	-- clocks and resets
    clk_i           : in std_logic_vector(0 to 3);
    reset_i         : in std_logic;

    -- misc I/O
    buttons_i       : in from_BUTTONS_t;
    switches_i      : in from_SWITCHES_t;
    leds_o          : out to_LEDS_t;

    -- controller inputs
    inputs_i        : in from_INPUTS_t;

    -- external ROM/RAM
    flash_i         : in from_FLASH_t;
    flash_o         : out to_flash_t;
    sram_i       		: in from_SRAM_t;
		sram_o					: out to_SRAM_t;
    sdram_i         : in from_SDRAM_t;
    sdram_o         : out to_SDRAM_t;

    -- video
    video_i         : in from_VIDEO_t;
    video_o         : out to_VIDEO_t;

    -- audio
    audio_i         : in from_AUDIO_t;
    audio_o         : out to_AUDIO_t;
    
    -- SPI (flash)
    spi_i           : in from_SPI_t;
    spi_o           : out to_SPI_t;

    -- serial
    ser_i           : in from_SERIAL_t;
    ser_o           : out to_SERIAL_t;
    
    -- general purpose I/O
    gp_i            : in from_GP_t;
    gp_o            : out to_GP_t
  );

end PACE;

architecture SYN of PACE is

	component coco3fpga is
		port
		(
			CLK50MHZ			: in std_logic;
			
			-- RAM, ROM, and Peripherials
			RAM_DATA0_I		: in std_logic_vector(15 downto 0);			-- 16 bit data bus from RAM 0
			RAM_DATA0_O		: out std_logic_vector(15 downto 0);		-- 16 bit data bus to RAM 0
			RAM_DATA1_I	  : in std_logic_vector(15 downto 0);	    -- 16 bit data bus from RAM 1
			RAM_DATA1_O		: out std_logic_vector(15 downto 0);	  -- 16 bit data bus to RAM 1
			RAM_ADDRESS		: out std_logic_vector(18 downto 0);		-- Common address
			RAM_RW_N			: out std_logic;												-- Common RW
			RAM0_CS_N			: out std_logic;												-- Chip Select for RAM 0
			RAM1_CS_N			: out std_logic;												-- Chip Select for RAM 1
			RAM0_BE0_N		: out std_logic;												-- Byte Enable for RAM 0
			RAM0_BE1_N		: out std_logic;												-- Byte Enable for RAM 0
			RAM1_BE0_N		: out std_logic;												-- Byte Enable for RAM 1
			RAM1_BE1_N		: out std_logic;												-- Byte Enable for RAM 1
			RAM_OE_N			: out std_logic;
			
			-- VGA
			RED1					: out std_logic;
			GREEN1				: out std_logic;
			BLUE1					: out std_logic;
			RED0					: out std_logic;
			GREEN0				: out std_logic;
			BLUE0					: out std_logic;
			H_SYNC				: out std_logic;
			V_SYNC				: out std_logic;
			
			-- PS/2
			ps2_clk				: in std_logic;
			ps2_data			: in std_logic;
			
			--Serial Ports
			TXD1					: out std_logic;
			RXD1					: in std_logic;
			TXD2					: out std_logic;
			RXD2					: in std_logic;
			TXD3					: out std_logic;
			RXD3					: in std_logic;
      RTS3          : out std_logic;
      CTS3          : in std_logic;
			
			-- Display
			DIGIT_N				: out std_logic_vector(3 downto 0);
			SEGMENT_N			: out std_logic_vector(7 downto 0);
			
			-- LEDs
			LED						: out std_logic_vector(7 downto 0);
			
			-- CoCo Perpherial
			SPEAKER				: out std_logic_vector(1 downto 0);
			PADDLE				: in std_logic_vector(3 downto 0);
			PADDLE_RST    : out std_logic_vector(3 downto 0);
			P_SWITCH			: in std_logic_vector(3 downto 0);
			
			-- Extra Buttons and Switches
			SWITCH				: in std_logic_vector(7 downto 0);
			BUTTON				: in std_logic_vector(3 downto 0)
		);
	end component;

	alias clk_50M 		  : std_logic is clk_i(0);
	
  signal ram_address  : std_logic_vector(18 downto 0);
	signal ram1_di		  : std_logic_vector(15 downto 0);
	signal ram1_do		  : std_logic_vector(15 downto 0);
	signal ram0_di		  : std_logic_vector(15 downto 0);
	signal ram0_do		  : std_logic_vector(15 downto 0);
	signal ram_rw_n		  : std_logic;
	signal ram0_cs_n	  : std_logic;
	signal ram1_cs_n	  : std_logic;
	signal ram0_be_n	  : std_logic_vector(1 downto 0);
	signal ram1_be_n	  : std_logic_vector(1 downto 0);
	signal ram_oe_n		  : std_logic;

begin

	--GEN_RMW_SRAM : if PACE_TARGET = PACE_TARGET_P2 generate
	GEN_RMW_SRAM : if false generate
	
		BLK_SRAM : block

			signal rmw_a    : std_logic_vector(ram_address'range);
	    signal rmw_oe   : std_logic;
	    signal rmw_we   : std_logic;

			constant DELAY	: time := 2 ns;

			type state_t 		is (IDLE, READ, WRITE1, WRITE2);
			signal state		: state_t;
			
		begin

			process (clk_50M, reset_i)
				variable rmw_di			: std_logic_vector(15 downto 0);
				variable rmw_do			: std_logic_vector(15 downto 0);
				variable rmw_be			: std_logic_vector(ram0_be_n'range);
			begin
				if reset_i = '1' then
					state <= IDLE after DELAY;
				elsif rising_edge(clk_50M) then
					case state is
						when IDLE =>
							if ram0_cs_n = '0' and ram_rw_n = '0' then
								-- start read-write-modify cycle
								rmw_a <= ram_address;
								rmw_do := ram0_do;
								rmw_be := not ram0_be_n;
								rmw_oe <= '1' after DELAY;
								rmw_we <= '0' after DELAY;
								state <= READ after DELAY;
							end if;
							
						when READ =>
							-- wait 20ns
							state <= WRITE1 after DELAY;

						when WRITE1 =>
							-- OR-in the value and write back
							rmw_di := sram_i.d(15 downto 0);
							if rmw_be(1) = '1' then
								sram_o.d(15 downto 8) <= rmw_do(15 downto 8) after DELAY;
							else
								sram_o.d(15 downto 8) <= rmw_di(15 downto 8) after DELAY;
							end if;
							if rmw_be(0) = '1' then
								sram_o.d(7 downto 0) <= rmw_do(7 downto 0) after DELAY;
							else
								sram_o.d(7 downto 0) <= rmw_di(7 downto 0) after DELAY;
							end if;
							rmw_oe <= '0' after DELAY;
							rmw_we <= '1' after DELAY;
							state <= WRITE2 after DELAY;
							
						when WRITE2 =>
							state <= IDLE after DELAY;
							
						when others =>
							state <= IDLE after DELAY;
					end case;
				end if;
			end process;

			sram_o.a <= std_logic_vector(resize(unsigned(ram_address), sram_o.a'length)) when state = IDLE else
									std_logic_vector(resize(unsigned(rmw_a), sram_o.a'length));
			sram_o.d(31 downto 16) <= (others => '0');
			ram0_di <= sram_i.d(ram0_di'range);
			--sram_o.be <=  std_logic_vector(resize(unsigned("11"), sram_o.be'length));
			sram_o.cs <= not ram0_cs_n when state = IDLE else '1';
			sram_o.oe <= not ram_oe_n when state = IDLE else rmw_oe;
			sram_o.we <= '0' when state = IDLE else rmw_we;
			
		end block BLK_SRAM;

	end generate GEN_RMW_SRAM;

	GEN_EXPERIMENTAL : if PACE_TARGET = PACE_TARGET_P2 generate
	
		sram_o.a <= std_logic_vector(resize(unsigned(ram_address), sram_o.a'length));
		sram_o.d <= std_logic_vector(resize(unsigned(ram0_do), sram_o.d'length));
		ram0_di <= sram_i.d(7 downto 0) & sram_i.d(7 downto 0);
		sram_o.be <= std_logic_vector(resize(unsigned(not ram0_be_n), sram_o.be'length));
		sram_o.cs <= not ram0_cs_n;
		sram_o.oe <= not ram_oe_n;
		sram_o.we <= not ram_rw_n;
	
	end generate GEN_EXPERIMENTAL;
		
	GEN_SRAM_DE2 : if PACE_TARGET = PACE_TARGET_DE2 generate

		sram_o.a <= std_logic_vector(resize(unsigned(ram_address), sram_o.a'length));
		sram_o.d <= ram1_do & ram0_do;
		ram1_di <= sram_i.d(31 downto 16);
		ram0_di <= sram_i.d(15 downto 0);
		sram_o.be <= not (ram1_be_n & ram0_be_n);
		sram_o.cs <= ram1_cs_n nand ram0_cs_n;
		sram_o.oe <= not ram_oe_n;
		sram_o.we <= not ram_rw_n;
	
	end generate GEN_SRAM_DE2;
	
	GEN_SRAM_P2A : if PACE_TARGET = PACE_TARGET_P2A generate

    -- this is for 32-bit wide memory
		--sram_o.a <= std_logic_vector(resize(unsigned(ram_address), sram_o.a'length));
		--sram_o.d <= ram1_do & ram0_do;
		--ram1_di <= sram_i.d(31 downto 16);
		--ram0_di <= sram_i.d(15 downto 0);
		--sram_o.be <= ((ram1_cs_n & ram1_cs_n) nor ram1_be_n) & ((ram0_cs_n & ram0_cs_n) nor ram0_be_n);
		--sram_o.cs <= ram1_cs_n nand ram0_cs_n;
		--sram_o.oe <= not ram_oe_n;
		--sram_o.we <= not ram_rw_n;

    -- this is for 16-bit wide memory
		sram_o.a <= std_logic_vector(resize(unsigned(ram_address), sram_o.a'length));
		sram_o.d(31 downto 16) <= (others => '0');
		sram_o.d(15 downto 0) <= ram1_do when ram1_cs_n = '0' else ram0_do;
		ram1_di <= sram_i.d(15 downto 0);
		ram0_di <= sram_i.d(15 downto 0);
		sram_o.be <= "00" & (ram1_be_n(1) nand ram0_be_n(1)) & (ram1_be_n(1) nand ram0_be_n(1));
		sram_o.cs <= ram1_cs_n nand ram0_cs_n;
		sram_o.oe <= not ram_oe_n;
		sram_o.we <= not ram_rw_n;
	
	end generate GEN_SRAM_P2A;
	
	GEN_SRAM_2 : if PACE_TARGET = PACE_TARGET_DE1 generate

    -- hook up Burched SRAM module
    GEN_D: for i in 0 to 7 generate
      ram1_di(8+i) <= gp_i(35-i);
      ram1_di(i) <= gp_i(35-i);
      gp_o.d(35-i) <= ram1_do(i);
      gp_o.d(27-i) <= 'Z';
    end generate;
    GEN_A: for i in 0 to 16 generate
      gp_o.d(17-i) <= ram_address(i);
    end generate;
    gp_o.d(0) <= ram1_cs_n;                   -- CEAn
    gp_o.d(18) <= '1';                        -- upper byte WEn
    gp_o.d(19) <= ram_rw_n or ram1_be_n(0);   -- lower byte WEn

		sram_o.a <= std_logic_vector(resize(unsigned(ram_address), sram_o.a'length));
		sram_o.d <= ram1_do & ram0_do;
		ram0_di <= sram_i.d(15 downto 0);
		sram_o.be <= "00" & not ram0_be_n;
		sram_o.cs <= not ram0_cs_n;
		sram_o.oe <= not ram_oe_n;
		sram_o.we <= not ram_rw_n;
	
	end generate GEN_SRAM_2;
	
	GEN_SRAM_COCO3PLUS : if PACE_TARGET = PACE_TARGET_COCO3PLUS generate

		sram_o.a <= std_logic_vector(resize(unsigned(ram_address), sram_o.a'length));
		sram_o.d <= ram1_do & ram0_do;
		ram1_di <= sram_i.d(31 downto 16);
		ram0_di <= sram_i.d(15 downto 0);
		sram_o.be <= ((ram1_cs_n & ram1_cs_n) nor ram1_be_n) & ((ram0_cs_n & ram0_cs_n) nor ram0_be_n);
		sram_o.cs <= ram1_cs_n nand ram0_cs_n;
		sram_o.oe <= not ram_oe_n;
		sram_o.we <= not ram_rw_n;
	
	end generate GEN_SRAM_COCO3PLUS;
	
	coco_inst : coco3fpga
		port map
		(
			CLK50MHZ			=> clk_50M,
			
			-- RAM, ROM, and Peripherials
			RAM_DATA0_I		=> ram0_di,
			RAM_DATA0_O		=> ram0_do,
			RAM_DATA1_I	  => ram1_di,
      RAM_DATA1_O   => ram1_do,
			RAM_ADDRESS		=> ram_address,
			RAM_RW_N			=> ram_rw_n,
			RAM0_CS_N			=> ram0_cs_n,
			RAM1_CS_N			=> ram1_cs_n,
			RAM0_BE0_N		=> ram0_be_n(0),
			RAM0_BE1_N		=> ram0_be_n(1),
			RAM1_BE0_N		=> ram1_be_n(0),
			RAM1_BE1_N		=> ram1_be_n(1),
			RAM_OE_N			=> ram_oe_n,
			
			-- VGA
			RED1					=> video_o.rgb.r(9),
			GREEN1				=> video_o.rgb.g(9),
			BLUE1					=> video_o.rgb.b(9),
			RED0					=> video_o.rgb.r(8),
			GREEN0				=> video_o.rgb.g(8),
			BLUE0					=> video_o.rgb.b(8),
			H_SYNC				=> video_o.hsync,
			V_SYNC				=> video_o.vsync,
			
			-- PS/2
			ps2_clk				=> inputs_i.ps2_kclk,
			ps2_data			=> inputs_i.ps2_kdat,
			
			--Serial Ports
			TXD1					=> ser_o.txd,
			RXD1					=> ser_i.rxd,
			TXD2					=> open,
			RXD2					=> '0',
			TXD3					=> open,
			RXD3					=> '0',
      RTS3          => open,
      CTS3          => '0',
      
			-- Display
			DIGIT_N				=> open,
			SEGMENT_N			=> open,
			
			-- LEDs
			LED						=> leds_o(7 downto 0),
			
			-- CoCo Perpherial
			SPEAKER				=> open,
			PADDLE				=> (others => '0'),
			PADDLE_RST    => open,
			P_SWITCH			=> (others => '1'),
			
			-- Extra Buttons and Switches
			SWITCH				=> (others => '0'), -- fast=1.78MHz
			BUTTON(3)			=> reset_i,
			BUTTON(2 downto 0) => "000"
		);

	video_o.clk <= clk_50M;

	-- unused
	video_o.rgb.r(7 downto 0) <= (others => '0');
	video_o.rgb.g(7 downto 0) <= (others => '0');
	video_o.rgb.b(7 downto 0) <= (others => '0');

  spi_o <= NULL_TO_SPI;
  
end SYN;

