-- VHDL implementation of a Recel III MPU
-- (c)2024 bontango
--
-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.
--
--  a simplified design for implementing Rockwell parts needed for a Recel II MPU
--
-- v0.10 IO config to real RecelFA
-- v0.11 updated with latest versions from WillFA_Test CPU
-- v0.12 added dip read, boot message & boot phases
-- v0.13 adapted 11696 outports, activated game select 
-- v0.14 game prom is 2K now for all games (1702 to be duplicated 8 times)
-- v0.15 real switch input (DIA), LED2 now signals sounds
-- v0.16 changed DOA pins, added option to be able to test RecelFA with 'nothing' connected ( DIA = "1111") 
-- v0.17 added D0,D1, D2,D3 commands to r11696
-- v0.18 changed HM6508 from internal ram to external fram
-- v0.19 changed logic HM6508
-- v0.20 clocks via PLL, added test serial out, changed DIA, debug version
-- v0.21 adjusted DIA/DOA to original CPU
-- v0.22 implemented fram
-- v0.30 special rom format based on source for Testpcb, new 1761,17axx, hm6508
-- v0.31 pps4.vhd v0.8 (testversion)
-- v0.32 pps4.vhd v0.8 with resolved 'T' bug
-- v0.33 pps4.vhd v0.9 with modified skip instruction
-- v0.34 HM6508 with standard (dual access) ram
-- v0.35 added fram
-- v0.36 corrected coil assignments in v0.2 r11696.vhd
-- v0.37 sounds renamed and reordered & v0.3 r11696.vhd with modified return values
-- v0.38 with PPS4_2.vhd v091 ( splitted PC to hi/low )
-- v0.39 with RecelFA.mif init file, 2port ram 1024x1 & 256x4
-- v0.40 added gentones and deactivate S4

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity RecelFA is
	port(
		
	   -- the FPGA board
		clk_50	: in std_logic; 	
		reset_sw  : in std_logic; 	
		LED_SD_Error	: out std_logic; 	
		LED1		: out std_logic; 	
		LED2		: out std_logic; 	
		S3  : in std_logic; 			
		S6  : in std_logic; 	
		tone : out std_logic; 	
		
		-- integrated sound
		DFP_Busy : in std_logic; 
		DFP_TX	: out std_logic; 
		DFP_RX	: in std_logic; 
		
		-- SPI FRAM & SD card
		MOSI_FRAM			: 	buffer 	std_logic;
		MISO_FRAM			: 	in 	std_logic;
		SPI_CLK_FRAM			: 	buffer 	std_logic;
		CS_FRAM	: 	buffer 	std_logic;
		
		-- SD card
		MOSI_SDCard			: 	out 	std_logic;
		MISO_SDCard			: 	in 	std_logic;
		SPI_CLK_SDCard			: 	out 	std_logic;
		CS_SDcard	: 	buffer 	std_logic; 						
				
		--dips 		
		Dip_Sw_Ret		: in 	std_logic;
		
		-- driver control
		E_DISPLAY_IC_N			: 	out 	std_logic;
		E_DRIVER_IC_N			: 	out 	std_logic;
		
		-- USB serial CH340
		USB_Rx			: 	buffer 	std_logic;
		USB_Tx			: 	in 	std_logic;
		
		----------------------
		-- Recel
		----------------------
		--Sound
		Sound_10			: 	buffer 	std_logic;
		Sound_100		: 	buffer 	std_logic;
		Sound_1K			: 	buffer 	std_logic;
		Sound_10K		: 	buffer 	std_logic;
		Sound_100K		: 	buffer 	std_logic;
		--CPU
		DOA: buffer 	std_logic_vector(3 downto 0);
		DIA: in 	std_logic_vector(3 downto 0);
		--Display
		Disp_DA: out 	std_logic_vector(3 downto 0);
		Disp_DB: out 	std_logic_vector(3 downto 0);
		Disp_X: out 	std_logic_vector(7 downto 0);
		Disp_DBS	: 	out 	std_logic;
		Disp_Enable	: 	out 	std_logic;
		--Driver
		Coil: out 	std_logic_vector(7 downto 0); -- coils #F,#E,#D,#C,#B,#A,#9,#8		
		COIL_Ball_Home	: 	out 	std_logic; -- #7
		COIL_Knocker	: 	out 	std_logic; -- #6
		Bonus: out 	std_logic_vector(3 downto 0);
		Expander_MX_DR	: 	out 	std_logic;
		Play_Signal	: 	out 	std_logic;
		Rejector_Control	: 	out 	std_logic;
		-- Lights
		Lite_Double_Bonus	: 	out 	std_logic;
		Lite_Extra_Ball	: 	out 	std_logic;
		Lite_Special	: 	out 	std_logic;
		Lite_21	: 	out 	std_logic;
		Lite_31	: 	out 	std_logic;
		Lite_32	: 	out 	std_logic;
		Lite_34	: 	out 	std_logic;
		Lite_38	: 	out 	std_logic;
		Lite_41	: 	out 	std_logic;
		Lite_42	: 	out 	std_logic;
		Lite_44	: 	out 	std_logic;
		Lite_48	: 	out 	std_logic;
		Lite_51	: 	out 	std_logic;
		Lite_52	: 	out 	std_logic;
		Lite_54	: 	out 	std_logic;
		Lite_58	: 	out 	std_logic
		
		
		);
