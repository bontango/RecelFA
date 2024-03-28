library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Counter_74HC4040 is
    Port (
        CLK     : in  STD_LOGIC;
        CLR     : in  STD_LOGIC;
        Q       : out STD_LOGIC_VECTOR(11 downto 0)
    );
end Counter_74HC4040;

architecture Behavioral of Counter_74HC4040 is
    signal counter : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
begin
    process(CLK, CLR)
    begin
        if CLR = '1' then
            counter <= (others => '0'); -- Clear-Zustand
        elsif falling_edge(CLK) then
            if counter = "111111111111" then
                counter <= (others => '0'); -- Wenn der Zähler voll ist, setze ihn auf Null
            else
                counter <= counter + 1; -- Zähler erhöhen
            end if;
        end if;
    end process;

    Q <= counter; -- Ausgang mit Zählerstand verbinden
end Behavioral;
