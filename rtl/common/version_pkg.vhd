-- version_pkg.vhd - die Softwareversion, gemeinsam fuer alle RecelFA-Varianten.
--
-- Die auf dem Boot-Display angezeigte Version ist
--
--     SW_MAIN . SW_SUB1 . SW_SUB2
--
-- wobei SW_MAIN aus variants/<name>/variant_pkg.vhd kommt (BOARD_ID: Cyclone IV = 1,
-- Cyclone 10 = 2). Ein Release aendert deshalb genau EINE Ziffer hier, und beide
-- Boards folgen. Vorher stand SW_MAIN/SW_SUB1/SW_SUB2 in jeder Variantenkopie des
-- Top-Levels - genau dort sind die beiden Varianten auseinandergelaufen.
--
-- Angezeigt wird das in Recel_init (display1), siehe top/RecelFA.vhd.
library ieee;
use ieee.std_logic_1164.all;

package version_pkg is
	constant SW_SUB1 : std_logic_vector(3 downto 0) := x"0";
	constant SW_SUB2 : std_logic_vector(3 downto 0) := x"4";
end package version_pkg;
