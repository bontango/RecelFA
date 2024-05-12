--
-- HM6508.vhd 
-- cmos 1024x1bit 
-- read/write fram chip FM25CL64B
-- for RecelFA
-- bontango 04.2024
--
--
-- fix SPI mode : C remains at 0 for (CPOL=0, CPHA=0)
--
-- v 0.1




library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity HM6508_RAM is
    Port (
        i_clk : in STD_LOGIC;		  
		  i_Rst_L : in std_logic;     -- FPGA Reset		
        addr : in STD_LOGIC_VECTOR(9 downto 0);
        data_in : in STD_LOGIC;
        data_out : out STD_LOGIC;
        write_enable_n : in STD_LOGIC;
        enable_n : in STD_LOGIC;
		  	-- SPI Interface
			o_SPI_Clk  : out STD_LOGIC;
			i_SPI_MISO : in STD_LOGIC;
			o_SPI_MOSI : out STD_LOGIC;
			o_SPI_CS_n : out STD_LOGIC
    );
end HM6508_RAM;

architecture Behavioral of HM6508_RAM is
		type STATE_T is ( Check_en, send_read_request, wait_for_read,								
								send_write_request, 	wait_for_Write_done,
								write_enable, wait_for_Cmd_done ); 				
		signal state : STATE_T;       		
								
		-- SPI stuff				
		signal TX_Data_W : std_LOGIC_VECTOR ( 31 downto 0); -- 4 Bytes ( 3 cmd plus 1 Data) 32bits
		signal RX_Data_W : std_LOGIC_VECTOR ( 31 downto 0);
		signal TX_Start_W : std_LOGIC;
		signal TX_Done_W : std_LOGIC;
		signal MOSI_W : std_LOGIC;
		signal SS_W :  std_LOGIC;
		signal SPI_Clk_W :  std_LOGIC;

		signal TX_Data_R : std_LOGIC_VECTOR ( 31 downto 0); -- 4 Bytes ( 3 cmd plus 1 Data) 32bits
		signal RX_Data_R : std_LOGIC_VECTOR ( 31 downto 0);
		signal TX_Start_R : std_LOGIC;
		signal TX_Done_R : std_LOGIC;
		signal MOSI_R : std_LOGIC;
		signal SS_R :  std_LOGIC;
		signal SPI_Clk_R :  std_LOGIC;
		
		signal TX_Data_Stat : std_LOGIC_VECTOR ( 15 downto 0); -- 2 Bytes ( 1 cmd plus 1 status)
		signal RX_Data_Stat : std_LOGIC_VECTOR ( 15 downto 0);
		signal TX_Start_Stat : std_LOGIC;
		signal TX_Done_Stat : std_LOGIC;
		signal MOSI_Stat : std_LOGIC;
		signal SS_Stat :  std_LOGIC;
		signal SPI_Clk_Stat :  std_LOGIC;

		signal TX_Data_Cmd : std_LOGIC_VECTOR ( 7 downto 0); -- 1 Byte data
		signal RX_Data_Cmd : std_LOGIC_VECTOR ( 7 downto 0);
		signal TX_Start_Cmd : std_LOGIC;
		signal TX_Done_Cmd : std_LOGIC;
		signal MOSI_Cmd : std_LOGIC;
		signal SS_Cmd :  std_LOGIC;
		signal SPI_Clk_Cmd :  std_LOGIC;
					
		-- we react to edges of triggers, so we need to remember
		signal old_write_enable_n :  std_LOGIC;
		signal old_enable_n : std_LOGIC;
		signal latched_addr : STD_LOGIC_VECTOR(9 downto 0);

begin

	-- signals for the four SPI Master
	o_SPI_MOSI <=	
	MOSI_R when TX_Start_R = '1' else
	MOSI_W when TX_Start_W = '1' else
	MOSI_Stat when TX_Start_Stat = '1' else
	MOSI_Cmd when TX_Start_Cmd = '1' else
	'0';

	o_SPI_Clk <=
	SPI_Clk_R when TX_Start_R = '1' else
	SPI_Clk_W when TX_Start_W = '1' else
	SPI_Clk_Stat when TX_Start_Stat = '1' else
	SPI_Clk_Cmd when TX_Start_Cmd = '1' else
	'0';

	o_SPI_CS_n <=
	SS_R when TX_Start_R = '1' else
	SS_W when TX_Start_W = '1' else
	SS_Stat when TX_Start_Stat = '1' else
	SS_Cmd when TX_Start_Cmd = '1' else
	'1';


EEPROM_WRITE: entity work.SPI_Master
    generic map (      
      Laenge => 32)
    port map (
			  TX_Data  => TX_Data_W,
           RX_Data  => RX_Data_W,
           MOSI     => MOSI_W,
           MISO     => i_SPI_MISO,
           SCLK     => SPI_Clk_W,
           SS       => SS_W,
           TX_Start => TX_Start_W,
           TX_Done  => TX_Done_W,
           clk      => i_Clk,
			  do_not_disable_SS => '0',
			  do_not_enable_SS => '0'
      );
		
