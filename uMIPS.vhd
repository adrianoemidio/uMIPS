LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY uMIPS IS
	PORT(	reset					: IN STD_LOGIC;
			clock48MHz			: IN STD_LOGIC;
			LCD_RS, LCD_E		: OUT	STD_LOGIC;
			LCD_RW, LCD_ON		: OUT STD_LOGIC;
			c_sync				: OUT STD_LOGIC;
			h_sync, v_sync		: OUT STD_LOGIC;
			vga_blank			: OUT STD_LOGIC;
			vga_clock			: OUT STD_LOGIC;
			m_sel_in				: IN 	STD_LOGIC;
			red_out 				: OUT STD_LOGIC_VECTOR(9 DOWNTO 0); 
			green_out			: OUT STD_LOGIC_VECTOR(9 DOWNTO 0); 
			blue_out			 	: OUT STD_LOGIC_VECTOR(9 DOWNTO 0); 
			DATA					: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			clockPB				: IN STD_LOGIC;
			InstrALU				: IN STD_LOGIC);
END uMIPS;

ARCHITECTURE exec OF uMIPS IS
COMPONENT LCD_Display
	GENERIC(NumHexDig: Integer:= 11);
	PORT(	reset, clk_48Mhz	: IN	STD_LOGIC;
			HexDspData		: IN  STD_LOGIC_VECTOR((NumHexDig*4)-1 DOWNTO 0);
			LCD_RS, LCD_E		: OUT	STD_LOGIC;
			LCD_RW				: OUT STD_LOGIC;
			DATA_BUS				: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0));
END COMPONENT;

COMPONENT Ifetch
	PORT( rst,clk		: IN STD_LOGIC;
		ADDResult		: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		JumpAddr			: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		JregAddr			: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		PCAddr			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		PC_PLUS_4		: OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
		dataInstr		: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		Jump				: IN 	STD_LOGIC;
		BranchE, Zero	: IN STD_LOGIC;
		BranchNE			: IN STD_LOGIC;
		Jreg				: IN STD_LOGIC); 
END COMPONENT;

COMPONENT Idecode
	  PORT(	read_data_1		: OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				read_data_2		: OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Instruction 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				ALU_result		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				RegWrite 		: IN 	STD_LOGIC;
				RegDst 			: IN 	STD_LOGIC;
				MemToReg			: IN	STD_LOGIC;
				PCToReg			: IN	STD_LOGIC;
				Read_data		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Write_data_out	: OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Jump_immed		: OUT STD_LOGIC_VECTOR( 25 DOWNTO 0 );
				PC_PLUS_4		: IN	STD_LOGIC_VECTOR(9 DOWNTO 0);
				Sign_extend 	: OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				clock,reset		: IN 	STD_LOGIC );

END COMPONENT;

COMPONENT control
   PORT( Opcode 		: IN 		STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			Rcode			: IN		STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			ALUop 		: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			RegDst 		: OUT 	STD_LOGIC;
			MemToReg		: OUT		STD_LOGIC;
			PCToReg		: OUT 	STD_LOGIC;
			MenWrite		: OUT 	STD_LOGIC;
			ALUSrc		: OUT 	STD_LOGIC;
			RegWrite 	: OUT 	STD_LOGIC;
			Jump			: OUT		STD_LOGIC;
			BranchE 		: OUT		STD_LOGIC;
			BranchNE		: OUT		STD_LOGIC;
			JReg			: OUT		STD_LOGIC);
END COMPONENT;

COMPONENT Execute
	PORT(	Read_data_1 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Read_data_2 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Sign_extend		: IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PC_PLUS_4		: IN	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			function_op		: IN	STD_LOGIC_VECTOR( 5 DOWNTO 0 );	
			ALUop				: IN	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			ALUSrc			: IN	STD_LOGIC;
			ALU_Result 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			ADDResult 		: OUT	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			Jump_immed		: IN STD_LOGIC_VECTOR( 25 DOWNTO 0 );
			JumpAddr			: OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			JregAddr			: OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			Zero				: OUT	STD_LOGIC);

END COMPONENT;

COMPONENT dmemory 
	PORT(	read_data 			: OUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
        	address 				: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
        	write_data 			: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
	   	Memwrite				: IN 	STD_LOGIC;
         clock,reset			: IN 	STD_LOGIC );
