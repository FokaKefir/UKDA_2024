----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2024 11:25:40 AM
-- Design Name: 
-- Module Name: pwm_module - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwm_ultra is
    Port ( 	src_clk : in  STD_LOGIC;
           	src_ce : in  STD_LOGIC;
           	reset : in  STD_LOGIC;
           	h : in  STD_LOGIC_VECTOR (15 downto 0);
			min_val : in STD_LOGIC_VECTOR (15 downto 0);
			max_val : in STD_LOGIC_VECTOR (15 downto 0);
           	pwm_out : out  STD_LOGIC);
end pwm_ultra;


architecture Behavioral of pwm_ultra is

type casee is(RDY,INIT,HIGH,LOW);
signal actual_case : casee;
signal next_case : casee;
signal pwm_sig, pwm_next_sig : STD_LOGIC;
signal counter, counter_next : STD_LOGIC_VECTOR(15 downto 0);

begin

State_R:process(src_clk,reset)
begin

    if reset = '1' then
			actual_case <= RDY;
			counter <= (others => '0');
			pwm_sig <= '0';
	elsif (src_clk'event and src_clk='1') then
			actual_case <= next_case;
			counter <= counter_next;
			pwm_sig <= pwm_next_sig;
	end if;

end process State_R;

next_case_log:process(actual_case, counter, h)
begin

case(actual_case) is
	when RDY =>
		next_case<=INIT;
		
	when INIT =>
		if counter < min_val
			then
				next_case<=INIT;
			else
				next_case<=HIGH;
		end if;

	when HIGH =>
		if counter< (h+min_val)  	
			then	
				next_case<=HIGH;
			else
				next_case<=LOW;
		end if;
		
	when LOW =>
		if counter<max_val  
			then
				next_case<=LOW;
			else
				next_case<=RDY;
		end if;
	end case;
end process next_case_log;

WITH actual_case SELECT 
counter_next<=	(others => '0')	WHEN RDY,
				counter + 1     WHEN others; 
				
				
WITH actual_case SELECT
pwm_next_sig<= 	'0' WHEN RDY,
				'1' WHEN INIT,
				'1' WHEN HIGH,
				'0' WHEN LOW;


pwm_out<=pwm_next_sig;


end Behavioral;
