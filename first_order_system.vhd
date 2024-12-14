----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/14/2024 05:22:31 PM
-- Design Name: 
-- Module Name: first_order_system - Behavioral
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

entity first_order_system is
    generic(
        -- A and B as Q15 parameters.
        A : integer := 30000;  -- Example pole factor, scaled as Q15
        B : integer := 5000    -- Example gain factor, scaled as Q15
    );
    Port (
        q_clk    : in  std_logic;
        reset    : in  std_logic;
        enable   : in  std_logic;
        sys_in  : in  signed(15 downto 0);  
        dir      : in  std_logic_vector(1 downto 0);
        sys_out  : out signed(14 downto 0) 
    );
end first_order_system;

architecture Behavioral of first_order_system is

    -- 15-bit signed range: -16384 to +16383
    signal speed     : signed(14 downto 0) := (others => '0');
    signal input_val : signed(15 downto 0) := (others => '0');
   

begin

    process(q_clk, reset)
         variable temp : integer;
    begin
        if reset = '1' then
            speed <= (others => '0');
        elsif rising_edge(q_clk) then
            if enable = '1' then
                -- Determine input_val based on direction
                case dir is
                    when "01" => input_val <= sys_in;               -- Forward torque
                    when "10" => input_val <= -sys_in;              -- Reverse torque
                    when others => input_val <= (others => '0');    -- No torque
                end case;

                -- Compute next speed:
                -- speed_next = (A/32768)*speed + (B/32768)*input_val
                temp := (to_integer(speed)*A)/32768 + (to_integer(input_val)*B)/32768;

                -- Saturate to 15-bit range: -16384 to +16383
                if temp > 16383 then
                    speed <= to_signed(16383, 15);
                elsif temp < -16384 then
                    speed <= to_signed(-16384, 15);
                else
                    speed <= to_signed(temp, 15);
                end if;
            end if;
        end if;
    end process;

    sys_out <= speed;

end Behavioral;

