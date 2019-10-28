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
			Zero				: OUT	STD_LOGIC);
END Execute;

ARCHITECTURE behavior OF Execute IS

	SIGNAL Alu_in2 	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ALU_Mux		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ALU_ctl		: STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN
	
	--Gera os sinais para ALU Control
	ALU_ctl( 0 ) <= ( function_op( 0 ) OR function_op( 3 ) ) AND ALUop(1 ); 
	ALU_ctl( 1 ) <= ( NOT function_op( 2 ) ) OR (NOT ALUOp( 1 ) ); 
	ALU_ctl( 2 ) <= ( function_op( 1 ) AND ALUop( 1 )) OR ALUop( 0 );
	
	--Multiplexador na entrada da ula
	Alu_in2 <= Sign_extend 
		WHEN ALUSrc = '1'
		ELSE Read_data_2;
		
	-- Saida da ula para SLT 
	ALU_Result <= X"0000000" & B"000" & ALU_mux( 31 ) 
		WHEN ALU_ctl = "111"
		ELSE ALU_mux( 31 DOWNTO 0 );
	
	--Calcula o endeço de salto
	ADDResult <= ((Sign_extend(6 DOWNTO 0)&"00") + PC_PLUS_4);
	
	--Computa o valor do zero
	Zero <= '1' WHEN ALU_mux = x"00000000" ELSE '0';
	
PROCESS(ALU_ctl,Read_data_1,Alu_in2)
BEGIN
	CASE ALU_ctl IS
		-- Operação E lógico 
		WHEN "000" => ALU_mux <= Read_data_1 AND Alu_in2; 
		-- Operação OU lógico 
		WHEN "001" => ALU_mux <= Read_data_1 OR Alu_in2;
		-- Operação de Soma 
		WHEN "010" => ALU_mux <= Read_data_1 + Alu_in2;
		-- Operação de Subtração 
		WHEN "110" => ALU_mux <= Read_data_1 - Alu_in2;
		-- Operação SLT 
		WHEN "111" => ALU_mux <= Read_data_1 - Alu_in2 ; 
		WHEN OTHERS => ALU_mux <= X"00000000" ;
	
	END CASE;
END PROCESS;
	
	
END behavior;

