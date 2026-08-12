--
-- generate 400KHz clock for Recel from 50Mhz system clock
-- CPU needs to be clocked 2x
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;

	entity cpu_clk_gen is
		port(
                clk_in  : in std_logic;                
                cpu_clk_out : out std_logic;
					 reset : in std_logic
            );
    end cpu_clk_gen;
	 
   architecture Behavioral of cpu_clk_gen is
	   signal q_cpuClkCount : integer range 0 to 254;
		--signal q_cpuClkCount	: std_logic_vector(6 downto 0); 
    begin
		cpu_clk_gen: process (clk_in, reset)
		begin
		if ( reset = '0') then  -- Asynchronous reset      
			cpu_clk_out     <= '0';
			q_cpuClkCount   <= 0;
		elsif rising_edge(clk_in) then
					if q_cpuClkCount < 126 then		
						q_cpuClkCount <= q_cpuClkCount + 1;
					else
						q_cpuClkCount <= 0;
					end if;
					if q_cpuClkCount < 63 then		
						cpu_clk_out <= '0';
					else
						cpu_clk_out <= '1';
					end if;
				end if;
			end process;
    end Behavioral;				

-- CPU Clock

-- CPU frequency 	Counter top 	Counter half-way
-- 200Khz if cpuClkCount < 250 then 	if cpuClkCount < 125 then
-- 396,8Khz if cpuClkCount < 126 then 	if cpuClkCount < 64 then
-- 400Khz if cpuClkCount < 125 then 	if cpuClkCount < 63 then


    