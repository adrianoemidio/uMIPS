LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;  -- Tipo de sinal STD_LOGIC e STD_LOGIC_VECTOR
USE IEEE.STD_LOGIC_ARITH.ALL;  -- Operacoes aritmeticas sobre binarios
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL; -- Componente de memoria

ENTITY Ifetch IS
	PORT( rst,clk	: IN STD_LOGIC;
		ADDResult	: IN	STD_LOGIC_VECTOR(9 DOWNTO 0);
		PCAddr		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		PC_PLUS_4	: OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
		dataInstr	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		Branch, Zero: IN STD_LOGIC);
END Ifetch;

ARCHITECTURE behavior OF Ifetch IS

-- Descreva aqui os demais sinais internos
SIGNAL PC		: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL PC_INC	: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL PC_NEXT : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL Mem_addr: STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
	-- Descricao da Memoria
	data_memory: altsyncram -- Declaracao do compomente de memoria
	GENERIC MAP(
		operation_mode	=> "ROM",
		width_a			=> 32, -- tamanho da palavra (Word)
		widthad_a		=> 8,   -- tamanho do barramento de endereco
		lpm_type			=> "altsyncram",
		outdata_reg_a	=> "UNREGISTERED",
		init_file		=> "program.mif",  -- arquivo com estado inicial
		intended_device_family => "Cyclone")
	PORT MAP(
		address_a	=> Mem_addr,
		q_a			=> dataInstr,
		clock0		=> clk);  -- sinal de clock da memoria
	
	-- Descricao do somador (soma 1 palavra)
	PC_INC <= PC + 4;
	PC_PLUS_4 <= PC_INC;
	
	PC_NEXT <= "0000000000" WHEN rst = '1' ELSE 
					ADDResult WHEN ((Zero = '1') AND (Branch = '1')) ELSE
					PC_INC;
					
	-- Descricao do registrador (32 bits)
	Mem_addr <= PC_NEXT(9 DOWNTO 2);	
	
	PCAddr <= PC(9 DOWNTO 2);
	
	PROCESS(clk,rst)
	BEGIN
		IF(rst = '1') THEN
			PC <= "00" & x"00";
		ELSIF(clk'event AND clk = '1') THEN		
			PC <= PC_NEXT;
		END IF;
	
	
	
	END PROCESS; 
	

	
END behavior;