end RecelFA;


architecture rtl of RecelFA is

signal cpu_clk		: std_logic; -- 400 kHz CPU clock
signal reset_l	 	: std_logic := '0';
signal boot_phase	: 	std_logic_vector(3 downto 0) := "0000";
signal uart_clk		: std_logic; -- 9600 Baud 

-- CPU PPS4/2
signal cpu_addr		: std_logic_vector(11 downto 0);
signal cpu_din			: std_logic_vector(7 downto 0);
signal cpu_w_io		: std_logic := '1';

signal io_data : std_logic_vector( 3 downto 0); -- data from IO device
signal io_data_B1 : std_logic_vector( 3 downto 0); -- data from IO device B1
signal io_data_B2 : std_logic_vector( 3 downto 0); -- data from IO device B2
signal io_data_B3 : std_logic_vector( 3 downto 0); -- data from IO device b3
signal io_data_B5 : std_logic_vector( 3 downto 0); -- data from IO device B5
signal io_cmd  : std_logic_vector( 3 downto 0); -- cmd to IO device
signal io_device    : std_logic_vector( 3 downto 0); -- ID of IO device
signal io_accu    : std_logic_vector( 3 downto 0); -- accu for input to IO device
signal io_port    : std_logic_vector( 3 downto 0); -- port of IO device (BL)

signal cpu_di_a		: std_logic_vector(3 downto 0);
signal cpu_di_b		: std_logic_vector(3 downto 0);
signal cpu_do_a		: std_logic_vector(3 downto 0);
signal cpu_do_b		: std_logic_vector(3 downto 0);


-- ROMs
signal B1_rom_dout  : std_logic_vector(7 downto 0);
signal B2_rom_dout 	: std_logic_vector(7 downto 0);
signal Game_rom_dout 	: std_logic_vector(7 downto 0);

-- address decoding helper
signal B1_rom_cs		: std_logic;
signal B2_rom_cs		: std_logic;
signal Game_rom_cs		: std_logic;

-- IO devices
signal B1_cs		: std_logic;
signal B2_cs		: std_logic;
signal B3_cs		: std_logic;
signal B5_cs		: std_logic;

-- address decoding helper
signal B1_rom_addr	:  std_logic_vector(9 downto 0);
signal B2_rom_addr	:  std_logic_vector(9 downto 0);
signal Game_rom_addr	:  std_logic_vector(10 downto 0);

-- SD card
signal address_sd_card	:  std_logic_vector(13 downto 0);
signal data_sd_card	:  std_logic_vector(7 downto 0);
signal wr_rom			:  std_logic;
signal wr_B1_rom			:  std_logic;
signal wr_B2_rom			:  std_logic;
signal wr_Game_rom			:  std_logic;
signal SDcard_MOSI	:	std_logic; 
signal SDcard_CLK		:	std_logic; 
signal SDcard_error	:	std_logic; 

