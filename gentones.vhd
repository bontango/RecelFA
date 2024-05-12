----------------------------------------------------------------------------------
-- Company: 
-- Engineer: garzol
-- 
-- Create Date: 09.05.2024 11:23:32
-- Design Name: 
-- Module Name: gentones - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gentones is
    Port (
           hiclk       : in        STD_LOGIC;
           tonesel     : in        std_logic_vector(4 downto 0);
           soundout    : out       std_logic
          );
end gentones;

architecture Behavioral of gentones is

signal   tone_clk        : unsigned(4 downto 0) := (others => '0');
constant c_basetonehi    : integer:=8928; --is 5600Hz for 20ns ticks

signal   s10p            : std_logic;
signal   s100p           : std_logic;
signal   s1kp            : std_logic;
signal   s10kp           : std_logic;
signal   s100kp          : std_logic;

begin
   
    --gated by group D/8 (11696 pin38)
    s10p    <= not (not tone_clk(0) and tonesel(0));
    
    --gated by group D/4 (11696 pin37)
    s100p   <= not (tone_clk(1) and tonesel(1));
    
    --gated by group D/2 (11696 pin35)
    s1kp    <= not (tone_clk(2) and tonesel(2));
    
    --gated by group D/1 (11696 pin34)
    s10kp   <= not (tone_clk(3) and tonesel(3));
    
    --gated by group C/8 (11696 pin33)
    s100kp  <= not (tone_clk(4) and tonesel(4));
    
    soundout <= not (s10p and s100p and s1kp and s10kp and s100kp);
    
    --base tone clock at 5600Hz from a clock at 50MHz
    process(hiclk)
        variable     tickcnt : integer range 0 to c_basetonehi+1 := 0;
    begin
        if (rising_edge(hiclk)) then
            tickcnt := tickcnt+1;
            if tickcnt >= c_basetonehi then
                tickcnt := 0;
                tone_clk <= tone_clk + "1";
            end if;
        end if;
    end process;

end Behavioral;
