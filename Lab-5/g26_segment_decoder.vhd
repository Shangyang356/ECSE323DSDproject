-- this circuit generates the appropriate 7-segment display.
--
-- entity name: g26_segment_decoder
--
-- Copyright (C) 2015 Chuan Qin, Wei Wang
-- Version 1.1
-- Author: 	Chuan Qin; chuan.qin2@mail.mcgill.ca
--			Wei Wang; wei.wang18@mail.mcgill.ca
-- Date: February 11, 2015

library ieee; -- allows use of the std_logic_vector type
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity g26_segment_decoder is
port(	code			: in std_logic_vector(3 downto 0);
		RippleBlank_In	: in std_logic;
		segments 		: out std_logic_vector(6 downto 0));
end g26_segment_decoder;

architecture func of g26_segment_decoder is
	Signal temp: std_logic_vector(7 downto 0);
begin
	
	with (RippleBlank_In & code) select (temp) <=
	--when the ripple in is equal to 0
	"01000000" when "00000", -- 0
	"01111001" when "00001", -- 1
	"00100100" when "00010", -- 2
	"00110000" when "00011", -- 3
	"00011001" when "00100", -- 4
	"00010010" when "00101", -- 5
	"00000010" when "00110", -- 6
	"01111000" when "00111", -- 7
	"00000000" when "01000", -- 8
	"00010000" when "01001", -- 9
	"00001000" when "01010", -- A
	"00000011" when "01011", -- b
	"00100111" when "01100", -- c
	"00100001" when "01101", -- d
	"00000110" when "01110", -- E
	"00001110" when "01111", -- F
	
	--when ripple in is equal to 1
	"11111111" when "10000", -- 0
	"01111001" when "10001", -- 1
	"00100100" when "10010", -- 2
	"00110000" when "10011", -- 3
	"00011001" when "10100", -- 4
	"00010010" when "10101", -- 5
	"00000010" when "10110", -- 6
	"01111000" when "10111", -- 7
	"00000000" when "11000", -- 8
	"00010000" when "11001", -- 9 
	"00001000" when "11010", -- A
	"00000011" when "11011", -- b
	"00100111" when "11100", -- c
	"00100001" when "11101", -- d
	"00000110" when "11110", -- E
	"00001110" when "11111", -- F
	"11111111" when others; -- OFF
	segments <= temp(6 downto 0);

end func;