-- displays
signal game_group_A : std_logic_vector(3 downto 0);
signal game_group_B : std_logic_vector(3 downto 0);
signal game_X : std_logic_vector(7 downto 0);
signal game_DBS : std_logic;

-- boot message
signal bm_group_A : std_logic_vector(3 downto 0);
signal bm_group_B : std_logic_vector(3 downto 0);
signal bm_X : std_logic_vector(7 downto 0);
signal bm_DBS : std_logic;

-- init & boot message helper
signal g_dig0					:  std_logic_vector(3 downto 0);
signal g_dig1					:  std_logic_vector(3 downto 0);
signal o_dig0					:  std_logic_vector(3 downto 0);
signal o_dig1					:  std_logic_vector(3 downto 0);

-- dip games select and options
signal game_select 		:  std_logic_vector(5 downto 0);				
signal game_option		: 	std_logic_vector(6 downto 1);
signal dipstrobe		:  std_logic_vector(11 downto 0);

-- HM6508
signal counter_clk :  std_logic;  -- 4040
signal counter_clr :  std_logic;  -- 4040
signal HM6508_addr : std_logic_vector(9 downto 0);
signal HM6508_din :  std_logic;
signal HM6508_wr :  std_logic;
signal HM6508_dout :  std_logic;
signal HM6508_enable :  std_logic;

-- cmos ram
signal ram_addr	: 	std_logic_vector(9 downto 0);
signal fram_addr	: 	std_logic_vector(7 downto 0);
signal ram_data	: 	std_logic_vector(0 downto 0);
signal fram_data	: 	std_logic_vector(3 downto 0);
signal ram_wren 	:  std_logic;
signal fram_wren 	:  std_logic;
signal ram_dout	: 	std_logic_vector(0 downto 0);
signal fram_dout	: 	std_logic_vector(3 downto 0);
signal fram_trigger 	:  std_logic;		
		
		
-- others
signal GameOn :  std_logic := '0';
signal int_coil_7 :  std_logic;
signal int_Lite_41 :  std_logic;
signal int_Lite_44 :  std_logic;
signal int_Lite_48 :  std_logic;
signal int_Lite_51 :  std_logic;
signal int_Lite_52 :  std_logic;
signal int_Lite_54 :  std_logic;
signal int_Lite_58 :  std_logic;
signal int_bonus : std_logic_vector(3 downto 0);

-- SW version
constant SW_MAIN : std_logic_vector(3 downto 0) := x"0";
constant SW_SUB1 : std_logic_vector(3 downto 0) := x"4";
constant SW_SUB2 : std_logic_vector(3 downto 0) := x"0";

begin

--Debug
--RTH

-- switches
--coil(0) <= DOA(3); --D21
--coil(1) <= DOA(2); --D19
--coil(2) <= DOA(1); -- D17
--coil(3) <= DOA(0); -- D16
--
--coil(4) <= cpu_di_a(0); --CLK1
--COIL_Knocker <= cpu_di_a(1);--D25
--coil(5) <= cpu_di_a(2); --D14
--coil(6) <= cpu_di_a(3); -- D12
--

--display tilt & match
--coil(3 downto 0) <= game_group_A; --D21, D19, D17, D16
--coil(4) <= game_DBS; --CLK1
--coil(5) <= game_X(0); --D14
--coil(6) <= game_X(1); -- D12


-- cmos
--coil(0) <= not HM6508_enable; --D21
--coil(1) <= HM6508_dout; --D19
--coil(2) <= not HM6508_wr; -- D17
--coil(3) <= HM6508_din; -- D16
--coil(4) <= '1' when io_cmd = x"D" else '0'; --CLK1
--coil(5) <= '1' when cpu_addr = x"800" else '0'; --D14
--coil(6) <= B3_cs; --USB_Rx; -- D12

--sound
--coil(0) <= Sound_10; --D21
--coil(1) <= sound_100; --D19
--coil(2) <= sound_1K; -- D17
--coil(3) <= sound_10K; -- D16
--coil(4) <= sound_100K; --CLK1

