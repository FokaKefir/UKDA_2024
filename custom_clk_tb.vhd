----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2024 10:35:07 AM
-- Design Name: 
-- Module Name: custom_clk_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity custom_clk_tb is
--  Port ( );
end custom_clk_tb;

architecture Behavioral of custom_clk_tb is

component  custom_clk is
    Port ( src_clk : in STD_LOGIC;
           reset : in std_logic;
           div_val : in STD_LOGIC_VECTOR (9 downto 0);
           q_clk : out STD_LOGIC);
end component;

           signal src_clk : STD_LOGIC := '0';
           signal reset : std_logic;
           signal div_val : STD_LOGIC_VECTOR (9 downto 0);
           signal q_clk : STD_LOGIC;
  
    

begin
src_clk <= not src_clk after 5 ns;
custom_clk_peldany: custom_clk
    port map ( src_clk => src_clk,
               reset => reset,
               div_val => div_val,
               q_clk => q_clk);
      
process

begin
    div_val <= "0000001000";
    reset <= '1';
    wait for 10 ns;
    reset <= '0';
    wait;
end process;
end Behavioral;
