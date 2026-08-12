-- variant_pkg.vhd - was dieses Board ist, als VHDL-Konstante.
-- Variante: cyclone_10 (RecelFA-Platine mit dem Cyclone 10 Board, 10CL006YE144C8G)
--
-- Diese Datei liegt im Variantenordner, nicht in rtl/common/, und ist der ERSTE
-- Eintrag der erzeugten .qsf. Alles uebrige am Design ist gemeinsam.
library ieee;
use ieee.std_logic_1164.all;

package variant_pkg is
	-- Fuehrende Ziffer der auf dem Boot-Display angezeigten Version. Zusammen mit
	-- SW_SUB1/SW_SUB2 aus rtl/common/version_pkg.vhd ergibt das BOARD_ID.SW_SUB1.SW_SUB2,
	-- hier also 2.0.x - dieselbe Ziffer steckt auch im Dateinamen RecelFA_v2xx.jic.
	constant BOARD_ID : std_logic_vector(3 downto 0) := x"2";
end package variant_pkg;
