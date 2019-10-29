LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


ENTITY Idecode IS
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
				Sign_extend 	: OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				PCAddr			: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
				clock,reset		: IN 	STD_LOGIC );
END Idecode;

ARCHITECTURE behavior OF Idecode IS

	-- Definiocao do vetor de registradores
	TYPE registe_file IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(31 DOWNTO 0);

	--
	SIGNAL register_array:registe_file;
	
	SIGNAL Rs_ID,Rt_ID,Rd_ID,write_reg_ID, write_reg_sel : STD_LOGIC_VECTOR(4 DOWNTO 0);
	
	SIGNAL Immediate_value : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	SIGNAL write_sel : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	SIGNAL write_data : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
	-- Os sinais abaixo devem receber as identificacoes dos registradores
	-- que estao definidos na instrucao, ou seja, o indice dos registradores
	-- a serem utilizados na execucao da instrucao
	-- Esses sinais separam em partes os bits da instrução
	Rs_ID 				<= Instruction(25 DOWNTO 21);
   Rt_ID 				<= Instruction(20 DOWNTO 16);
   Rd_ID					<= Instruction(15 DOWNTO 11);
   Immediate_value 	<= Instruction(15 DOWNTO 0);
	
	Write_data_out	<= write_data;
	
	-- Os sinais abaixo devem receber o conteudo dos registradores, reg(i)
	-- USE "CONV_INTEGER(read_Rs_ID)" para converter os bits de indice do registrador
	-- para um inteiro a ser usado como indice do vetor de registradores.
	-- Exemplo: dado um sinal X do tipo array de registradores, 
	-- X(CONV_INTEGER("00011")) recuperaria o conteudo do registrador 3.
	read_data_1 <= register_array(CONV_INTEGER(Rs_ID));	 
	read_data_2 <= register_array(CONV_INTEGER(Rt_ID));
	
	-- Crie um multiplexador que seleciona o registrador de escrita de acordo com o sinal RegDst
   write_reg_sel <= Rd_ID WHEN RegDst = '1' ELSE Rt_ID;
	
	write_reg_ID <= write_reg_sel WHEN (PCToReg = '0') ELSE
						 "11111";
	
	
	--Multiplexador na saida do data memory para selecionar escrita/leitura da memoria no registro
	write_sel <= ALU_result( 31 DOWNTO 0 ) WHEN ( MemToReg = '0' ) ELSE Read_data;
	
	write_data <= write_sel WHEN (PCToReg = '0') ELSE 
					  X"000000" & (PCAddr + 4); 
	
	-- Estenda o sinal Immediate_value de instrucoes do tipo I de 16-bits to 32-bits
	-- Faca isto independente do tipo de instrucao, mas use apenas quando
	-- for instrucao do tipo I.
   Sign_extend <= X"0000"&Immediate_value WHEN Immediate_value(15) = '0'
	ELSE X"FFFF"&Immediate_value;
	
	--Valor do Imediato para instrucao jp
	Jump_immed <= Instruction(25 DOWNTO 0);

PROCESS
	BEGIN
		WAIT UNTIL clock'EVENT AND clock = '1';
		IF reset = '1' THEN
			-- Inicializa os registradores com seu numero
			FOR i IN 0 TO 31 LOOP
				register_array(i) <= CONV_STD_LOGIC_VECTOR( i, 32 );
 			END LOOP;
  		ELSIF RegWrite = '1' AND write_reg_ID /= 0 THEN
		   -- Escreve no registrador indicado pela instrucao
			register_array(CONV_INTEGER(write_reg_ID)) <= write_data;
		END IF;
	END PROCESS;
END behavior;


