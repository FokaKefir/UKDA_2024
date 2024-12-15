----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/03/2024 10:22:18 AM
-- Design Name: 
-- Module Name: pid_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Testbench for PID module
-- 
-- Dependencies: PID.vhd
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pid_pwm_tb is
end pid_pwm_tb;

architecture Behavioral of pid_pwm_tb is

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

component PID is
    Port ( 
        q_clk : in STD_LOGIC;
        src_ce : in std_logic;
        src_reset : in std_logic;
        start : in std_logic;
        error : in STD_LOGIC_VECTOR (15 downto 0);   
        output : out STD_LOGIC_VECTOR (15 downto 0);
        dir : out std_logic_vector (1 downto 0)
    );
end component;


component pwm_ultra is
    Port ( 	src_clk : in  STD_LOGIC;
           	src_ce : in  STD_LOGIC;
           	reset : in  STD_LOGIC;
           	h : in  STD_LOGIC_VECTOR (15 downto 0);
			min_val : in STD_LOGIC_VECTOR (15 downto 0);
			max_val : in STD_LOGIC_VECTOR (15 downto 0);
           	pwm_out : out  STD_LOGIC);
end component;

    -- Signals for the PID module
    
    signal q_clk : std_logic := '0';
    signal src_ce : std_logic := '1';
    signal reset : std_logic := '1';
    signal error : std_logic_vector(15 downto 0) := std_logic_vector(to_signed(2000, 16));
    signal output : std_logic_vector(15 downto 0) := "0000000000000000";
    signal dir : std_logic_vector(1 downto 0);

    signal src_clk : STD_LOGIC := '0';
    signal period : std_logic_vector(15 downto 0);
    signal div_val : STD_LOGIC_VECTOR (9 downto 0);
    signal mv_out_signal : std_logic := '0';
    
    signal min_val : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000001";
	signal max_val : STD_LOGIC_VECTOR (15 downto 0) := "1111000000000000";
    signal pwm_out :  STD_LOGIC;

begin

    src_clk <= not src_clk after 5 ns;
    
    custom_clk_uut: custom_clk
        port map ( src_clk => src_clk,
                   reset => reset,
                   div_val => div_val,
                   q_clk => q_clk);

    mv_signal_uut: mv_signal
        port map ( q_clk => q_clk,
                   reset => reset,
                   period => period,
                   out_signal => mv_out_signal
        ); 

    -- Instantiate the PID module
    pid_peldany: PID
    port map (
            q_clk => q_clk,
            src_ce => src_ce,
            src_reset => reset,
            start => mv_out_signal,
            error => error,
            output => output,
            dir => dir
    );
    
    pwm_peldany: pwm_ultra
    Port map ( 	
        src_clk => src_clk,
        src_ce => src_ce, 
        reset => reset,
        h => output,
        min_val => min_val,
	    max_val => max_val,
        pwm_out => pwm_out
    );
        
    

div_val <= "0000001000";
period <= "0000000000011010";

reset <= '0' after 20ns;

process(mv_out_signal)
begin
    if rising_edge(mv_out_signal) then
            if signed(error) > -1200 then
                error <= std_logic_vector(signed(error) - 100 - signed(error) / 64);
        end if;
    end if;
end process;

end Behavioral;
