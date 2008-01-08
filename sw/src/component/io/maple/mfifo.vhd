-- megafunction wizard: %FIFO%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: scfifo 

-- ============================================================
-- File Name: mfifo.vhd
-- Megafunction Name(s):
-- 			scfifo
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 6.0 Build 202 06/20/2006 SP 1 SJ Full Version
-- ************************************************************


--Copyright (C) 1991-2006 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.all;

ENTITY mfifo IS
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END mfifo;


ARCHITECTURE SYN OF mfifo IS

	SIGNAL sub_wire0	: STD_LOGIC ;
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL sub_wire2	: STD_LOGIC ;



	COMPONENT scfifo
	GENERIC (
		add_ram_output_register		: STRING;
		intended_device_family		: STRING;
		lpm_numwords		: NATURAL;
		lpm_showahead		: STRING;
		lpm_type		: STRING;
		lpm_width		: NATURAL;
		lpm_widthu		: NATURAL;
		overflow_checking		: STRING;
		underflow_checking		: STRING;
		use_eab		: STRING
	);
	PORT (
			rdreq	: IN STD_LOGIC ;
			empty	: OUT STD_LOGIC ;
			aclr	: IN STD_LOGIC ;
			clock	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			wrreq	: IN STD_LOGIC ;
			data	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			full	: OUT STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	empty    <= sub_wire0;
	q    <= sub_wire1(7 DOWNTO 0);
	full    <= sub_wire2;

	scfifo_component : scfifo
	GENERIC MAP (
		add_ram_output_register => "OFF",
		intended_device_family => "Cyclone II",
		lpm_numwords => 256,
		lpm_showahead => "ON",
		lpm_type => "scfifo",
		lpm_width => 8,
		lpm_widthu => 8,
		overflow_checking => "ON",
		underflow_checking => "ON",
		use_eab => "ON"
	)
	PORT MAP (
		rdreq => rdreq,
		aclr => aclr,
		clock => clock,
		wrreq => wrreq,
		data => data,
		empty => sub_wire0,
		q => sub_wire1,
		full => sub_wire2
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: AlmostEmpty NUMERIC "0"
-- Retrieval info: PRIVATE: AlmostEmptyThr NUMERIC "-1"
-- Retrieval info: PRIVATE: AlmostFull NUMERIC "0"
-- Retrieval info: PRIVATE: AlmostFullThr NUMERIC "-1"
-- Retrieval info: PRIVATE: CLOCKS_ARE_SYNCHRONIZED NUMERIC "1"
-- Retrieval info: PRIVATE: Clock NUMERIC "0"
-- Retrieval info: PRIVATE: Depth NUMERIC "256"
-- Retrieval info: PRIVATE: Empty NUMERIC "1"
-- Retrieval info: PRIVATE: Full NUMERIC "1"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone II"
-- Retrieval info: PRIVATE: LE_BasedFIFO NUMERIC "0"
-- Retrieval info: PRIVATE: LegacyRREQ NUMERIC "0"
-- Retrieval info: PRIVATE: MAX_DEPTH_BY_9 NUMERIC "0"
-- Retrieval info: PRIVATE: OVERFLOW_CHECKING NUMERIC "0"
-- Retrieval info: PRIVATE: Optimize NUMERIC "2"
-- Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
-- Retrieval info: PRIVATE: UNDERFLOW_CHECKING NUMERIC "0"
-- Retrieval info: PRIVATE: UsedW NUMERIC "0"
-- Retrieval info: PRIVATE: Width NUMERIC "8"
-- Retrieval info: PRIVATE: dc_aclr NUMERIC "0"
-- Retrieval info: PRIVATE: rsEmpty NUMERIC "1"
-- Retrieval info: PRIVATE: rsFull NUMERIC "0"
-- Retrieval info: PRIVATE: rsUsedW NUMERIC "0"
-- Retrieval info: PRIVATE: sc_aclr NUMERIC "1"
-- Retrieval info: PRIVATE: sc_sclr NUMERIC "0"
-- Retrieval info: PRIVATE: wsEmpty NUMERIC "0"
-- Retrieval info: PRIVATE: wsFull NUMERIC "1"
-- Retrieval info: PRIVATE: wsUsedW NUMERIC "0"
-- Retrieval info: CONSTANT: ADD_RAM_OUTPUT_REGISTER STRING "OFF"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone II"
-- Retrieval info: CONSTANT: LPM_NUMWORDS NUMERIC "256"
-- Retrieval info: CONSTANT: LPM_SHOWAHEAD STRING "ON"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "scfifo"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "8"
-- Retrieval info: CONSTANT: LPM_WIDTHU NUMERIC "8"
-- Retrieval info: CONSTANT: OVERFLOW_CHECKING STRING "ON"
-- Retrieval info: CONSTANT: UNDERFLOW_CHECKING STRING "ON"
-- Retrieval info: CONSTANT: USE_EAB STRING "ON"
-- Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT NODEFVAL aclr
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
-- Retrieval info: USED_PORT: empty 0 0 0 0 OUTPUT NODEFVAL empty
-- Retrieval info: USED_PORT: full 0 0 0 0 OUTPUT NODEFVAL full
-- Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
-- Retrieval info: USED_PORT: rdreq 0 0 0 0 INPUT NODEFVAL rdreq
-- Retrieval info: USED_PORT: wrreq 0 0 0 0 INPUT NODEFVAL wrreq
-- Retrieval info: CONNECT: @data 0 0 8 0 data 0 0 8 0
-- Retrieval info: CONNECT: q 0 0 8 0 @q 0 0 8 0
-- Retrieval info: CONNECT: @wrreq 0 0 0 0 wrreq 0 0 0 0
-- Retrieval info: CONNECT: @rdreq 0 0 0 0 rdreq 0 0 0 0
-- Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: full 0 0 0 0 @full 0 0 0 0
-- Retrieval info: CONNECT: empty 0 0 0 0 @empty 0 0 0 0
-- Retrieval info: CONNECT: @aclr 0 0 0 0 aclr 0 0 0 0
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: GEN_FILE: TYPE_NORMAL mfifo.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL mfifo.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL mfifo.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL mfifo.bsf TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL mfifo_inst.vhd FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL mfifo_waveforms.html FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL mfifo_wave*.jpg FALSE