END COMPONENT;


COMPONENT video  
PORT( clk_50MHz			: IN STD_LOGIC;
		c_sync				: OUT STD_LOGIC;
		red, green, blue 	: OUT STD_LOGIC; 
		h_sync, v_sync		: OUT STD_LOGIC;
		v_on_out				: OUT STD_LOGIC;
		vga_clk				: OUT STD_LOGIC;
		MenWrite				: IN STD_LOGIC;
		Zero					: IN STD_LOGIC;
		Jump					: IN STD_LOGIC;
		m_sel					: IN STD_LOGIC;
		ram_addr				: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		ram_data				: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		PCAddr				: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		readData1			: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		readData2			: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		DataInstr			: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		ALU_result			: IN STD_LOGIC_VECTOR(31 DOWNTO 0));
END COMPONENT;

COMPONENT debounce 
  PORT(
    clk     : IN  STD_LOGIC;  --input clock
    button  : IN  STD_LOGIC;  --input signal to be debounced
    result  : OUT STD_LOGIC); --debounced signal
END COMPONENT;

SIGNAL DataInstr 			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL DisplayData		: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL PCAddr				: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL RegDst				: STD_LOGIC;
SIGNAL RegWrite			: STD_LOGIC;
SIGNAL ALUResult			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SignExtend			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL readData1			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL readData2			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL HexDisplayDT		: STD_LOGIC_VECTOR(43 DOWNTO 0);
SIGNAL clock				: STD_LOGIC;
SIGNAL MemToReg			: STD_LOGIC;
SIGNAL MenWrite			: STD_LOGIC;
SIGNAL ALUSrc				: STD_LOGIC;
SIGNAL Read_data			: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL Write_data_out 	: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL BranchE				: STD_LOGIC;
SIGNAL BranchNE			: STD_LOGIC;
SIGNAL PC_PLUS_4			: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL ADDResult 			: STD_LOGIC_VECTOR( 9 DOWNTO 0 );
SIGNAL Zero					: STD_LOGIC;
SIGNAL ALUop 				: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
SIGNAL Jump					: STD_LOGIC;
SIGNAL JumpAddr			: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL JReg					: STD_LOGIC;
SIGNAL JRegAddr			: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL Jump_immed			: STD_LOGIC_VECTOR(25 DOWNTO 0);
SIGNAL PCToReg				: STD_LOGIC;
SIGNAL clk_d				: STD_LOGIC;
SIGNAL n_rst				: STD_LOGIC;

SIGNAL red					: STD_LOGIC;
SIGNAL green				: STD_LOGIC;
SIGNAL blue					: STD_LOGIC;

SIGNAL ram_addr_sel 		: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL mem_write_sel		: STD_LOGIC;
SIGNAL ram_clk_sel      : STD_LOGIC;

SIGNAL ram_addr_vga		: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL ram_data_vga		: STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL pc_data_vga		: STD_LOGIC_VECTOR(31 DOWNTO 0);