-- IO
--coil(0) <= not io_accu(3); --D21
--coil(1) <= not io_accu(2); --D19
--coil(2) <= not io_accu(1); -- D17
--coil(3) <= not io_accu(0); -- D16
--coil(4) <= io_cmd(3); --CLK1
--coil(5) <= io_cmd(1); --D14
--coil(6) <= io_cmd(0); -- D12
--COIL_Knocker <= io_cmd(2);--D25
--COIL_Ball_Home <= '1' when io_device = x"D" else '0'; -- D23

-- Init
LED1 <= not ( Sound_10 or Sound_100 or Sound_1K or Sound_10K or Sound_100K ); -- visualize sounds
LED2 <=  not GameOn; 
LED_SD_Error <= SDcard_error;

-----------------
--Trigger write to fram
------------------
fram_trigger <= '1' when hm6508_addr = x"3FF" else '0'; --

-----------------
--Switches
------------------
cpu_di_a <= DIA; --DIA checked OK (same as org CPU) but no attract mode, need to negate?
--cpu_di_a <= not DIA;
--cpu_di_a <= "1111";
cpu_di_b <= "1111";
DOA <= cpu_do_a; --DOA checked OK!


--cpu_di_a(0) <= not DIA(3);
--cpu_di_a(1) <= not DIA(2);
--cpu_di_a(2) <= not DIA(1);
--cpu_di_a(3) <= not DIA(0);

-----------------
--Start values, to be adapted later
------------------
E_DISPLAY_IC_N		<= '0';
DISp_Enable 		<=  '0';
-- RecelFA neds option to boot on the desk with nothing connected ??
--cpu_di_a <= not DIA when S3 = '1' else "1111"; --RTH debug

 

-- integrated sound
-- DFP_Busy : in std_logic; 
DFP_TX	<= '0';
-- DFP_RX	: in std_logic; 


-----------------
--boot phases
------------------
reset_l <= boot_phase(3);
-----------------------------------------------
-- phase 0: activated by switch on FPGA board	
-- show (own) boot message
-- read first time dip settings which sets boot phase 1
-----------------------------------------------
META1: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => reset_sw,
	o_Q => boot_phase(0),
   i_Fast_Clk => clk_50
	); 
		
-----------------------------------------------
-- phase 2: activated by init
-- activate boot message
-- read first time dip settings which sets boot phase 1
-----------------------------------------------

-- display bm switch, switch to game in boot phase 2
Disp_DA <= bm_group_A when boot_phase(3) = '0' else game_group_A;
Disp_DB <= bm_group_B when boot_phase(3) = '0' else game_group_B;
Disp_X <= bm_x when boot_phase(3) = '0' else game_X;
Disp_DBS <= bm_DBS when boot_phase(3) = '0' else game_DBS;

					
BM: entity work.boot_message
port map(
	clk		=> clk_50, 	
	-- Control/Data Signals,
   reset  => boot_phase(0),  
	--show error
	is_error => SDcard_error, --active low
	-- output
	group_A   => bm_group_A,
	group_B   => bm_group_B,
		  
	X   => bm_X,
	DBS => bm_DBS,

	-- input (display data)
	display1	=> ( SW_MAIN,SW_SUB1,SW_SUB2,x"F",x"F" ),
	display2	=> ( g_dig1, g_dig0, x"F",x"F",x"F" ),
	display3	=> ( o_dig1, o_dig0, x"F",x"F",x"F" ),
	display4	=> ( x"5",x"0",x"9",x"6",x"3" ),
   error_display4 => ( x"F",x"5",x"6",x"F", x"F")
	);

	
