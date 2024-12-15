----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2024 11:05:13 AM
-- Design Name: 
-- Module Name: clk - Behavioral
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
use IEEE.std_logic_signed.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MV_signal is       
    port( q_clk : in std_logic;
          reset : in std_logic;
          period : in std_logic_vector(15 downto 0);
          out_signal : out std_logic
    );
end MV_signal;

architecture Behavioral of MV_signal is

begin

process(q_clk,reset)

variable x: integer range 65535 downto 0 := 0;
variable out_sig: std_logic :='0';

begin
if reset ='1' then
    x:=1;
    out_sig:='0';
elsif q_clk'event and  q_clk='1' then
    if out_sig='0' then 
        if x < period then
            x:=x+1;
        else
            out_sig := '1';
        end if;
    else
        out_sig := '0';
        x := 1;
    end if;
      
end if;

out_signal<= out_sig;

end process;
end Behavioral;
