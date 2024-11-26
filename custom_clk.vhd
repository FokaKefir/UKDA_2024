----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2024 10:23:53 AM
-- Design Name: 
-- Module Name: custom_clk - Behavioral
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

entity custom_clk is
    Port ( src_clk : in STD_LOGIC;
           reset : in std_logic;
           div_val : in STD_LOGIC_VECTOR (9 downto 0);
           q_clk : out STD_LOGIC);
end custom_clk;

architecture Behavioral of custom_clk is

begin

process(src_clk,reset)

variable x: integer range 1023 downto 0 := 0;
variable q: std_logic := '0';

begin 
if reset ='1' then
    x:=0;
    q:='0';
elsif src_clk'event and  src_clk='1' then
    if x<div_val then
        x:=x+1;
        q:=q;
    else
        x:=1;
        q:=not(q);
    end if;
end if;
q_clk<=q;
end process;

end Behavioral;
