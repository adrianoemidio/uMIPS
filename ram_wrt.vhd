LIBRARY IEEE; 
USE IEEE.STD_LOGIC_1164.ALL; 
USE IEEE.STD_LOGIC_ARITH.ALL; 
USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
USE IEEE.NUMERIC_STD.ALL;

ENTITY ram_wrt IS
	PORT(
			w_data		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			w_addr		: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
			ram_addr		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			write_en		: OUT STD_LOGIC;
			m_sel			: IN STD_LOGIC;
			clk			: IN STD_LOGIC;
			update		: IN STD_LOGIC;
			MenWrite		: IN STD_LOGIC;
			Zero			: IN STD_LOGIC;
			Jump			: IN STD_LOGIC;
			PCAddr		: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			readData1	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			readData2	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			DataInstr	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			ALU_result	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			ram_data		: IN STD_LOGIC_VECTOR(31 DOWNTO 0));

END ram_wrt;

ARCHITECTURE arch OF ram_wrt IS
	
	--Register and bit and column counters
	SIGNAL reg_cnt : STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL bit_cnt : STD_LOGIC_VECTOR(2 DOWNTO 0);
	
	--Write Enable signal
	SIGNAL we : STD_LOGIC;
	
	--CPU Status Write address
	SIGNAL addr_cpu : STD_LOGIC_VECTOR(11 DOWNTO 0) := X"000";
	
	--RAM Status Write address
	SIGNAL addr_ram : STD_LOGIC_VECTOR(11 DOWNTO 0);
		
	--Write data
	SIGNAL data : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	--Signal to register selected
	SIGNAL reg 		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL reg_cpu	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL reg_mem : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	--Signal to covert digit
	SIGNAL digit : STD_LOGIC_VECTOR(3 DOWNTO 0);
	

BEGIN	
	
-- Output
	w_data <= data;
	w_addr <= addr_ram WHEN m_sel = '0' ELSE addr_cpu;
	write_en <= we;
	
	--Vram addr for cpu status
	addr_cpu(4 DOWNTO 0)		<=	("10001" + bit_cnt);
	addr_cpu(5)					<=	'0';
	addr_cpu(6)					<= '0';
	addr_cpu(10 DOWNTO 7)	<= ("0100" + reg_cnt(2 DOWNTO 0));
	addr_cpu(11) 				<= '0';
	
	-- VRAM addr for ram status
	--addr_ram(7 DOWNTO 0)	<= X"00" + ("00000" & bit_cnt) + ("000" & reg_cnt & "0") + ('0' & reg_cnt & "000");
	--addr_ram(11 DOWNTO 8)	<= "000" & reg_cnt(3);
	
	addr_ram(5 DOWNTO 0)	<= (bit_cnt) +(reg_cnt(1 DOWNTO 0) & "000") + ("000" & reg_cnt(1 DOWNTO 0) & '0');
	addr_ram(9 DOWNTO 6) <= (reg_cnt(4 DOWNTO 2) & '0');
	addr_ram(11 DOWNTO 10)	<= "10";
	
	--Extenal RAM address
	ram_addr <= ("000" & reg_cnt);
	
PROCESS
	BEGIN
		WAIT UNTIL clk'EVENT AND clk = '1';

			IF update = '1' THEN
					--Reset counters
					reg_cnt 	<=  "00000";
					bit_cnt 	<=  "000";
					we			<=	 '0';
			ELSE
		
				--Enable white
				we <= '1';
		
				IF m_sel = '1' THEN
				
					--Updade counter reg_cnt = 3 bits
					IF ( bit_cnt = 7 ) THEN 
						bit_cnt <= "000"; 
						IF ( reg_cnt < 7 ) THEN
							reg_cnt <= reg_cnt + 1;
						ELSE
							reg_cnt <=	"00000";
						END IF;
					ELSE 
						bit_cnt <= bit_cnt + 1; 
					END IF; 
			
				ELSE	
					--Updade counter reg_cnt = 4 bits
					IF ( bit_cnt = 7 ) THEN 
						bit_cnt <= "000"; 
						reg_cnt <= reg_cnt + 1;
					ELSE 
						bit_cnt <= bit_cnt + 1; 
					END IF;
				END IF;
			
			END IF;
END PROCESS;

	
	--convert 4 bits to hex char
	WITH digit SELECT
		data <=	X"30" WHEN "0000", -- 0
					X"31" WHEN "0001", -- 1		
					X"32" WHEN "0010", -- 2
					X"33" WHEN "0011", -- 3
					X"34" WHEN "0100", -- 4
					X"35" WHEN "0101", -- 5
					X"36" WHEN "0110", -- 6
					X"37" WHEN "0111", -- 7
					X"38" WHEN "1000", -- 8
					X"39" WHEN "1001", -- 9		
					X"41" WHEN "1010", -- A
					X"42" WHEN "1011", -- B
					X"43" WHEN "1100", -- C
					X"44" WHEN "1101", -- D
					X"45" WHEN "1110", -- E
					X"46" WHEN "1111", -- F
					X"00" WHEN OTHERS;
					
	
	--Select digit
	WITH bit_cnt SELECT
		digit <= reg(3 DOWNTO 0)   WHEN "111",
					reg(7 DOWNTO 4)   WHEN "110",		
					reg(11 DOWNTO 8)  WHEN "101",
					reg(15 DOWNTO 12) WHEN "100",
					reg(19 DOWNTO 16) WHEN "011",
					reg(23 DOWNTO 20) WHEN "010",
					reg(27 DOWNTO 24) WHEN "001",
					reg(31 DOWNTO 28) WHEN "000",
					reg(31 DOWNTO 28) WHEN OTHERS;
	
	--Select CPU data ou memory data
	reg <= reg_mem WHEN m_sel = '0' ELSE reg_cpu;
	
	--Ram data read
	reg_mem <= ram_data;
	
	--Select CPU regsiter
	WITH reg_cnt(3 DOWNTO 0) SELECT
		reg_cpu <= 	PCAddr								WHEN "0000",
					DataInstr								WHEN "0001",		
					ReadData1								WHEN "0010",
					ReadData2								WHEN "0011",
					ALU_result								WHEN "0100",
					(X"0000000" & "000" & Zero)		WHEN "0101",
					(X"0000000" & "000" & Jump)		WHEN "0110",
					(X"0000000" & "000" & MenWrite)	WHEN "0111",
					X"00000000"								WHEN OTHERS;


END arch;