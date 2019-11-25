--  Execute module
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY  Execute IS
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
			JRegAddr			: OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			Zero				: OUT	STD_LOGIC);
END Execute;

ARCHITECTURE behavior OF Execute IS

	SIGNAL Alu_in2 	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ALU_Mux		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ALU_ctl		: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL R_type_crt	: STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN
	
	--Gera os sinais para ALU Control
					
	--Multiplexador para selecionar entre as diversas isntrucoes tipo R
	WITH function_op SELECT 
			R_type_crt <=	"010" WHEN "100000", -- add
								"110" WHEN "100010", -- sub
								"000" WHEN "100100", -- and
								"001" WHEN "100101", -- or
								"111" WHEN "101010", -- slt
								"100" WHEN "000000", -- sll
								"101" WHEN "000010", -- srl
								"010" WHEN "001000", -- jr
								"011" WHEN OTHERS; -- Operacao invalida
 

	--Multiplexador que seleciona entre a instrucao R e as outras instrucoes
	ALU_ctl <=	"010" 		WHEN ALUop = "00" ELSE -- lw,sw,addi
					"110" 		WHEN ALUop = "01" ELSE -- beq, bne
					R_type_crt	WHEN ALUop = "10" OR ALUop = "11"; -- R Type
 
	--Multiplexador na entrada da ula
	Alu_in2 <= Sign_extend 
		WHEN ((ALUSrc = '1') OR (ALU_ctl = "100") OR (ALU_ctl = "101"))
		ELSE Read_data_2;
		
	-- Saida da ula para SLT 
	ALU_Result <= X"0000000" & B"000" & ALU_mux( 31 ) 
		WHEN ALU_ctl = "111"
		ELSE ALU_mux( 31 DOWNTO 0 );
	
	--Calcula o endeço de salto
	ADDResult <= ((Sign_extend(6 DOWNTO 0)&"00") + PC_PLUS_4);
	
	--Calcula o Jump absoluto
	JumpAddr <= ( PC_PLUS_4(9 DOWNTO 8) & Jump_immed(5 DOWNTO 0) & "00" );
	
	--Calcula o endereço de pulo guardado no registrador
	--JRegAddr <= ("00" & ALU_Mux(9 DOWNTO 2));
	JRegAddr <= ALU_Mux(9 DOWNTO 0);
	
	--Computa o valor do zero
	Zero <= '1' WHEN ALU_mux = x"00000000" ELSE '0';
	
PROCESS(ALU_ctl,Read_data_1,Alu_in2,Read_data_2)
BEGIN
	CASE ALU_ctl IS
		-- Operação E lógico 
		WHEN "000" => ALU_mux <= Read_data_1 AND Alu_in2; 
		-- Operação OU lógico 
		WHEN "001" => ALU_mux <= Read_data_1 OR Alu_in2;
		-- Operação de Soma (também serve para jr, sw e lw)
		WHEN "010" => ALU_mux <= Read_data_1 + Alu_in2;
		-- Operação de Subtração (também serve para beq e bne)
		WHEN "110" => ALU_mux <= Read_data_1 - Alu_in2;
		-- Operação SLT 
		WHEN "111" => ALU_mux <= Read_data_1 - Alu_in2;
		-- Operaçao SLL
		WHEN "100" => ALU_mux <= STD_LOGIC_VECTOR(SHL(UNSIGNED(Read_data_2),UNSIGNED(Alu_in2(10 DOWNTO 6))));
		-- Operaçao SRL
		WHEN "101" => ALU_mux <= STD_LOGIC_VECTOR(SHR(UNSIGNED(Read_data_2),UNSIGNED(Alu_in2(10 DOWNTO 6))));
		WHEN OTHERS => ALU_mux <= X"00000000" ;
	
	END CASE;
END PROCESS;
	
	
END behavior;

