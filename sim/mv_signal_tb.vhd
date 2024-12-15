----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2024 11:30:55 AM
-- Design Name: 
-- Module Name: mv_signal_tb - Behavioral
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

entity mv_signal_tb is
--  Port ( );
end mv_signal_tb;

architecture Behavioral of mv_signal_tb is

component  custom_clk is
    Port ( src_clk : in STD_LOGIC;
           reset : in std_logic;
           div_val : in STD_LOGIC_VECTOR (9 downto 0);
           q_clk : out STD_LOGIC);
end component;

component MV_signal is       
    port( q_clk : in std_logic;
          reset : in std_logic;
          period : in std_logic_vector(15 downto 0);
          out_signal : out std_logic
    );
end component;

           signal src_clk : STD_LOGIC := '0';
           signal reset : std_logic;
           signal div_val : STD_LOGIC_VECTOR (9 downto 0);
           signal q_clk : STD_LOGIC;
           signal period : std_logic_vector(15 downto 0);
           signal mv_out_signal : std_logic;
  
    

begin
src_clk <= not src_clk after 5 ns;
custom_clk_peldany: custom_clk
    port map ( src_clk => src_clk,
               reset => reset,
               div_val => div_val,
               q_clk => q_clk);

mv_signal_peldany: mv_signal
    port map ( q_CLK => q_clk,
               reset => reset,
               period => period,
               out_signal => mv_out_signal
    );   
process

begin
    div_val <= "0000000010";
    period <= "0000000000000100";
    reset <= '1';
    wait for 12 ns;
    reset <= '0';
    wait;
end process;
end Behavioral;
