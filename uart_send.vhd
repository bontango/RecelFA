-- simple transmitter for CH340 uart
--
-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.
--
-- Version 0.1
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_send is
    Port ( 
           clk : in  STD_LOGIC; -- need to be fix 9600baud
           rst : in  STD_LOGIC; --reset_l
           txd : out  STD_LOGIC; --txd pin
			  char_to_send : in  std_logic_vector (7 downto 0); 
           send_flag : in  STD_LOGIC --flag: start sending		
		);	  
end uart_send;

architecture Behavioral of uart_send is

function reverse_any_vector (a: in std_logic_vector)
    return std_logic_vector is
  variable result: std_logic_vector(a'RANGE);
  alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
begin
  for i in aa'RANGE loop
    result(i) := aa(i);
  end loop;
  return result;
end; -- function reverse_any_vector
  
  signal output : std_logic_vector (9 downto 0);    
  type STATE_T is ( Idle, Send, Check); 
  signal state : STATE_T;        --State
  signal bitcounter : integer range 0 to 10;
begin

DFPLAYR_Mini : process (clk, rst, send_flag, char_to_send) is
  
begin
  if rst = '0' then --Reset condidition (reset_l)
    txd <= '1';
    state <= Idle;    
  elsif rising_edge(clk)then
    case state is
	   when Idle => --with the first tick we contruct the paket to send (100 bits; 99..0)
        if send_flag = '1' then -- send flag is true, start sending
			 output <=   '0' & reverse_any_vector(std_logic_vector(char_to_send)) & '1' ;
			 -- reset counter
			 bitcounter <= 9; 
			 -- new state
          state <= send;
        end if;		      
      when Send =>   
        txd <= output(bitcounter); 
        bitcounter <= bitcounter - 1;
        if bitcounter = 0 then          
          state <= Check;
        end if;
      when Check =>   -- wait in this stae until flag to go down
			if send_flag = '0' then
				state <= Idle;
			end if;
      end case;
  end if;
end process;
end architecture;

