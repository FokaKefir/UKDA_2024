----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/14/2024 05:54:52 PM
-- Design Name: 
-- Module Name: first_order_system_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity first_order_system_tb is
end first_order_system_tb;

architecture Behavioral of first_order_system_tb is

    component first_order_system is
        generic(
            A : integer := 30000;
            B : integer := 2768
        );
        Port (
            q_clk    : in  std_logic;
            reset    : in  std_logic;
            enable   : in  std_logic;
            sys_in  : in  signed(15 downto 0);    
            dir      : in  std_logic_vector(1 downto 0);
            sys_out  : out signed(14 downto 0)     
        );
    end component;

    signal q_clk   : std_logic := '0';
    signal reset   : std_logic := '1';
    signal enable  : std_logic := '1';
    signal sys_in : signed(15 downto 0) := (others => '0');
    signal dir     : std_logic_vector(1 downto 0) := "00";
    signal sys_out : signed(14 downto 0);  -- 15-bit output

    constant CLK_PERIOD : time := 20 ns;

begin

    UUT: first_order_system
        generic map(
            A => 23000,  
            B => 9768
        )
        port map(
            q_clk   => q_clk,
            reset   => reset,
            enable  => enable,
            sys_in => sys_in,
            dir     => dir,
            sys_out => sys_out
        );

    -- Clock generation
    clk_process: process
    begin
        q_clk <= '0';
        wait for CLK_PERIOD/2;
        q_clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initially hold reset for 100 ns
        wait for 100 ns; 
        reset <= '0';  -- Release reset after 100 ns

        -- Wait a bit before applying the step input
        wait for 200 ns;

        -- Apply a step input: set sys_in to a value and direction forward
        sys_in <= to_signed(1000,16);  -- 16-bit signed magnitude
        dir <= "01";  -- forward direction
        
        -- Let the simulation run and observe output
        wait for 6000 ns;

        -- Finish simulation
        wait;
    end process;

end Behavioral;
