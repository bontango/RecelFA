--*****************************************************************************
--
--  Title   : Rockwell 10788 Keyboard and Display controller
--
--  File    : r10788.vhd
--
--  Author  : bontango
--
--  a simplified design for implementing Rockwell 10788 chip on Recel3 MPU
--
--
-- Notes
-- display functions implemented only, no keyboard
--
-- v0.9  initial version based onGottlieb System1 version
-- v0.91 adjusted Reg_A & B count
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity r10788 is
  port( 
		  clk     : in  std_logic;
        reset   : in  std_logic;		
        device_id    : in  std_logic_vector( 3 downto 0); -- chip select
		  w_io   : in  std_logic;
		  
		  io_data : out  std_logic_vector( 3 downto 0); -- data from IO device 
		  		  		  		  
		  io_device    : in std_logic_vector( 3 downto 0); -- ID of current active IO device -> I2(7 downto 4)
		  io_cmd    : in std_logic_vector( 3 downto 0); --  command -> I2(3 downto 0)
		  io_accu    : in std_logic_vector( 3 downto 0); -- accu for input to IO device		  

		  group_A   : out  std_logic_vector( 3 downto 0); -- Digit data Group A
		  group_B   : out  std_logic_vector( 3 downto 0); -- Digit data Group B
		  
		  X   : out  std_logic_vector( 7 downto 0); -- Digit data Group A
		  DBS   : out  std_logic
		  
        );
end r10788;

architecture fsm of r10788 is

      --   FSM states
  type state_t is ( wait_cs, assign, wait_io_finish );
  signal state : state_t;

  signal count : integer range 0 to 26000 := 0;
  --signal digit : integer range 0 to 15 := 0;  
  signal blanking	: 	std_logic:= '0';
  signal reg_A_count : std_logic_vector( 3 downto 0);
  signal reg_B_count : std_logic_vector( 3 downto 0);
  
  signal mask_a : std_logic_vector( 3 downto 0);
  signal mask_b : std_logic_vector( 3 downto 0);

  -- internal buffer display regs
  signal	  strobes : std_logic_vector( 3 downto 0);
  type DISP_REG_TYPE is array (0 to 15) of std_logic_vector(3 downto 0);
  signal DISP_REG_A            : DISP_REG_TYPE;	
  signal DISP_REG_B            : DISP_REG_TYPE;		
	
begin  --  fsm 
  
  fsm_proc : process ( clk, reset)
  begin  --  process fsm_proc 
		
		if ( reset = '0') then  -- Asynchronous reset
			--   output and variable initialisation
			state <= wait_cs;
			DISP_REG_A <= (others=>(others=>'0'));
			DISP_REG_B <= (others=>(others=>'0'));			
			reg_A_count <= (others=>'0');
			reg_B_count <= (others=>'0');
			mask_a <= (others=>'0');
			mask_b <= (others=>'0');
		elsif rising_edge( clk) then  -- Synchronous FSM

		-- not fully implemented yet
		
		   	 case state is
			    ---- State 1 wait for chip select ---
				 when wait_cs =>
				 if (device_id = io_device) and ( w_io = '1' ) then
				   io_data <= "0000"; --give feedback 					
					state <= assign;
				 end if;	
				 
				 ---- State 2 assign values to out depends on cmd)
				 when assign =>
					-- possible commands
					case io_cmd is
						when "1110" => --  0xE load display register A 16 times each, need to count)						   
							DISP_REG_A( conv_integer (reg_A_count)) <= not io_accu;
							reg_A_count <= reg_A_count + 1;
							
						when "1101" => --  0xD load display register B 16 times, need to count)
							DISP_REG_B( conv_integer (reg_B_count)) <= not io_accu;
							reg_B_count <= reg_B_count + 1;	
							
						when "1011" => --  0xB Blank the displays of DA1,DA2,DA3,DA4,DB1,DB2
							mask_a <= "1111";
							mask_b <= mask_b or "0011";
						
						when "0111" => --  0x7 Blank the displays DB3,DB4
							mask_b <= mask_b or "1100";

					
						when "0011" => --  0x3 turn on display
							mask_a <= "0000";
							mask_b <= "0000";
							
						when others =>
							-- nop

							end case; -- cmd
					state <= wait_io_finish;
					
				 when wait_io_finish =>
				 ---- State 3 wait for current io cycle to be finished
				 if ( w_io = '0' ) then 
					state <= wait_cs;
				 end if;	
			end case;  --  state
		end if; -- rising_edge(clk)
  end process fsm_proc;
  
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
					group_A <= DISP_REG_A( conv_integer(strobes)) or mask_a; 
					group_B <= DISP_REG_B( conv_integer(strobes)) or mask_b;	
				end if;	
			end if; --rising edge		
		end process;

end fsm;
		