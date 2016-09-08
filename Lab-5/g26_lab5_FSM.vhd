-- this circuit is the main file of the lab5 project. It includes a finite state machine and use components to connect 
-- all the needed designs from previous labs. 
-- entity name: g26_lab5_FSM
--
-- Copyright (C) 2015 Chuan Qin, Wei Wang
-- Version 1.0
-- Author:  Chuan Qin; chuan.qin2@mail.mcgill.ca
--			Wei Wang; wei.wang18@mail.mcgill.ca
-- Date: April 4, 2015

library ieee; -- allows use of the std_logic_vector type
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library lpm;
use lpm.lpm_components.all;

entity g26_lab5_FSM is

GENERIC (
		FLASH_MEMORY_ADDRESS_WIDTH 	: INTEGER := 22;
		FLASH_MEMORY_DATA_WIDTH 	: INTEGER := 8
);

port ( 
	clk, 
	reset,
	pause,
	start,
	stop,
	songnumber,
	shiftoctave,
	whetherloop               	: in std_logic;
	BPM							: in std_LOGIC_VECTOR(5 downto 0);
	
	triggerforled				: out std_logic;
	
	--segmentsofnotenumber        : out std_logic_vector(6 downto 0);
	--segmentsofoctave            : out std_logic_vector(6 downto 0);
	--segmentsofnoteduration      : out std_logic_vector(6 downto 0);
	--segmentsofvolume            : out std_logic_vector(6 downto 0);
	
	i_data 						: IN STD_LOGIC_VECTOR(FLASH_MEMORY_DATA_WIDTH - 1 DOWNTO 0);
	FL_ADDR 					: OUT 	STD_LOGIC_VECTOR(FLASH_MEMORY_ADDRESS_WIDTH - 1 DOWNTO 0);
	FL_DQ 						: INOUT 	STD_LOGIC_VECTOR(FLASH_MEMORY_DATA_WIDTH - 1 DOWNTO 0);
	FL_CE_N,	
	FL_OE_N,
	FL_WE_N,
	FL_RST_N 					: OUT STD_LOGIC;
	INIT 						: IN  std_logic;
	AUD_MCLK 					: OUT std_logic; -- codec master clock input
	AUD_BCLK 					: OUT std_logic; -- digital audio bit clock
	AUD_DACDAT 					: OUT std_logic; -- DAC data lines
	AUD_DACLRCK 				: OUT std_logic; -- DAC data left/right select
	I2C_SDAT 					: OUT std_logic; -- serial interface data line
	I2C_SCLK 					: OUT std_logic  -- serial interface clock)
	

);
end g26_lab5_FSM;

architecture arc of g26_lab5_FSM is 

signal addresscounter 			: integer range 0 to 255;
signal tempofsongrom  			: std_logic_vector(15 downto 0);
signal tempofsongrom1			: std_logic_vector(15 downto 0);
signal tempofsongrom2 			: std_logic_vector(15 downto 0);
signal tempofnote_duration 	    : std_logic_vector(2 downto 0);
signal tempoftriplet  			: std_logic;
signal tempoftrigger        	: std_logic;
signal tempoftrigger2        	: std_logic;
signal tempofnotenumber    	    : std_logic_vector(3 downto 0);
signal tempofoctave   			: std_logic_vector(2 downto 0);
signal tempofsongend 			: std_logic;
signal tempofloudness 			: std_logic_vector(3 downto 0);
signal whetherstop 			    : std_logic;
signal whetherpause				: std_logic;
signal whetherend			    : std_logic;
TYPE State_type is              (WSL,WSH,WTL,WTH);
signal y       					: State_type; 
signal playend					: std_logic;

component g26_segment_decoder
	port(	code				: in std_logic_vector(3 downto 0);
		RippleBlank_In			: in std_logic;
		--RippleBlank_Out 		: out std_logic;
		segments 				: out std_logic_vector(6 downto 0));
	end component;