Lite_58 <= dipstrobe(0) when boot_phase(2) = '0' else int_Lite_58;
coil(7) <= dipstrobe(1) when boot_phase(2) = '0' else int_coil_7;
Lite_52 <= dipstrobe(2) when boot_phase(2) = '0' else int_Lite_52;
bonus(0) <= dipstrobe(3) when boot_phase(2) = '0' else int_bonus(0); --4
Lite_41 <= dipstrobe(4) when boot_phase(2) = '0' else int_Lite_41;
bonus(1) <= dipstrobe(5) when boot_phase(2) = '0' else int_bonus(1); --3
Lite_44 <= dipstrobe(6) when boot_phase(2) = '0' else int_Lite_44;
bonus(2) <= dipstrobe(7) when boot_phase(2) = '0' else int_bonus(2); --2
Lite_48 <= dipstrobe(8) when boot_phase(2) = '0' else int_Lite_48;
bonus(3) <= dipstrobe(9) when boot_phase(2) = '0' else int_bonus(3);	--1
Lite_54 <= dipstrobe(10) when boot_phase(2) = '0' else int_Lite_54;	
Lite_51 <= dipstrobe(11) when boot_phase(2) = '0' else int_Lite_51;	
--activate driver ICs in boot phase 2
E_DRIVER_IC_N	<= '1' when boot_phase(2) = '0' else '0';
	
RDIPS: entity work.read_the_dips
port map(
	clk_in		=> cpu_clk,
	i_Rst_L  => boot_phase(0),   
	--output 
	game_select	=> game_select,
	game_option	=> game_option,
	-- strobes
	dip_strobe => dipstrobe,
	-- input
	return_sig => Dip_Sw_Ret,
	-- signal when finished
	done	=> boot_phase(1) -- set to '1' when reading dips is done
	);	
---------------------
-- SD card stuff
----------------------
SD_CARD: entity work.SD_Card
port map(
		
	i_clk		=> clk_50,	
	-- Control/Data Signals,
   i_Rst_L  => boot_phase(1), -- first dip read finished
	-- PMOD SPI Interface
   o_SPI_Clk  => SPI_CLK_SDCard,
   i_SPI_MISO => MISO_SDCard,
   o_SPI_MOSI => MOSI_SDCard,
   o_SPI_CS_n => CS_SDcard,	
	-- selection	
	selection => "00" & not game_select,
	-- data
	address_sd_card => address_sd_card,
	data_sd_card => data_sd_card,
	wr_rom => wr_rom,
	-- control CPU & rest of HW
	cpu_reset_l => boot_phase(2),
	-- feedback
	SDcard_error => SDcard_error
);	

-----------------------------------------------
-- phase 2: activated by SD card read
-- read fram, read/write to ram
----------------------
FRAM: entity work.FRAM
port map(
	i_clk => clk_50,
	address_fram	=> Fram_addr,
	data_fram	=> Fram_data,
	wr_ram => Fram_wren,
	q_ram => Fram_dout,
	-- Control/Data Signals,   
	i_Rst_L  => boot_phase(2),
	-- PMOD SPI Interface
   o_SPI_Clk  => SPI_CLK_FRAM,
   i_SPI_MISO => MISO_FRAM,
   o_SPI_MOSI => MOSI_FRAM,
   o_SPI_CS_n => CS_FRAM,
	-- write trigger
	w_trigger(1) => fram_trigger, -- save whenever Recel save
	w_trigger(0) => game_option(5), -- as trigger for testing
	-- init trigger (no read, RAM will be zero)
	i_init_Flag => game_option(1), -- 0 if option Dip1 is set 
	-- signal when finished
	done	=> boot_phase(3) -- set to '1' when first read of eeprom and write to cmos is done
	);	

---------------------
-- count display strobes
-- indicate game running or not
-- set eeprom trigger ??
---------------------
COUNT_STROBES: entity work.count_to_zero
port map(   
   Clock => clk_50,
	clear => reset_l,
	d_in => game_X(0),
	count_a =>"00011111", -- GAME IS RUNNING (we have strobes) 
	count_b =>"111111111", -- eeprom trigger	
	d_out_a => GameOn,
	d_out_b => open
);	

