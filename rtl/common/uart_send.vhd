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
-- Version 0.3
-- use seperate tx module
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_send is
    Port ( 
           clk : in  STD_LOGIC; -- 50MHz
           rst : in  STD_LOGIC; --reset_l
           txd : out  STD_LOGIC; --txd pin	
			  rxd : in  STD_LOGIC; --rxd pin	
			  address	: buffer 	std_logic_vector(7 downto 0);	  
			  data	: in 	std_logic_vector(3 downto 0)           
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

--frm https://gist.github.com/mathieucaroff/3132c36ff21b63a72c8c0574998859ee
function hex (lvec: in std_logic_vector) return character is
		variable text : character;
		subtype halfbyte is std_logic_vector(4-1 downto 0);
	begin
			case halfbyte'(lvec) is
				when "0000" => text := '0';
				when "0001" => text := '1';
				when "0010" => text := '2';
				when "0011" => text := '3';
				when "0100" => text := '4';
				when "0101" => text := '5';
				when "0110" => text := '6';
				when "0111" => text := '7';
				when "1000" => text := '8';
				when "1001" => text := '9';
				when "1010" => text := 'A';
				when "1011" => text := 'B';
				when "1100" => text := 'C';
				when "1101" => text := 'D';
				when "1110" => text := 'E';
				when "1111" => text := 'F';
				when others => text := '!';
			end case;
		return text;
	end function;  
  
signal uart_data_tx : std_logic_vector (7 downto 0);   
signal uart_data_rx : std_logic_vector (7 downto 0);   
 
type STATE_T is ( Idle, next_char, Send, Check, set_data_addr, construct_string, Finish); 
signal state : STATE_T;        --State
  
signal string_to_send : string (1 to 11);
constant string_length : integer range 0 to 15 := 11;
signal tx_index : integer range 0 to 15 := 0;
signal ram_index : integer range 0 to 280 := 0;

signal r_TX_DV : std_logic := '0';
signal r_TX_ACTIVE : std_logic;
signal uart_rx_flag : std_logic;

begin


UART_TX_INST : entity work.uart_tx 
--  generic map (
--    g_CLKS_PER_BIT => c_CLKS_PER_BIT 434 for 50MHz default
--      )
    port map (
      i_clk       => clk,
      i_tx_dv     => r_TX_DV,
      i_tx_byte   => uart_data_tx,
      o_tx_active => r_TX_ACTIVE,
      o_tx_serial => txd,
      o_tx_done   => open
      );


UART_RX_INST : entity work.uart_rx
    port map (
      i_clk       => clk,
      i_rx_serial => rxd,
      o_rx_dv     => uart_rx_flag,
      o_rx_byte   => uart_data_rx
      );

uart_send : process (clk, rst, uart_rx_flag) is
  
begin
  if rst = '0' then --Reset condidition (reset_l)
	 r_TX_DV <= '0';
    state <= Idle;    
  elsif rising_edge(clk)then
    case state is
	   when Idle => 
        if uart_rx_flag = '1' then -- rx flag is true, start sending
			 -- new state
			 tx_index <= 0;
			 ram_index <= 0;
          state <= set_data_addr;			 
        end if;		    

		when set_data_addr =>   
			if ram_index < 256 then
				ram_index <= ram_index + 1;
				address <= std_logic_vector(to_unsigned(ram_index, 8));
				state <= construct_string;
			else
				state <= Idle;
			end if;

		when construct_string =>   			
		  string_to_send <= " 0" & hex(address(7 downto 4)) & hex(address(3 downto 0)) & " : " & hex(data) & ";" & cr & lf;
		  tx_index <= 0;
		  state <= next_char;
		  
      when next_char =>   
		   if tx_index < string_length then			 
			 uart_data_tx <=   std_logic_vector(to_unsigned(character'pos(string_to_send(tx_index + 1)), 8));
		    -- next index
			 tx_index <= tx_index + 1;
			 state <= Send;
			else
			 state <= set_data_addr;
			end if;
			
      when Send =>   
        r_tx_DV <= '1';
		  state <= Check;	
	
      when Check =>   -- wait for active
        r_tx_DV <= '0';
		  if r_TX_ACTIVE = '1' then
			state <= Finish;	
		  end if;
	
      when Finish =>   -- wait in this state until flag to go down
			if r_TX_ACTIVE = '0' then
				state <= next_char;
			end if;
			
      end case;
  end if;
end process;
end architecture;

