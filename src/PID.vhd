----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2024 10:33:17 AM
-- Design Name: 
-- Module Name: PID - Behavioral
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
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PID is
    Port ( 
        q_clk : in STD_LOGIC;
        src_ce : in std_logic;
        src_reset : in std_logic;
        start : in std_logic;
        error : in STD_LOGIC_VECTOR (15 downto 0);   
        output : out STD_LOGIC_VECTOR (15 downto 0);
        dir : out std_logic_vector (1 downto 0)
    );
end PID;

architecture Behavioral of PID is

type statetypes is (RDY, INIT, CALC_PID, SUM_PID, DIVIDE_KG, OVERLOAD, SIGN, END_S);
signal actual_state, next_state : statetypes := RDY;

-- PID parameters
signal Kp : integer := 1000;
signal Kd : integer := 5;
signal Ki : integer := 0;

-- signals for calculations
signal output_signed : signed(16 downto 0) := (others => '0');
signal inter : signed (31 downto 0) := (others => '0');
signal error_signed : signed(15 downto 0) := (others => '0');
signal p, i, d : signed(31 downto 0) := (others => '0');
signal output_carrier : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
signal dir_internal : STD_LOGIC_VECTOR(1 downto 0) := "00";

begin

state_r : process(q_clk, src_reset)
begin
    if src_reset = '1' then
        actual_state <= RDY;
    elsif rising_edge(q_clk) then
        actual_state <= next_state;
    end if;
end process state_r;

next_state_logic : process(actual_state, start)
begin
    case actual_state is
        when RDY =>
            if start = '1' then
                next_state <= INIT;
            else
                next_state <= RDY;
            end if;
        when INIT => 
            next_state <= CALC_PID;
        when CALC_PID =>
            next_state <= SUM_PID;
        when SUM_PID =>
            next_state <= DIVIDE_KG;
        when DIVIDE_KG =>
            next_state <= OVERLOAD;
        when OVERLOAD =>
            next_state <= SIGN;
        when SIGN => 
            next_state <= END_S;
        when END_S =>
            next_state <= RDY;
    end case;
end process next_state_logic;

process(actual_state)
    variable error_old : signed(15 downto 0) := (others => '0');
begin
    case actual_state is
        when RDY =>
            
            
        when INIT => 
            error_signed <= signed(error);
        when CALC_PID =>
            p <= Kp * error_signed;
            i <= Ki * (error_signed + error_old);
            d <= Kd * (error_signed - error_old);
        when SUM_PID =>
            inter <= p + i + d;
        when DIVIDE_KG =>
            output_signed <= resize(inter / 2048, 17);
        when OVERLOAD =>
            if output_signed > to_signed(32767, 17) then
                output_signed <= to_signed(32767, 17);
            elsif output_signed < to_signed(-32768, 17) then 
                output_signed <= to_signed(-32768, 17);
            end if;
        when SIGN => 
            if output_signed = 0 then
                output_carrier <= (others => '0');
                dir_internal <= "00";
            elsif output_signed < 0 then
                output_carrier <= std_logic_vector(-output_signed(15 downto 0));
                dir_internal <= "10";
            else
                output_carrier <= std_logic_vector(output_signed(15 downto 0));
                dir_internal <= "01";
            end if;
        when END_S =>
            error_old := error_signed;
    end case;
end process;

output <= output_carrier;
dir <= dir_internal;

end Behavioral;