-- Recel3 address map
-- 1st Gen Recel CPU with 1702 eprom
--0x000..0x3FF : A1761-13 B1
--0x400..0x7FF : A1762-13 B2
--0x800..0x8FF : game eprom 1702
--0x900..0x9FF : 1. mirror game eprom 1702
--0xA00..0xAFF : 2. mirror game eprom 1702
--0xB00..0xBFF : 3. mirror game eprom 1702
--0xC00..0xCFF : 4. mirror game eprom 1702 overlapping with mirror B2 ( 0xC00..0xFFF ) !!
--0xD00..0xDFF : 5. mirror game eprom 1702 overlapping with mirror B2 ( 0xC00..0xFFF ) !!
--0xE00..0xEFF : 6. mirror game eprom 1702 overlapping with mirror B2 ( 0xC00..0xFFF ) !!
--0xF00..0xFFF : 7. mirror game eprom 1702 overlapping with mirror B2 ( 0xC00..0xFFF ) !!
--
-- 2nd Gen Recel CPU with 2716 eprom
--0x000..0x3FF : A1761-13 B1
--0x400..0x7FF : first part of 2716 ( at three bytes modified copy of A1762-13 B2)
--0x800..0xBFF : second part of 2716 ( 4 x256Byte identicale blocks )
--0xC00..0xFFF : mirror of first part of 2716


----------------------------------------------------
-- Address decoding here, 
----------------------------------------------------
--0x000..0x3FF : A1761-13
B1_rom_cs	<= '1' when cpu_addr(11 downto 10) = "00" else '0';
--0x400..0x7FF : A1762-13
B2_rom_cs	<= '1' when cpu_addr(11 downto 10) = "01" else '0';
--0x800..0x8FF : game eprom 1702
Game_rom_cs	<= '1' when cpu_addr(11) = '1' else '0';

-- Bus control
cpu_din <= 
B1_rom_dout when B1_rom_cs='1' else
B2_rom_dout when B2_rom_cs='1' else
not Game_rom_dout when Game_rom_cs='1' else 
x"FF";

------------------
-- ROMs ----------
-- moved to RAM, initial 10KByte read from SD
-- one file of 10Kbyte for all Recel Variants
-- address selection	
-- read from SD when wr_rom == 1
-- else map to address room
------------------
					
					
-- content of B1 rom is read from first 1K of SD
wr_B1_rom <= '1' when ((wr_rom='1') and (address_sd_card(13 downto 10) ="0000" )) else '0';
B1_rom_addr <=  --1K
	address_sd_card(9 downto 0) when wr_B1_rom = '1' else
	cpu_addr(9 downto 0);

-- content of B2 rom is read from second 1K of SD
wr_B2_rom <= '1' when ((wr_rom='1') and (address_sd_card(13 downto 10) ="0001" )) else '0';
B2_rom_addr <=  --1K
	address_sd_card(9 downto 0) when wr_B2_rom = '1' else
	cpu_addr(9 downto 0);

-- content of Game rom is read from 2K 
wr_Game_rom <= '1' when ((wr_rom='1') and (address_sd_card(13 downto 11) ="001" )) else '0';
Game_rom_addr <=  -- 2KByte
	address_sd_card(10 downto 0) when wr_Game_rom = '1' else
	not cpu_addr(10 downto 0);
	