component g26_note_timer_board
	port(
		clk, reset,pause 		: in std_logic;
		bpm                     : in std_logic_vector(7 downto 0);
		note_duration 			: in std_logic_vector(2 downto 0);
		triplet 				: in std_logic;
		playend                 : in std_logic;
		TRIGGER 				: out std_logic
		);
	end component;

component g26_flash_read
	port(
		clk_50 					: IN  std_logic; -- clk should be 50MHz 
		rst 					: IN  std_logic;  
		shiftoctave             : in  std_logic;
		volume				    : in std_logic_vector (3 downto 0);
		trigger 				: IN  std_logic; -- trigger = 1 resets the sample address to the beginning
		note					: IN  unsigned(3 downto 0); -- selects the note to be played (within an octave)
		octave 					: IN  unsigned(2 downto 0); -- the octave the note should be played at (4 octave range)
		sample_data 			: OUT std_logic_vector(15 downto 0); -- a single 16 bit sample value, to be sent to the audio codec chip	
		
		i_data 					: IN  STD_LOGIC_VECTOR(FLASH_MEMORY_DATA_WIDTH - 1 DOWNTO 0);			
		-- Signals to be connected to Flash chip via proper I/O ports
		FL_ADDR 				: OUT 	STD_LOGIC_VECTOR(FLASH_MEMORY_ADDRESS_WIDTH - 1 DOWNTO 0);
		FL_DQ 					: INOUT 	STD_LOGIC_VECTOR(FLASH_MEMORY_DATA_WIDTH - 1 DOWNTO 0);
		FL_CE_N,
		FL_OE_N,
		FL_WE_N,
		FL_RST_N 				: OUT STD_LOGIC;
		INIT 					: IN  std_logic;
		AUD_MCLK 				: OUT std_logic; -- codec master clock input
		AUD_BCLK 				: OUT std_logic; -- digital audio bit clock
		AUD_DACDAT 				: OUT std_logic; -- DAC data lines
		AUD_DACLRCK 			: OUT std_logic; -- DAC data left/right select
		I2C_SDAT 				: OUT std_logic; -- serial interface data line
		I2C_SCLK 				: OUT std_logic  -- serial interface clock)
		);
	end component;


