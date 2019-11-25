LIBRARY IEEE; 
USE IEEE.STD_LOGIC_1164.ALL; 
USE IEEE.STD_LOGIC_ARITH.ALL; 
USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

ENTITY VGA IS 
PORT( clock_25MHz		: IN STD_LOGIC; 
		horiz_sync_out : OUT STD_LOGIC; 
		vert_sync_out	: OUT STD_LOGIC;
		v_on_out			: OUT STD_LOGIC;
		c_sync			: OUT STD_LOGIC;
 		pixel_row 		: OUT STD_LOGIC_VECTOR( 9 DOWNTO 0 );
		pixel_column : OUT STD_LOGIC_VECTOR( 9 DOWNTO 0 )); 
		
END VGA; 

ARCHITECTURE a OF VGA IS 
	SIGNAL horiz_sync, vert_sync : STD_LOGIC; 
	SIGNAL video_on_v, video_on_h : STD_LOGIC; 
	SIGNAL h_count, v_count : STD_LOGIC_VECTOR( 9 DOWNTO 0 ); 
	
BEGIN 

	
	-- video_on is High only when RGB data is displayed 
	v_on_out <= video_on_H AND video_on_V;
	
	--Sicronismo Separado do canal de cores
	--c_sync <= horiz_sync;
	c_sync <= '0';
	
	

	PROCESS 
		BEGIN 
		WAIT UNTIL( clock_25MHz'EVENT ) AND ( clock_25MHz = '1' ); 
		--Generate Horizontal and Vertical Timing Signals for Video Signal 
		-- H_count counts pixels (640 + extra time for sync signals) 
		IF ( h_count = 799 ) THEN 
			h_count <= "0000000000"; 
		ELSE 
			h_count <= h_count + 1; 
		END IF; 
			
		--Generate Horizontal Sync Signal using H_count 
		IF((h_count < 756)AND(h_count > 658)) THEN 
			horiz_sync <= '0'; 
		ELSE 
			horiz_sync <= '1'; 
		END IF; 
		
		--V_count counts rows of pixels (480 + extra time for sync signals) 
		IF ( v_count > 523 ) AND ( h_count > 698 ) THEN 
			v_count <= "0000000000"; 
		ELSIF ( h_count = 699 ) THEN 
			v_count <= v_count + 1; 
		END IF; 
		
		-- Generate Vertical Sync Signal using V_count 
		IF ( v_count < 495 ) AND ( v_count > 492 ) THEN 
			vert_sync <= '0';
		ELSE 
			vert_sync <= '1'; 
		END IF; 
		
		-- Generate Video on Screen Signals for Pixel Data 
		IF ( h_count < 640 ) THEN 
			video_on_h <= '1'; 
			pixel_column <= h_count; 
		ELSE 
			video_on_h <= '0'; 
		END IF; 
		
		IF ( v_count < 480 ) THEN 
			video_on_v <= '1'; 
			pixel_row <= v_count; 
		ELSE 
			video_on_v <= '0';
		END IF;
		
		-- Turn off RGB out
		--red_out <= red AND video_on; 
		--green_out <= green AND video_on; 
		--blue_out <= blue AND video_on; 
		horiz_sync_out <= horiz_sync; 
		vert_sync_out <= vert_sync; 
		
		END PROCESS; 
	END a;
	