--IO decoding for Chips used
B1_cs <= '1' when io_device="0100" and cpu_w_io = '1' else '0'; --0x4 --B1 A2362-13 A1761-13    Access NVRAM HM6508+few output control
B2_cs <= '1' when io_device="0010" and cpu_w_io = '1' else '0'; --0x2 --B2 A2361-13 A1762-13    16 output control 
B3_cs <= '1' when io_device="1101" and cpu_w_io = '1' else '0'; --0xD --B3 11696 General Purpose I/O expander (no datasheet found, assuming it's similar to 10696)
B5_cs <= '1' when io_device="1111" and cpu_w_io = '1' else '0'; --0xF --B5 10788 Display driver


io_data <=
io_data_B1 when B1_cs = '1' else 
io_data_B2 when B2_cs = '1' else
io_data_B3 when B3_cs = '1' else
io_data_B5 when B5_cs = '1' else
x"F";


-- clocks via PLL  
clock_gen: entity work.clk_gen 
port map(   
	inclk0 => clk_50,
	c0	=> cpu_clk, --  400Khz
	c1 => uart_clk -- 115200Hz
);


--B4 11660 Rockwell Parallel Processing System 4-bit CPU (PPS/4-2)
B4: entity work.PPS4 
port map(
	clk     			=> cpu_clk,
	reset   			=> reset_l,
	w_io				=> cpu_w_io,	
	io_cmd			=> io_cmd,
	io_data			=> io_data,
	io_device		=> io_device,
	io_accu			=> io_accu,
	io_port			=> io_port,
	d_in    			=> cpu_din,	
	addr				=> cpu_addr,
	di_a				=> cpu_di_a,
	di_b				=> cpu_di_b,
	do_a				=> cpu_do_a,
	do_b				=> open, --cpu_do_b,
	accu_debug => open
	);

--B3 11696 General Purpose I/O expander
B3_IO: entity work.r11696
port map(
		  clk => clk_50,
        reset  => reset_l,
        device_id   => "1101", -- B3 has ID 0xD
		  w_io   => cpu_w_io,
		  		  
		  io_data => io_data_B3,
		  
		  io_device  => io_device,
		  io_cmd   => io_cmd,
		  io_accu  => io_accu,
		  		  
		  sound_and_coils_out(0) => sound_10, --IO6-8
		  sound_and_coils_out(1) => sound_100, --IO6-4
		  sound_and_coils_out(2) => sound_1K, --IO6-2
		  sound_and_coils_out(3) => sound_10K, --IO6-1
		  sound_and_coils_out(4) => sound_100K, --IO5-8
		  
		  sound_and_coils_out(5) => open,
		  sound_and_coils_out(6) => COIL_Knocker, --open, --RTH for DEBUG 
		  sound_and_coils_out(7) => COIL_Ball_Home,
		  sound_and_coils_out(14 downto 8) => Coil(6 downto 0), --open, --RTH for DEBUG 
		  sound_and_coils_out(15) => int_coil_7,
		  
		  group_7_out(0) => int_bonus(3),
		  group_7_out(1) => int_bonus(2),
		  group_7_out(2) => int_bonus(1),
		  group_7_out(3) => int_bonus(0),
		  
		  group_8_out(0) => Lite_Special,
		  group_8_out(1) => Lite_Extra_Ball,
		  group_8_out(2) => Lite_Double_Bonus,
		  group_8_out(3) => Play_Signal

	);		

		
B1_ROM: entity work.B1_ROM -- B1 System ROM 1KByte
port map(
	address	=> B1_rom_addr,
	clock		=> clk_50, 
	data => data_sd_card,
	wren => wr_B1_rom,		
	q			=> B1_rom_dout
	);	
	
B2_ROM: entity work.B2_ROM -- B2 System ROM 1KByte
port map(
	address	=> B2_rom_addr,
	clock		=> clk_50, 
	data => data_sd_card,
	wren => wr_B2_rom,		
	q			=> B2_rom_dout
	);	
	

--0x4 --B1 A1761-13    Access NVRAM HM6508+few output control I/O is input
B1_IO: entity work.rA1761
port map(
		  clk => clk_50,
        reset  => reset_l,
        device_id   => "0100", -- B1 has ID 0x4
		  w_io   => cpu_w_io,
		  		  
		  io_data => io_data_B1,
		  
		  io_device  => io_device,
		  io_cmd   => io_cmd,
		  
		  io_accu  => io_accu,
		  io_port => io_port,
		  
		  io_port_in(0) => HM6508_dout,   --inverter on CPU but different logik ? RTH
		  io_port_in(15 downto 1)  => "111111111111111", --"0000000000000000",		  
		  io_port_out(0) => open,
		  io_port_out(1) => HM6508_din,
		  io_port_out(2) => HM6508_enable,
		  io_port_out(3) => HM6508_wr,
		  io_port_out(4) => counter_clk,
		  io_port_out(5) => counter_clr,
		  io_port_out(8 downto 6) => open,
		  io_port_out(9) => Expander_MX_DR,
		  io_port_out(13 downto 10) => open,
		  io_port_out(14) => Rejector_Control,
		  io_port_out(15) => open

	);	

--0x2 --B2 A1762-13    16 output control 
B2_IO: entity work.rA17xx 
port map(
		  clk => clk_50,
        reset  => reset_l,
        device_id   => "0010", -- B2 has ID 0x2
		  w_io   => cpu_w_io,
		  		  
		  io_data => io_data_B2,
		  
		  io_device  => io_device,
		  io_cmd   => io_cmd,
		  
		  io_accu  => io_accu,
		  io_port => io_port,
		  
		  io_port_in(15 downto 0)  => "0000000000000000",
		  io_port_out(15) => open, --Lite_28,
		  io_port_out(14) => open, --Lite_24,
		  io_port_out(13) => open, --Lite_22,
		  io_port_out(12) => Lite_21,
		  io_port_out(11) => Lite_38,
		  io_port_out(10) => Lite_34,
		  io_port_out(9) => Lite_32,
		  io_port_out(8) => Lite_31,
		  io_port_out(7) => int_Lite_48,
		  io_port_out(6) => int_Lite_44,
		  io_port_out(5) => Lite_42,
		  io_port_out(4) => int_Lite_41,
		  io_port_out(3) => int_Lite_58,
		  io_port_out(2) => int_Lite_54,
		  io_port_out(1) => int_Lite_52,
		  io_port_out(0) => int_Lite_51
	);	
	

--B5 10788 Display driver
B5_IO: entity work.r10788
port map(
		  clk => clk_50,
        reset  => reset_l,
        device_id   => "1111", -- B5 has ID 0xF
		  w_io   => cpu_w_io,
		  		  
		  io_data => io_data_B5, 
		  
		  io_device  => io_device,
		  io_cmd   => io_cmd,
		  io_accu  => io_accu,
		  		  
		  group_A => game_group_A,
		  group_B => game_group_B,
		  
		  X => game_X,
		  DBS => game_DBS
	);	
	

GAME_ROM: entity work.Game_ROM -- Game ROM 256Byte
port map(
	address	=> Game_rom_addr, 
	clock		=> clk_50, 
	data => data_sd_card,
	wren => wr_Game_rom,		
	q			=> Game_rom_dout
	);	

	
-- write and enable via inverter on CPU	
HM6508: entity work.HM6508 
port map(	
	clk		=> clk_50, 
	reset => reset_l,	
	enable_n => not HM6508_enable,
	addr	=> HM6508_addr,
	data_in => HM6508_din,
	data_out => HM6508_dout,
	write_enable_n => not HM6508_wr,
	--
	address => ram_addr,
	ram_out => ram_data,
	wren => ram_wren,
	ram_in => ram_dout
	);	
	
----------------------
-- HM6508 ram (dual port)
----------------------
HM6508_RAM: entity work.HM6508_RAM -- 1024 x 1bit & 256 x 4bit
	port map(
		address_a	=> ram_addr,
		address_b   => fram_addr,
		clock			=> clk_50,
		data_a		=> ram_data,
		data_b		=> fram_data,
		wren_a 		=> ram_wren,
		wren_b 		=> fram_wren,
		q_a			=> ram_dout,
		q_b			=> fram_dout
);
	
	
-- clear via inverter on CPU		
COUNTER4040: entity work.Counter_74HC4040 
port map(
	CLK => counter_clk,
	CLR => not counter_clr,
	Q(9 downto 0) => HM6508_addr
	);	

-- generate tones via FPGA
GENTONES: entity work.gentones
port map(
	hiclk => clk_50,	
   tonesel(0) => Sound_10,
	tonesel(1) => Sound_100,
	tonesel(2) => Sound_1K,
	tonesel(3) => Sound_10K,
	tonesel(4) => Sound_100K,
   soundout => open
	);	
	
	
-- for game select to visiualize
CONVG: entity work.byte_to_decimal
port map(
	clk_in	=> clk_50, 	
	mybyte	=> "11" & game_select,
	dig0 => g_dig0,
	dig1 => g_dig1,
	dig2 => open
	);
	
-- for RecelFA option to visiualize
CONVO: entity work.byte_to_decimal
port map(
	clk_in	=> clk_50, 	
	mybyte	=> "11" & game_option,
	dig0 => o_dig0,
	dig1 => o_dig1,
	dig2 => open
	);	

-- send on char (test)
uart_send: entity work.uart_send
port map(   
	clk => uart_clk,
	rst => reset_l,
	txd => USB_Rx,
	char_to_send => x"4C", -- 'L'
	send_flag => not S3
);

end rtl;
		