--SIGNAL DispTemp : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
	LCD_ON <= '1';
	--clock <= (NOT(clk_d)) AND m_sel;
	clock <= (NOT(clk_d)) AND m_sel_in;
	
	n_rst <= NOT(reset);
	
	--Multiplexador para selecionar a exibicao dos dados da ram
	ram_addr_sel	<= ram_addr_vga  		WHEN m_sel_in = '0' ELSE ALUResult(7 DOWNTO 0);
	mem_write_sel	<=	'0'			  		WHEN m_sel_in = '0' ELSE MenWrite;
	ram_clk_sel		<= clock48MHz	WHEN m_sel_in = '0' ELSE clock;
	
	HexDisplayDT <= "0000" & PCAddr & DisplayData;
	
	DisplayData <= DataInstr WHEN InstrALU = '1' ELSE Write_data_out;
	
	--PCAddr para a placa de video
	pc_data_vga <= (X"000000" & PCAddr);
	
	
	--Multiplexador para saida de video
	green_out	<= "1111111111" WHEN green = '1' ELSE "0000000000";
	red_out 		<= "0000000000" WHEN red = '1' 	ELSE "0000000000";
	blue_out		<= "0000000000" WHEN blue = '1' 	ELSE "0000000000";
	
	--Sicronismo Separado do canal de cores
	

	lcd: LCD_Display
	PORT MAP(
		reset				=> n_rst,
		clk_48Mhz		=> clock48MHz,
		HexDspData		=> HexDisplayDT,
		LCD_RS			=> LCD_RS,
		LCD_E				=> LCD_E,
		LCD_RW			=> LCD_RW,
		DATA_BUS			=> DATA);
	
	IFT: Ifetch
	PORT MAP(
		rst			=> n_rst,
		clk 			=> clock,
		ADDResult	=> ADDResult,
		JumpAddr		=> JumpAddr,
		JRegAddr		=>	JRegAddr,
		PCAddr		=> PCAddr,
		dataInstr	=> DataInstr, 
		PC_PLUS_4	=> PC_PLUS_4,
		Jump			=> Jump,
		BranchE		=> BranchE,
		Zero			=> Zero,
		BranchNE		=> BranchNE,
		JReg			=> JReg);

	--CTR: Control
	CTR: Control
	PORT MAP(
		Opcode	=> DataInstr(31 DOWNTO 26),
		Rcode		=> DataInstr(5 DOWNTO 0),
		ALUop		=> ALUop,
		RegDst	=> RegDst,
		MemToReg	=> MemToReg,
		PCToReg	=> PCToReg,
		MenWrite => MenWrite,
		ALUSrc	=> ALUSrc,
		RegWrite => RegWrite,
		Jump		=> Jump,
		BranchE	=> BranchE,
		BranchNE => BranchNE,
		JReg		=> JReg);

	--IDEC: Idecode
	IDEC: Idecode
	PORT MAP(
		read_data_1		=> readData1,
		read_data_2		=> readData2,
		Instruction 	=> DataInstr,
		ALU_result		=> ALUResult,
		RegWrite 		=> RegWrite,
		RegDst 			=> RegDst,
		Read_data		=> Read_data,
		Write_data_out => Write_data_out,
		Jump_immed		=> Jump_immed,
		Sign_extend		=> SignExtend,
		PC_PLUS_4		=>	PC_PLUS_4,
		clock 			=> clock,
		MemToReg			=> MemToReg,
		PCToReg			=> PCToReg,
		reset 			=> n_rst);

	--EXE: Execute
	EXE: Execute
	PORT MAP(
		Read_data_1 => readData1,
		Read_data_2 => readData2,
		Sign_extend	=>	SignExtend,
		PC_PLUS_4	=> PC_PLUS_4,
		function_op	=>	DataInstr(5 DOWNTO 0),	
		ALUop			=> ALUop,
		ALUSrc		=> ALUSrc,	
		ALU_Result 	=> ALUResult,
		ADDResult 	=> ADDResult,
		Jump_immed	=> Jump_immed,
		JumpAddr		=> JumpAddr,
		JregAddr		=> JRegAddr,
		Zero			=> Zero);
		
	--MEM: Memory
	MEM : dmemory
	PORT MAP(
			read_data	=> Read_data,
        	address		=> ram_addr_sel,
        	write_data	=> readData2,
	   	Memwrite		=> mem_write_sel,
         clock			=> ram_clk_sel,
			reset			=> n_rst);
	
		--Debounce for push botton
	DEB1: debounce 
	PORT MAP(
			clk		=> clock48MHz,
			button	=> clockPB,
			result	=> clk_d);
	
	
	--VGA Output
	VID: video  
		PORT MAP( clk_50MHz	=> clock48MHz,
				c_sync		=> c_sync,
				red			=> red,
				green			=> green,
				blue			=> blue, 
				h_sync		=> h_sync,
				v_sync		=>	v_sync,
				v_on_out		=> vga_blank,
				vga_clk		=> vga_clock,
				MenWrite		=> MenWrite,
				Zero			=> Zero,
				Jump			=> Jump,
				m_sel			=> m_sel_in,
				ram_addr		=> (ram_addr_vga),
				ram_data		=> Read_data,
				PCAddr		=> pc_data_vga,
				readData1	=> ReadData1,
				readData2	=> ReadData2,
				DataInstr	=> DataInstr,
				ALU_result	=> AluResult);
	
	
END exec;