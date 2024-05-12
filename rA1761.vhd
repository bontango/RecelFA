--*****************************************************************************
--
--  Title   : Rockwell A17xx ROM RAM and IO chip
--
--  File    : rA1761.vhd
--
--  Author  : bontango
--
--  a simplified design for implementing Rockwell 10788 chip
--
--
-- Notes
-- only IO section implemented
-- adapted to recel system3 hardware
-- v02 no negated accu with CPU v08
-- v03 IO 0 fix set to input
-- v04 negated accu again
-- v05 OK?
-- v06 tests but looking good
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rA1761 is
  port( 
		  clk     : in  std_logic;
        reset   : in  std_logic;		
        device_id    : in  std_logic_vector( 3 downto 0); -- chip select
		  w_io   : in  std_logic;
		  		  
		  io_data : out  std_logic_vector( 3 downto 0); -- data from IO device 
		  
		  io_device    : in std_logic_vector( 3 downto 0); -- ID of current active IO device -> I2(7 downto 4)
		  io_cmd    : in std_logic_vector( 3 downto 0); --  command -> I2(3 downto 0)
		  io_accu    : in std_logic_vector( 3 downto 0); -- accu for input to IO device
		  io_port    : in std_logic_vector( 3 downto 0); -- port of IO device (BL)

		  io_port_in   : in  std_logic_vector( 15 downto 0); 
		  io_port_out   : buffer  std_logic_vector( 15 downto 0) 		
        );
end rA1761;

architecture fsm of rA1761 is
    --   FSM states
  type state_t is ( wait_cs, assign, wait_io_finish );
  signal state : state_t;
  signal port_state : std_logic; --1=enabled 0=disabled

begin  
  
  fsm_proc : process ( reset, clk, io_device, w_io, io_cmd, io_accu, io_port_in)
  begin  
		
		if ( reset = '0') then -- Asynchronous reset
		   --   output and variable initialisation		
			io_port_out     <= ( others => '0');
			port_state <= '0';
			state <= wait_cs;
		elsif rising_edge( clk) then  -- Synchronous FSM
		   	 case state is
			    ---- State 1 wait for chip select ---
				 when wait_cs =>
				 if (device_id = io_device) and ( w_io = '1' ) then
					state <= assign;
				 end if;					 
				 -- State 2 assign values to out and read in (depends on cmd) -- four commands
				 -- remember that io_accu is inverted accu due to IOL command
				 when assign =>
					----------------------------------------------------------
					-- SES 0 - select enable status, disable all outputs 					
					----------------------------------------------------------					
					if (io_cmd(0)='0') and (io_accu(3)='1') then 
						port_state <= '0';
					----------------------------------------------------------
					-- SES 1 - select enable status, enable all outputs					
					----------------------------------------------------------					
					elsif (io_cmd(0)='0') and (io_accu(3)='0') then 
						port_state <= '1'; 
					----------------------------------------------------------
					-- SOS 0 - select output status, port->0					
					----------------------------------------------------------					
					elsif (io_cmd(0)='1') and (io_accu(3)='1') then 
						if port_state = '1' then
							io_port_out( to_integer(unsigned(io_port))) <= '1'; -- TTL logik, set port to '1' !
						end if;

						io_data <= "0000";

					----------------------------------------------------------
					-- SOS 1 - select output status, port->1 					
					----------------------------------------------------------					
					elsif (io_cmd(0)='1') and (io_accu(3)='0') then 
							if port_state = '1' then
								io_port_out( to_integer(unsigned(io_port))) <= '0'; -- TTL logik, set port to '1' !
							end if;
						-- IO 0 is input, Recel do read with SOS 1: give back real status here							
						if ( io_port = "0000") then
							if ( io_port_out(0) = '1' ) then -- last setting was SOS 0
										io_data <= "1111";
							else	
									if io_port_in(0) = '1' then 
										io_data <= "0111"; -- "0000"; RTH
									else
										io_data <= "1111";
									end if;	
							end if;		
						else		
								io_data <= "1111";
						end if;	
					end if;	
						state <= wait_io_finish;
					----------------------------------------------------------
					-- io finish
					----------------------------------------------------------										
				 when wait_io_finish =>
				 ---- State 3 wait for current iio cycle to be finished
				 if ( w_io = '0' ) then 
					state <= wait_cs;
				 end if;	
			end case;  --  state
		end if; -- rising_edge(clk)
  end process fsm_proc;
end fsm;
