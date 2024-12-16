----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/14/2024 06:27:11 PM
-- Design Name: 
-- Module Name: second_order_system - Behavioral
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

entity second_order_system is
    generic(
        -- A1, A2, and B as Q15 parameters.
        -- Example stable system parameters:
        -- A1 ~ 0.6 (about 19660 in Q15), A2 ~ -0.2 (about -6553 in Q15), B ~ 0.25 (about 8192 in Q15)
        A1 : integer := 20000;   -- Approx 0.61 in Q15 scaling (20000/32768 ~ 0.61)
        A2 : integer := 10000;  -- Approx -0.30 in Q15 scaling (-10000/32768 ~ -0.30)
        B  : integer := 2768     -- Approx 0.15 in Q15 scaling (5000/32768 ~ 0.15)
    );
    Port (
        q_clk    : in  std_logic;
        reset    : in  std_logic;
        enable   : in  std_logic;
        sys_in  : in  signed(15 downto 0);
        dir      : in  std_logic_vector(1 downto 0);
        sys_out  : out signed(14 downto 0)
    );
end second_order_system;

architecture Behavioral of second_order_system is

    -- 15-bit signed range: -16384 to +16383
    signal y_k     : signed(14 downto 0) := (others => '0');  -- y(k)
    signal y_km1   : signed(14 downto 0) := (others => '0');  -- y(k-1)
    signal input_val : signed(15 downto 0) := (others => '0');
    
    
begin

    process(q_clk, reset)
        variable temp : integer;
    begin
        if reset = '1' then
            -- Initialize both states to zero
            y_k   <= (others => '0');
            y_km1 <= (others => '0');
        elsif rising_edge(q_clk) then
            if enable = '1' then
                -- Determine input based on direction
                case dir is
                    when "01" => input_val <= sys_in;               -- forward
                    when "10" => input_val <= -sys_in;              -- reverse
                    when others => input_val <= (others => '0');    -- no input
                end case;
                
                -- Compute y(k+1):
                -- y(k+1) = A1*y(k) + A2*y(k-1) + B*u(k)
                temp := (to_integer(y_k) * A1 +to_integer(y_km1)*A2 + to_integer(input_val)*B)/32768;

                -- Saturation to 15-bit range: [-16384, 16383]
                if temp > 16383 then
                    y_km1 <= y_k;  -- update old states
                    y_k   <= to_signed(16383, 15);
                elsif temp < -16384 then
                    y_km1 <= y_k;
                    y_k   <= to_signed(-16384, 15);
                else
                    y_km1 <= y_k;
                    y_k   <= to_signed(temp, 15);
                end if;
            end if;
        end if;
    end process;

    sys_out <= y_k;

end Behavioral;
