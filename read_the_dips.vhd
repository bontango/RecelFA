-- read the dips on WillFA
-- bontango 03.2024
--
-- v 1.0 -- 895KHz input clock
-- v 1.1 900Hz input clock, continous reading
-- v 1.2 adapted to willfa11, 6strobes, 2 returns, only one time reading
-- v 1.2 adapted to RecelFA, 12strobes, one return, only one time reading

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity read_the_dips is        
        port(
            clk_in  : in std_logic;               						
				i_Rst_L : in std_logic;     -- FPGA Reset					   
				--output 
				done		: out std_logic;        -- set to 1 when read finished
				game_select	:	out std_logic_vector(5 downto 0);
				game_option	:	out std_logic_vector(1 to 6);
				-- strobes
			   dip_strobe		: out std_logic_vector(11 downto 0);
				-- input
				return_sig			: in std_logic
            );
    end read_the_dips;
    ---------------------------------------------------
    architecture Behavioral of read_the_dips is
	 	type STATE_T is ( Start, Read1, Read2, Read3, Read4, Read5, Read6, 
							   Read7, Read8, Read9, Read10, Read11, Read12,Idle ); 
		signal state : STATE_T := Start;       		
	begin
	
	
	 read_the_dips: process (clk_in, i_Rst_L, return_sig)
    begin		
			if i_Rst_L = '0' then --Reset condidition (reset_l)    
			  state <= Start;
			  dip_strobe <= ( others => '1');					
			  done <= '0';
			elsif rising_edge(clk_in) then			
				case state is
					when Start =>
						dip_strobe <= "111111111110";
						state <= Read1;						
					when Read1 =>
						game_select(0) <= return_sig;						
						dip_strobe <= "111111111101";
						state <= Read2;
					when  Read2 =>
						game_select(1) <= return_sig;
						dip_strobe <= "111111111011";
						state <= Read3;
					when  Read3 =>
						game_select(2) <= return_sig;
						dip_strobe <= "111111110111";
						state <= Read4;
					when  Read4 =>
						game_select(3) <= return_sig;
						dip_strobe <= "111111101111";						
						state <= Read5;						
					when  Read5 =>
						game_select(4) <= return_sig;
						dip_strobe <= "111111011111";						
						state <= Read6;											
					when  Read6 =>
						game_select(5) <= return_sig;
						dip_strobe <= "111110111111";						
						state <= Read7;																					
					when Read7 =>
						game_option(6) <= return_sig;
						dip_strobe <= "111101111111";
						state <= Read8;
					when  Read8 =>
						game_option(5) <= return_sig;
						dip_strobe <= "111011111111";
						state <= Read9;
					when  Read9 =>
						game_option(4) <= return_sig;
						dip_strobe <= "110111111111";
						state <= Read10;
					when  Read10 =>
						game_option(3) <= return_sig;
						dip_strobe <= "101111111111";						
						state <= Read11;						
					when  Read11 =>
						game_option(2) <= return_sig;
						dip_strobe <= "011111111111";						
						state <= Read12;											
					when  Read12 =>
						game_option(1) <= return_sig;
						dip_strobe <= ( others => '0');					
						state <= Idle;																							
					when  Idle =>		
						dip_strobe <= ( others => '0');									
						done <= '1'; -- set after first round						
				end case;				
		end if;	--rising edge		
		end process;
    end Behavioral;