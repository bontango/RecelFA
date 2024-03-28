--*****************************************************************************
--
--  Title   : Rockwell A17xx ROM RAM and IO chip
--
--  File    : rA17xx.vhd
--
--  Author  : bontango
--
--  a simplified design for implementing Rockwell 10788 chip
--
--
-- Notes
-- only IO section implemented
-- adapted to recel system3 hardware
-- v04
-- v05 OK?
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rA17xx is
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
end rA17xx;

architecture fsm of rA17xx is
    --   FSM states
  type state_t is ( wait_cs, assign, wait_io_finish );
  signal state : state_t;

begin  
  
  fsm_proc : process ( reset, clk, io_device, w_io, io_cmd, io_accu, io_port_in)
  begin  
		
		if ( reset = '0') then -- Asynchronous reset
		   --   output and variable initialisation		
			io_port_out     <= ( others => '0');
			state <= wait_cs;
		elsif rising_edge( clk) then  -- Synchronous FSM
		   	 case state is
			    ---- State 1 wait for chip select ---
				 when wait_cs =>
				 if (device_id = io_device) and ( w_io = '1' ) then
					state <= assign;
				 end if;					 
				 ---- State 2 assign values to out and read in (depends on cmd) -- four commands
				 when assign =>
					----------------------------------------------------------
					-- SES 1 - select enable status, enable all outputs
					----------------------------------------------------------					
					if (io_cmd(0)='0') and (io_accu(3)='1') then 
						-- give back ( 4bit) status of port_out value						
						if io_port_in( to_integer(unsigned(io_port))) = '1' then 
							io_data <= '1' & io_accu(2 downto 0); 
							--io_data <= "1000";
						else
							io_data <= '0' & io_accu(2 downto 0);
							--io_data <= "0000";
						end if;	
					----------------------------------------------------------
					-- SES 0 - select enable status, disable all outputs (same as SES1 at the moment !!! )
					----------------------------------------------------------					
					elsif (io_cmd(0)='0') and (io_accu(3)='0') then 
						-- give back (4bit) status of port_out value						
						if io_port_in( to_integer(unsigned(io_port))) = '1' then
							io_data <= '1' & io_accu(2 downto 0); 
							--io_data <= "1000";
						else
							io_data <= '0' & io_accu(2 downto 0);
							--io_data <= "0000";	
						end if;
					----------------------------------------------------------
					-- SOS 1 - select output status, port->1
					----------------------------------------------------------					
					elsif (io_cmd(0)='1') and (io_accu(3)='1') then 
						io_port_out( to_integer(unsigned(io_port))) <= '1';							
						--io_data <= not io_accu;
						io_data <= "0000";
					----------------------------------------------------------
					-- SOS 0 - select output status, port->0
					----------------------------------------------------------					
					elsif (io_cmd(0)='1') and (io_accu(3)='0') then 
							io_port_out( to_integer(unsigned(io_port))) <= '0';						
							--io_data <= not io_accu;
							io_data <= "1111";
					end if;
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
