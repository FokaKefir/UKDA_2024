----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.12.2024 13:50:27
-- Design Name: 
-- Module Name: error_m_tb - Behavioral
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

entity error_m_tb is
end error_m_tb;

architecture Behavioral of error_m_tb is
    component error_m
        Port ( exp_turn : in signed (14 downto 0);
               act_turn : in signed (14 downto 0);
               error_val : out signed (15 downto 0));
    end component;

    signal exp_turn : signed (14 downto 0);
    signal act_turn : signed (14 downto 0);
    signal error_val : signed (15 downto 0);

begin
    uut: error_m
        Port map (
            exp_turn => exp_turn,
            act_turn => act_turn,
            error_val => error_val
        );

    process
    begin
        exp_turn <= to_signed(100, 15);
        act_turn <= to_signed(50, 15);
        wait for 10 ns;

        exp_turn <= to_signed(-100, 15);
        act_turn <= to_signed(-50, 15);
        wait for 10 ns;

        exp_turn <= to_signed(100, 15);
        act_turn <= to_signed(-50, 15);
        wait for 10 ns;

        exp_turn <= to_signed(-100, 15);
        act_turn <= to_signed(50, 15);
        wait for 10 ns;

        exp_turn <= to_signed(0, 15);
        act_turn <= to_signed(0, 15);
        wait for 10 ns;


        exp_turn <= to_signed(16383, 15); -- 2^14 - 1
        act_turn <= to_signed(0, 15);
        wait for 10 ns;

        exp_turn <= to_signed(-16384, 15); -- -2^14
        act_turn <= to_signed(0, 15);
        wait for 10 ns;

        exp_turn <= to_signed(16383, 15);
        act_turn <= to_signed(-16384, 15);
        wait for 10 ns;

        exp_turn <= to_signed(-16384, 15);
        act_turn <= to_signed(16383, 15);
        wait for 10 ns;

        exp_turn <= to_signed(0, 15);
        act_turn <= to_signed(0, 15);
        wait for 10 ns;

        exp_turn <= to_signed(16383, 15);
        act_turn <= to_signed(16382, 15);
        wait for 10 ns;

        exp_turn <= to_signed(-16384, 15);
        act_turn <= to_signed(-16383, 15);
        wait for 10 ns;

        wait;
    end process;

end Behavioral;
