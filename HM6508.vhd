--v 0.2 with external ram

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity HM6508 is
    Port (
        clk : in STD_LOGIC;
		  reset : in STD_LOGIC;
        addr : in STD_LOGIC_VECTOR(9 downto 0);
        data_in : in STD_LOGIC;
        data_out : out STD_LOGIC;
        write_enable_n : in STD_LOGIC;
        enable_n : in STD_LOGIC;
		  --
		  address : out STD_LOGIC_VECTOR(9 downto 0);
		  ram_in : in STD_LOGIC_VECTOR(0 downto 0);
		  ram_out : out STD_LOGIC_VECTOR(0 downto 0);
		  wren : out STD_LOGIC
    );
end HM6508;

architecture Behavioral of HM6508 is
    type ram_type is array (1023 downto 0) of STD_LOGIC;
    signal ram : ram_type;
	 signal old_write_enable_n : std_LOGIC;
begin
    process (clk, addr, data_in, write_enable_n, reset, ram_in)
    begin
		if ( reset = '0') then  -- Asynchronous reset 
			old_write_enable_n <= '1';
      elsif rising_edge(clk) then
            if enable_n = '0' then
					-- data out valid when not in write cycle
					if ( write_enable_n = '1' ) then
						address <= addr;
						wren <= '0';	-- we read
						data_out <= ram_in(0);
					end if;						
					-- did write_enable_n change?
               if ( old_write_enable_n /= write_enable_n ) then						
						if ( write_enable_n = '0' ) then -- write_enable_n went low -> Output in Z-State
						  wren <= '0';	-- ram in read mode
                    data_out <= '1'; --Z state when not enabled, pull-up on PCB
						else
							address <= addr;
							wren <= '1';	-- we write						
							ram_out(0) <= data_in; -- write_enable_n went high -> write data_in
						end if;					
					end if;
				else
						data_out <= '1'; --Z state when not enabled, pull-up on PCB
						wren <= '0';	-- ram in read mode
            end if;
				-- remember state of write_enable_n
				old_write_enable_n <= write_enable_n;				
        end if;
    end process;
end Behavioral;
