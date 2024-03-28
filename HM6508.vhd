library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity HM6508_RAM is
    Port (
        clk : in STD_LOGIC;
        addr : in STD_LOGIC_VECTOR(9 downto 0);
        data_in : in STD_LOGIC;
        data_out : out STD_LOGIC;
        write_enable_n : in STD_LOGIC;
        enable_n : in STD_LOGIC
    );
end HM6508_RAM;

architecture Behavioral of HM6508_RAM is
	type RAMTYPE is array (1023 downto 0) of std_logic;
   signal RAM             : RAMTYPE := ( others => '1');
begin
    process (clk, addr, data_in, write_enable_n)
    begin
        if rising_edge(clk) then
            if enable_n = '0' then
                if write_enable_n = '0' then
                    RAM(conv_integer(addr)) <= data_in;
						  --data_out <= data_in;
                else
                    data_out <= RAM(conv_integer(addr));
                end if;
            end if;
        end if;
    end process;
end Behavioral;
