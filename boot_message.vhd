-- boot message on Recel Display
-- part of  RecelFA
-- bontango 03.2024
--
-- v 1.0
-- 50 MHz input clock


LIBRARY ieee;
USE ieee.std_logic_1164.all;

package instruction_buffer_type is
	type DISPLAY_T is array (0 to 4) of std_logic_vector(3 downto 0);
end package instruction_buffer_type;

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.instruction_buffer_type.all;

    entity boot_message is        
        port(
			  clk     : in  std_logic;
			  reset   : in  std_logic;		
			  is_error  : in  std_logic;		--active low
		  
				-- input (display data)
			   display1			: in  DISPLAY_T;
				display2			: in  DISPLAY_T;
				display3			: in  DISPLAY_T;
				display4			: in  DISPLAY_T;		
				error_display4		: in  DISPLAY_T;		
				
				--output (display control)
				group_A   : out  std_logic_vector( 3 downto 0); -- Digit data Group A
				group_B   : out  std_logic_vector( 3 downto 0); -- Digit data Group B
		  
				X   : out  std_logic_vector( 7 downto 0); -- Digit data Group A
				DBS   : out  std_logic

            );
    end boot_message;
    ---------------------------------------------------
    architecture Behavioral of boot_message is
	 
	 signal count : integer range 0 to 26000 := 0;
	  signal blanking	: 	std_logic:= '0';
	  
	  -- internal buffer display regs
	  signal	  strobes : std_logic_vector( 3 downto 0);
	  type DISP_REG_TYPE is array (0 to 15) of std_logic_vector(3 downto 0);
	  signal DISP_REG_A            : DISP_REG_TYPE;	
	  signal DISP_REG_B            : DISP_REG_TYPE;		

	 
  begin
	
  boot_message: process (display1, display2, display3, display4)
    begin
	 				DISP_REG_A(15) <= "1111"; 
					DISP_REG_A(14) <= "1111"; 
					DISP_REG_A(13) <= "1111"; 
					DISP_REG_A(12) <= display1(4);
					DISP_REG_A(11) <= display1(3);
					DISP_REG_A(10) <= display1(2);
					DISP_REG_A(9) <= display1(1);
					DISP_REG_A(8) <= display1(0);
					
					DISP_REG_A(7) <= "1111"; 
					DISP_REG_A(6) <= "1111"; 
					DISP_REG_A(5) <= "1111"; 
					DISP_REG_A(4) <= display2(4);
					DISP_REG_A(3) <= display2(3);
					DISP_REG_A(2) <= display2(2);
					DISP_REG_A(1) <= display2(1);
					DISP_REG_A(0) <= display2(0);					

					DISP_REG_B(15) <= "1111"; 
					DISP_REG_B(14) <= "1111"; 
					DISP_REG_B(13) <= "1111"; 
					if ( is_error = '0' ) then						
						DISP_REG_B(12) <= error_display4(4);
						DISP_REG_B(11) <= error_display4(3);
						DISP_REG_B(10) <= error_display4(2);
						DISP_REG_B(9) <= error_display4(1);
						DISP_REG_B(8) <= error_display4(0);
					else
						DISP_REG_B(12) <= display4(4);
						DISP_REG_B(11) <= display4(3);
						DISP_REG_B(10) <= display4(2);
						DISP_REG_B(9) <= display4(1);
						DISP_REG_B(8) <= display4(0);
					end if;
					DISP_REG_B(7) <= "1111"; 
					DISP_REG_B(6) <= "1111"; 
					DISP_REG_B(5) <= "1111"; 
					DISP_REG_B(4) <= display3(4);
					DISP_REG_B(3) <= display3(3);
					DISP_REG_B(2) <= display3(2);
					DISP_REG_B(1) <= display3(1);
					DISP_REG_B(0) <= display3(0);			
					
		end process;

-- structure of Recel 
DBS <= not strobes(3);
Xout: process (strobes, blanking)
   begin	
		if (blanking = '1') then
			X <= (others=>'0');			
		else	
			case strobes(2 downto 0) is
				when "000" => 	X <= "00000001";
				when "001" => 	X <= "00000010";
				when "010" => 	X <= "00000100";
				when "011" => 	X <= "00001000";								
				when "100" => 	X <= "00010000";								
				when "101" => 	X <= "00100000";								
				when "110" => 	X <= "01000000";								
				when "111" => 	X <= "10000000";								
			end case;	
		end if;	
	end process;
	 
 refresh: process (clk, reset)
    begin
			if ( reset = '0') then
			-- if ( reset = '0') or ( display_status = '0') then  -- Asynchronous reset or display off
				--   output and variable initialisation
				strobes <= "0000";
				group_A <= "1111"; -- display blank
				group_B <= "1111";	 
				count <= 0;
				--digit <= 0;
			elsif rising_edge(clk) then
				-- inc count for next round
				-- 50MHz input we have a clk each 20ns
				-- new refresh after 0,382ms, which is a count of 19.100
				count <= count +1;
				--ghosting prevention, we switch off displays before switching to next digit
				if ( count = 19100) then 					     
					blanking <= '1';
					strobes <= strobes +1;
				end if;

				if ( count = 19100 + 5000) then -- gap is 5000
					blanking <= '0';
					count <= 0;					
				end if;					
				
				if ( blanking = '1') then
					group_A <= "1111"; -- display blank
					group_B <= "1111";	 								
				else
					group_A <= DISP_REG_A( conv_integer(strobes)); 
					group_B <= DISP_REG_B( conv_integer(strobes));	
				end if;	
			end if; --rising edge		
		end process;
			
		
	end Behavioral;