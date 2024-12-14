----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/14/2024 06:30:20 PM
-- Design Name: 
-- Module Name: second_order_system_tb - Behavioral
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

entity second_order_system_tb is
end second_order_system_tb;

architecture Behavioral of second_order_system_tb is

    component second_order_system is
        generic(
            A1 : integer := 20000;
            A2 : integer := -10000;
            B  : integer := 5000
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
    signal sys_out : signed(14 downto 0);

    constant CLK_PERIOD : time := 20 ns;

begin

    UUT: second_order_system
        generic map(
            A1 => 25000,   
            A2 => -10000,  
            B  => 5000
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
        -- Hold reset for the first 100 ns
        wait for 100 ns;
        reset <= '0';

        -- Wait some time before applying the step input
        wait for 200 ns;

        -- Apply a step: For example, set sys_in to 1000 and direction forward
        sys_in <= to_signed(1000, 16);
        dir <= "01";  -- forward

        -- Let the system run and observe how sys_out changes over time.
        wait for 6000 ns;

        -- Finish simulation
        wait;
    end process;

end Behavioral;

