LIBRARY IEEE; 
USE IEEE.STD_LOGIC_1164.ALL; 
USE IEEE.STD_LOGIC_ARITH.ALL; 
USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

ENTITY video IS 
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
END video;

ARCHITECTURE arch OF video IS

	COMPONENT vga 
		PORT( clock_25MHz		: IN STD_LOGIC; 
				horiz_sync_out : OUT STD_LOGIC; 
				vert_sync_out	: OUT STD_LOGIC;
				v_on_out			: OUT STD_LOGIC;
				c_sync			: OUT STD_LOGIC;
				pixel_row 		: OUT STD_LOGIC_VECTOR( 9 DOWNTO 0 );
				pixel_column : OUT STD_LOGIC_VECTOR( 9 DOWNTO 0 )); 
	END COMPONENT;
	
	COMPONENT char_mem
		PORT(
			clk					: IN STD_LOGIC;
			char_read_addr 	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
			char_write_addr	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
			char_we				: IN STD_LOGIC;
			char_write_value	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			char_read_value	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT font_rom
		PORT(
				clk	: IN STD_LOGIC;
				addr	: IN STD_LOGIC_VECTOR(10 downto 0);
				data	: OUT STD_LOGIC_VECTOR(7 downto 0));
	END COMPONENT;
	
	COMPONENT ram_wrt
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

	END COMPONENT;


	--Video RAM address signal
	SIGNAL vram_addr : STD_LOGIC_VECTOR(11 DOWNTO 0);

	--Line and column counters
	SIGNAL v_counter : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL h_counter : STD_LOGIC_VECTOR(9 DOWNTO 0);

	--Video RAM data read
	SIGNAL vram_data_out		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL vram_data_out_i	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL vram_data_out_ii : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	--Video RAM data write
	SIGNAL vram_data_in : STD_LOGIC_VECTOR(7 DOWNTO 0);

	--Static signals
	SIGNAL clk_25_n : STD_LOGIC;
	SIGNAL clk_50_n : STD_LOGIC;

	SIGNAL cr_we_i : STD_LOGIC;
	SIGNAL cr_we_ii : STD_LOGIC;
	
	SIGNAL char_read_addr : STD_LOGIC_VECTOR(11 DOWNTO 0);
	
	SIGNAL addr : STD_LOGIC_VECTOR(10 DOWNTO 0);
	
	--Charcter ROM data out
	SIGNAL crom_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	--Vram write signal
	SIGNAL w_en : STD_LOGIC;
	
	--25MHz clock
	SIGNAL clk_25MHz : STD_LOGIC;
	
	--Video on signal
	SIGNAL video_on : STD_LOGIC;
	
	--Pixel output
	SIGNAL pixel : STD_LOGIC;
	

BEGIN

	clk_25_n <= NOT(clk_25MHz);
	clk_50_n <= NOT(clk_50MHz);
	
	cr_we_i  <= (w_en AND m_sel);
	cr_we_ii <= (w_en AND (NOT(m_sel)));
	
	char_read_addr <= (v_counter(8 DOWNTO 4) & h_counter(9 DOWNTO 3));
	
	addr <= (vram_data_out(6 DOWNTO 0) & v_counter(3 DOWNTO 0));
	
	v_on_out <= video_on;
	
	vga_clk <= clk_25MHz;


-- Output latch
PROCESS 
BEGIN 
	WAIT UNTIL( clk_25MHz'EVENT ) AND ( clk_25MHz = '1' );
		red	<= '0' AND video_on;
		green	<= pixel AND video_on;	
		blue	<= '0' AND video_on;
END PROCESS;
	
--Clock divider
PROCESS(clk_50MHz)
BEGIN
	IF(RISING_EDGE(clk_50MHz)) THEN
		clk_25MHz <= NOT(clk_25MHz);
	END IF;
END PROCESS;

	 VGA_i: vga
		PORT MAP(
				clock_25MHz		=> clk_25MHz,
				horiz_sync_out => h_sync ,
				vert_sync_out	=> v_sync,
				v_on_out			=> video_on,
				c_sync			=> c_sync,
				pixel_row 		=> v_counter,
				pixel_column 	=> h_counter); 
	
	VRAM_I: char_mem 
		PORT MAP(
			clk					=> clk_50_n,
			char_read_addr 	=> char_read_addr,
			char_write_addr	=> vram_addr,
			char_we				=> cr_we_i,
			char_write_value	=> vram_data_in,
			char_read_value	=> vram_data_out_i);
	
	VRAM_II: char_mem 
		PORT MAP(
			clk					=> clk_50_n,
			char_read_addr 	=> char_read_addr,
			char_write_addr	=> vram_addr,
			char_we				=> cr_we_ii,
			char_write_value	=> vram_data_in,
			char_read_value	=> vram_data_out_ii);


	CROM_I: font_rom
		PORT MAP(
				clk	=> clk_50_n,
				addr	=> addr,
				data	=> crom_data);
	
	WRT_I: ram_wrt
		PORT MAP(
			w_data		=> vram_data_in,
			w_addr		=> vram_addr,
			ram_addr		=>	ram_addr,
			write_en		=> w_en,
			m_sel			=> m_sel,
			clk			=> clk_25_n,
			update		=> video_on,
			MenWrite		=> MenWrite,
			Zero			=> Zero,
			Jump			=> Jump,
			PCAddr		=> PCAddr,
			readData1	=> ReadData1,
			readData2	=> ReadData2,
			DataInstr	=> DataInstr,
			ALU_result	=> ALU_result,
			ram_data		=> ram_data);
	
	--Output mux
	WITH h_counter(2 DOWNTO 0) SELECT
		pixel <= crom_data(7) WHEN "000",
					crom_data(6) WHEN "001",		
					crom_data(5) WHEN "010",
					crom_data(4) WHEN "011",
					crom_data(3) WHEN "100",
					crom_data(2) WHEN "101",
					crom_data(1) WHEN "110",
					crom_data(0) WHEN "111",
					crom_data(0) WHEN OTHERS;
	
	--VRAM select mux
	vram_data_out	<= vram_data_out_ii  WHEN m_sel = '0' ELSE vram_data_out_i;
	
END arch;