EEPROM_READ: entity work.SPI_Master
    generic map (      
      Laenge => 32)
    port map (
			  TX_Data  => TX_Data_R,
           RX_Data  => RX_Data_R,
           MOSI     => MOSI_R,
           MISO     => i_SPI_MISO,
           SCLK     => SPI_Clk_R,
           SS       => SS_R,
           TX_Start => TX_Start_R,
           TX_Done  => TX_Done_R,
           clk      => i_Clk,
			  do_not_disable_SS => '0',
			  do_not_enable_SS => '0'
      );

EEPROM_STAT: entity work.SPI_Master
    generic map (      
      Laenge => 16)
    port map (
			  TX_Data  => TX_Data_Stat,
           RX_Data  => RX_Data_Stat,
           MOSI     => MOSI_Stat,
           MISO     => i_SPI_MISO,
           SCLK     => SPI_Clk_Stat,
           SS       => SS_Stat,
           TX_Start => TX_Start_Stat,
           TX_Done  => TX_Done_Stat,
           clk      => i_Clk,
			  do_not_disable_SS => '0',
			  do_not_enable_SS => '0'
      );

EEPROM_CMD: entity work.SPI_Master
    generic map (      
      Laenge => 8)
    port map (
			  TX_Data  => TX_Data_Cmd,
           RX_Data  => RX_Data_Cmd,
           MOSI     => MOSI_Cmd,
           MISO     => i_SPI_MISO,
           SCLK     => SPI_Clk_Cmd,
           SS       => SS_Cmd,
           TX_Start => TX_Start_Cmd,
           TX_Done  => TX_Done_Cmd,
           clk      => i_Clk,
			  do_not_disable_SS => '0',
			  do_not_enable_SS => '0'
      );

FRAM: process (i_Clk, i_Rst_L, enable_n, write_enable_n)
			begin
			if i_Rst_L = '0' then --Reset condidition (reset_l)    
				TX_Start_R <= '0';				
				TX_Start_W <= '0';				
				TX_Start_Cmd <= '0';				
				TX_Start_Stat <= '0';	
				old_write_enable_n <= '1';
				old_enable_n <= '1';				
				state <= Check_en;
				
			elsif rising_edge(i_Clk) then
				case state is
				-- STATE MASCHINE ----------------
				when Check_en =>
				   --read enable signals and react
					if (( enable_n = '0') and ( old_enable_n = '1')) then
						latched_addr <= addr;
						old_enable_n <= '0';
						state <= send_read_request;
					-- back from read, reset flag
					elsif (( enable_n = '1') and ( old_enable_n = '0')) then	
						old_enable_n <= '1';					
					--write request
					elsif (( write_enable_n = '0') and ( old_write_enable_n = '1')) then
						old_write_enable_n <= '0';
						state <= send_write_request;										
					-- back from write, reset flag	
					elsif (( write_enable_n = '1') and ( old_write_enable_n = '0')) then
						old_write_enable_n <= '1';					
					end if;
					
				when send_read_request =>					
					TX_Data_R(31 downto 24) <= "00000011"; -- cmd read from memory array
					-- construct the address, we have 8KByte available -> 13 bit address
					-- two bytes address to be send
					TX_Data_R(23 downto 8)  <= "000000" & latched_addr;
					TX_Start_R <= '1'; -- set flag for sending byte		
					state <= wait_for_read;					

				when wait_for_read =>											
						if (TX_Done_R = '1') then -- Master sets TX_Done when TX is done ;-)
							TX_Start_R <= '0'; -- reset flag 		
							--put red data to output
							data_out <= RX_Data_R(0); --one bit only
							state <= Check_en;
						end if;
										
				when Write_enable => -- enable writing								
					TX_Data_Cmd <= "00000110"; -- write enable					
					TX_Start_Cmd <= '1'; -- set flag for sending byte											
					state <= wait_for_Cmd_done;					
					
				when wait_for_Cmd_done =>													
					if (TX_Done_Cmd = '1') then				
						TX_Start_Cmd <= '0'; -- reset flag 
						state <= send_write_request;														
					end if;											 
															
				when send_write_request =>
				   --header is write command plus address to write
					TX_Data_W(31 downto 24) <= "00000010"; -- cmd write memory array address 
					-- construct the address, we have 8KByte available -> 13 bit address
					-- two bytes address to be send
					TX_Data_R(23 downto 8)  <= "000000" & latched_addr;
					-- data in
					TX_Data_W ( 7 downto 0 ) <= "0000000" & data_in;
					TX_Start_W <= '1'; -- set flag for sending byte				
					state <= wait_for_Write_done;					
		
				when wait_for_Write_done =>							
						if (TX_Done_W = '1') then							
							TX_Start_W <= '0'; -- reset flag 														
							state <= Check_en;												
						end if;							
						
				end case;	
			end if; --rising edge				
		end process;
end Behavioral;
