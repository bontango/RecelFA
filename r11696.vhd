--*****************************************************************************
--
--  Title   : Rockwell r10696 General Purpose INPUT/OUTPUT GP I/O Device
--
--  File    : r11696.vhd
--
--  Author  : bontango
--
--  a simplified design for implementing Rockwell 11696 chip
--
--
-- Chip has 24 IOports
--
--REGISTER DESCRIPTION ( Assumptions )
--
-- organized in Group of 4 bits ( 6 Groups ) 3-4-5-6-7-8
-- Group	: 	OUT   :	 IN : Group
--    3     D0    :   D8 	: 3
--    4     D1    :   D9	: 4
--    5     D2    :   DA	: 5
--    6     D3    :   DF	: 6
--    7     D4    :   DC	: 7
--    8     D5    :   DD	: 8
--
-- D6 sets and DB unsets

-- Notes
-- special config for Recel3 MPU only
-- all ports configured as outputs
-- fix return values for 'IN' groups (last setting of associated pair)
-- implemented commands
-- D4 -> sets group 7 : Bonus Bits A..D
-- D5 -> sets Group 8 : L71,L72,L74, play signal
-- D6 -> sets port x to ON x=0..15 Group 6,5,4,3 (sound&coils)
-- DB -> sets port x to OFF x=0..15 Group 6,5,4,3 (sound&coils)
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r11696 is
  port( 
		  clk     : in  std_logic;
        reset   : in  std_logic;		
        device_id    : in  std_logic_vector( 3 downto 0); -- chip select
		  w_io   : in  std_logic;
		  		  
		  io_data : out  std_logic_vector( 3 downto 0); -- data from IO device 
		  
		  io_device    : in std_logic_vector( 3 downto 0); -- ID of current active IO device -> I2(7 downto 4)
		  io_cmd    : in std_logic_vector( 3 downto 0); --  command -> I2(3 downto 0)
		  io_accu    : in std_logic_vector( 3 downto 0); -- accu for input to IO device		  
		
		  sound_and_coils_out   : out  std_logic_vector( 15 downto 0); 
		  group_7_out   : out  std_logic_vector( 3 downto 0); 
		  group_8_out   : out  std_logic_vector( 3 downto 0)

        );
		  
end r11696;

architecture fsm of r11696 is

    --   FSM states
  type state_t is ( wait_cs, assign, wait_io_finish );
  signal state : state_t;
  signal io_accu_D0   : std_logic_vector( 3 downto 0); 
  signal io_accu_D1   : std_logic_vector( 3 downto 0);   
  signal io_accu_D2   : std_logic_vector( 3 downto 0);   
  signal io_accu_D3   : std_logic_vector( 3 downto 0); 
  signal io_accu_D4   : std_logic_vector( 3 downto 0);   
  signal io_accu_D5   : std_logic_vector( 3 downto 0);   
  
begin  
  
  fsm_proc : process ( reset, clk)
  begin  

		if ( reset = '0') then -- Asynchronous reset
		   --   output and variable initialisation			
			sound_and_coils_out  <= ( others => '0');
			group_7_out     <= ( others => '0');
			group_8_out     <= ( others => '0');
			io_accu_D0      <= ( others => '0');
			io_accu_D1      <= ( others => '0');
			state <= wait_cs;
		elsif rising_edge( clk) then  -- Synchronous FSM
		   	 case state is
			    ---- State 1 wait for chip select ---
				 when wait_cs =>
				 if (device_id = io_device) and ( w_io = '1' ) then
					state <= assign;
				 end if;	
				 
				 ---- State 2 assign values to out and read in (depends on cmd)
				 when assign =>
					-- possible commands
					case to_integer(unsigned(io_cmd)) is
						when 16#00# => 
							io_accu_D0 <= io_accu;
							io_data <= "0000"; --give feedback 
						when 16#08# => 
							io_data <= io_accu_D0; 

						when 16#01# => 
							io_accu_D1 <= io_accu;
							io_data <= "0000"; --give feedback 
						when 16#09# => 
							io_data <= io_accu_D1; 

						when 16#02# => 
							io_accu_D2 <= io_accu;
							io_data <= "0000"; --give feedback 
						when 16#0A# => 
							io_data <= io_accu_D2; 

						when 16#03# => 
							io_accu_D3 <= io_accu;
							io_data <= "0000"; --give feedback 
						when 16#0F# => 
							io_data <= io_accu_D3; 
							
						when 16#04# => 
							group_7_out <= not io_accu;-- set with negated accu 
							io_accu_D4 <= io_accu; 
							io_data <= "0000"; --give feedback 
						when 16#0C# => 
							io_data <= io_accu_D4; 
							
						when 16#05# => 
							group_8_out <= not io_accu; -- set with negated accu
							io_accu_D5 <= io_accu; 
							io_data <= "0000"; --give feedback 
						when 16#0D# => 
							io_data <= io_accu_D5; 
	
						when 16#06# => 
							sound_and_coils_out( to_integer(unsigned(not io_accu))) <= '1';	
						when 16#0B# => 
							sound_and_coils_out( to_integer(unsigned(not io_accu))) <= '0';	
							
						when others =>
							io_data <= "0000"; --give feedback 
					end case; -- cmd
					state <= wait_io_finish;
					
				 when wait_io_finish =>
				 ---- State 3 wait for current iio cycle to be finished
				 if ( w_io = '0' ) then 
					state <= wait_cs;
				 end if;	
			end case;  --  state
		end if; -- rising_edge(clk)
  end process fsm_proc;
end fsm;
