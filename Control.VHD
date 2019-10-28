-- control module
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY control IS
   PORT( Opcode 		: IN 		STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			ALUop 		: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			RegDst 		: OUT 	STD_LOGIC;
			MemToReg		: OUT		STD_LOGIC;
			MenWrite		: OUT 	STD_LOGIC;
			ALUSrc		: OUT 	STD_LOGIC;
			RegWrite 	: OUT 	STD_LOGIC;
			Branch 		: OUT		STD_LOGIC);
END control;

ARCHITECTURE behavior OF control IS

	SIGNAL	R_format	: STD_LOGIC;
	SIGNAL	beq		: STD_LOGIC;
	SIGNAL	lw,sw		: STD_LOGIC;
	
BEGIN           
	
	ALUOp( 1 ) <= R_format; 
	ALUOp( 0 ) <= beq;
	
	R_format <= '1' WHEN Opcode="000000" ELSE '0';
	lw			<=	'1' WHEN Opcode="100011" ELSE '0';
	sw			<=	'1' WHEN Opcode="101011" ELSE '0';
	beq		<= '1' WHEN Opcode="000100" ELSE '0';
	
	RegDst	<= R_format;
	RegWrite <= lw OR R_format;
	MemToReg <= lw;
	ALUSrc	<= lw or sw;
	MenWrite <= sw;
	Branch	<= beq;
	

   END behavior;


