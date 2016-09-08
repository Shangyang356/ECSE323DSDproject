-- this circuit provides the basic tempo for the music
--
-- entity name: g26_tempo
--
-- Copyright (C) 2015 Chuan Qin, Wei Wang
-- Version 1.0
-- Author:  Chuan Qin; chuan.qin2@mail.mcgill.ca
--			Wei Wang; wei.wang18@mail.mcgill.ca
-- Date: February 25, 2015

library ieee; -- allows use of the std_logic_vector type
use ieee.std_logic_1164.all;

library lpm;
use lpm.lpm_components.all;

entity g26_tempo is
	port(	bpm: in std_logic_vector(7 downto 0);
			clk, reset: in std_logic;
			beat: out std_logic;
			tempo_enable: out std_logic;
			beat_output: out std_logic_vector (4 downto 0));
end g26_tempo;

architecture func of g26_tempo is

signal temp0,temp1 : std_logic_vector (23 downto 0);
signal temp3 : std_logic_vector (4 downto 0);
signal temp2, temp4 : std_logic;
signal bpm_offset : std_logic_vector (11 downto 0);



		
begin
	crc_table : lpm_rom -- use the altera rom library macrocell
	GENERIC MAP(
		lpm_widthad => 8, -- sets the width of the ROM address bus
		lpm_numwords => 256, -- sets the words stored in the ROM
		lpm_outdata => "UNREGISTERED", -- no register on the output
		lpm_address_control => "REGISTERED", -- register on the input
		lpm_file => "g26_tempo_div.mif", -- the ascii file containing the ROM data
		lpm_width => 24 -- the width of the word stored in each ROM location
	)
	PORT MAP(
		inclock => clk,
		address => (bpm),
		q => temp0
	);
	
	U1 : lpm_counter
	GENERIC MAP (
		lpm_direction => "DOWN",
		lpm_port_updown => "PORT_UNUSED",
		lpm_type => "LPM_COUNTER",
		lpm_width => 24
	)
	PORT MAP (
		sload => temp2,
		aclr => not reset,
		clock => clk,
		data => temp0,
		cnt_en => '1',
		q => temp1
	);	
	With temp1 select
	temp2 <=
	'1' when "000000000000000000000000",
	'0' when others;
	
	tempo_enable <= temp2;
	
	U2 : lpm_counter
	GENERIC MAP (
		lpm_direction => "DOWN",
		lpm_port_updown => "PORT_UNUSED",
		lpm_type => "LPM_COUNTER",
		lpm_width => 5
	)
	PORT MAP (
		sload => temp4 and temp2,
		aclr => not reset,
		clock => clk,
		data => "10111",
		cnt_en => temp2,
		q => temp3
	);	
	
	With temp3 select
	temp4 <= 
	'1' when "00000",
	'0' when others;

	beat <= temp3(4);
	beat_output <= temp3;
	
	
	bpm_table : lpm_rom -- use the altera rom library macrocell
	GENERIC MAP(
		lpm_widthad => 8, -- sets the width of the ROM address bus
		lpm_numwords => 256, -- sets the words stored in the ROM
		lpm_outdata => "UNREGISTERED", -- no register on the output
		lpm_address_control => "REGISTERED", -- register on the input
		lpm_file => "g26_bpm_BCD.mif", -- the ascii file containing the ROM data
		lpm_width => 12 -- the width of the word stored in each ROM location
	)
	PORT MAP(
		inclock => clk,
		address => std_logic_vector(bpm),
		q => bpm_offset
	);
	

	
end func;