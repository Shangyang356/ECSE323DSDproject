-- this circuit is the finite state machine which monitors the four main state of the system 
--
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

entity g26_lab5_FSM_simulation is

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
	trigger,
	whetherloop               	: in std_logic;
	addresscounter 				: out integer range 0 to 255;
	whetherpause,statewsl,statewsh,statewtl,statewth				: out std_logic

);
end g26_lab5_FSM_simulation;

architecture arc of g26_lab5_FSM_simulation is 

TYPE State_type is              (WSL,WSH,WTL,WTH);
signal y       					: State_type; 
signal tempoftrigger			: std_logic;
signal tempofaddresscounter 			: integer range 0 to 255;
signal whetherstop						: std_logic;

begin
	one: process(clk,reset,start,stop,whetherloop,trigger)
	begin
			if reset = '0'  then
				y <= WSL;
				tempofaddresscounter <= 0;
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
						y <= WSL;whetherstop <= '1';tempofaddresscounter <= 0;
					end if;
				end if;
				
				if y = WTH then 
					if tempoftrigger = '1' then
						y <= WTL; tempofaddresscounter <= tempofaddresscounter +1;
					elsif stop ='0' or (whetherloop = '0' and tempofaddresscounter >29) then 
						y <= WSL;whetherstop <= '1';tempofaddresscounter <= 0;
					elsif stop ='1' and whetherloop ='1' and tempofaddresscounter >29 then
						tempofaddresscounter <= 0; y<= WTL;
					end if;
				end if;
				
				if y = WTL then
					if tempoftrigger = '0' then
						y <= WTH;
					elsif stop ='0' then 
						y <= WSL;whetherstop <= '1';tempofaddresscounter <= 0;
					end if;
				end if;	
			end if;
			 	whetherpause <= whetherstop or pause ;
				addresscounter <= tempofaddresscounter;
				if whetherstop ='1' or pause ='1' then
					tempoftrigger <= '0';
				else tempoftrigger <= trigger;
				end if;
				
			case y is
				when WSL =>
					statewsl <= '1';statewsh <= '0'; statewth <='0'; statewtl <='0';
				when WSH =>
					statewsl <= '0';statewsh <= '1'; statewth <='0'; statewtl <='0';
				when WTH =>
					statewsl <= '0';statewsh <= '0'; statewth <='1'; statewtl <='0';
				when WTL =>
					statewsl <= '0';statewsh <= '0'; statewth <='0'; statewtl <='1';
			end case;
				 
			
	end process;
end arc;