begin
	--whetherpause       <= whetherstop or pause or whetherend;
	
	crc_table : lpm_rom -- use the altera rom library macrocell
	GENERIC MAP(
		lpm_widthad => 8, -- sets the width of the ROM address bus
		lpm_numwords => 256, -- sets the words stored in the ROM
		lpm_outdata => "UNREGISTERED", -- no register on the output
		lpm_address_control => "REGISTERED", -- register on the input
		lpm_file => "g26_demo_song.mif", -- the ascii file containing the ROM data
		lpm_width => 16 -- the width of the word stored in each ROM location
	)
	PORT MAP(
		inclock => clk,
		address => (std_LOGIC_VECTOR(TO_unsigned(addresscounter,8))),
		q => tempofsongrom1
	);
	
	crc_table2 : lpm_rom -- use the altera rom library macrocell
	GENERIC MAP(
		lpm_widthad => 8, -- sets the width of the ROM address bus
		lpm_numwords => 256, -- sets the words stored in the ROM
		lpm_outdata => "UNREGISTERED", -- no register on the output
		lpm_address_control => "REGISTERED", -- register on the input
		lpm_file => "g26_demo_song2.mif", -- the ascii file containing the ROM data
		lpm_width => 16 -- the width of the word stored in each ROM location
	)
	PORT MAP(
		inclock => clk,
		address => (std_LOGIC_VECTOR(TO_unsigned(addresscounter,8))),
		q => tempofsongrom2
	);
	
	with songnumber select tempofsongrom <=
	tempofsongrom1 when '0',
	tempofsongrom2 when others;
	
	tempofnotenumber 			  <= tempofsongrom(3 downto 0);
	tempofoctave    			  <= tempofsongrom(6 downto 4);
	tempofnote_duration 		  <= tempofsongrom(9 downto 7);
	tempoftriplet    			  <= tempofsongrom(10);
	tempofloudness   			  <= tempofsongrom(14 downto 11);
	tempofsongend    			  <= tempofsongrom(15);
	
	Gate1: g26_note_timer_board
	PORT MAP (
			clk                 => clk, 
			reset               => reset,
			pause               => whetherpause,
			bpm                 => bpm & "00" ,
			note_duration 		=> tempofnote_duration,
			triplet             => tempoftriplet,
			TRIGGER             => tempoftrigger,
			playend             => playend
			);
	Gate2: g26_flash_read
	PORT MAP (
			clk_50  	        => clk,
			rst                 => reset,
			shiftoctave         => shiftoctave,
			volume              => tempofloudness,
			trigger             => not tempoftrigger ,
			note                => unsigned(tempofnotenumber),
			octave              => unsigned(tempofoctave),
			i_data              => i_data,
			FL_ADDR 			=> FL_ADDR,
			FL_DQ 				=> FL_DQ,
			FL_CE_N	 			=> FL_CE_N,
			FL_OE_N 			=> FL_OE_N,
			FL_WE_N             => FL_WE_N,
			FL_RST_N            => FL_RST_N,
			AUD_MCLK 			=> AUD_MCLK,
			AUD_BCLK            => AUD_BCLK,
			AUD_DACDAT          => AUD_DACDAT,
			AUD_DACLRCK         => AUD_DACLRCK,
			I2C_SDAT            => I2C_SDAT,
			I2C_SCLK            => I2C_SCLK,
			INIT				=> INIT
			);
	
	triggerforled <= tempoftrigger;
	
	--Gate3: g26_segment_decoder
	--PORT MAP (
			--code => tempofnotenumber,
			--RippleBlank_In => '1',
			--segments => segmentsofnotenumber
	--);
	
	--Gate4: g26_segment_decoder
	--PORT MAP (
			--code => tempofloudness,
			--RippleBlank_In => '1',
			--segments => segmentsofvolume
	--);
	
	--Gate5: g26_segment_decoder
	--PORT MAP (
			--code => '0' & tempofnote_duration,
			--RippleBlank_In => '1',
			--segments => segmentsofnoteduration
	--);
	
	--Gate6: g26_segment_decoder
	--PORT MAP (
			--code => '0' & tempofoctave,
			--RippleBlank_In => '1',
			--segments => segmentsofoctave
	--);
	
	one: process(clk,reset,start,stop,whetherloop,tempoftrigger,tempofsongend)
	begin
			if reset = '0'  then
				y <= WSL;
				addresscounter <= 0;
				whetherstop <= '1';
			elsif(clk ='1' and clk'event) then
				if y = WSL then
					if start ='0' then
						y <= WSH;
				    end if;
				end if;
				
				if y = WSH then 
					if start ='1' then
						y <= WTH; whetherstop <= '0';
					elsif stop ='0' then
						y <= WSL;whetherstop <= '1';addresscounter <= 0;
					end if;
				end if;
				
				if y = WTH then 
					if tempoftrigger = '1' and stop ='1' and not(whetherloop='0' and tempofsongend ='1')then
						y <= WTL; addresscounter <= addresscounter +1;
					elsif stop ='0' or (whetherloop = '0' and tempofsongend = '1') then 
						y <= WSL;whetherstop <= '1';addresscounter <= 0;
					elsif tempoftrigger ='1' and stop ='1' and whetherloop ='1' and tempofsongend ='1' then
						y <= WTl; addresscounter <= 0;
					end if;
				end if;
				
				if y = WTL then
					if tempoftrigger = '0' then
						y <= WTH;
					elsif stop ='0' then 
						y <= WSL;whetherstop <= '1';addresscounter <= 0;
					end if;
				end if;
				
				
				whetherpause <= whetherstop or pause ;
			end if;
	end process;
	

	
end arc;

	
	
	
	
	