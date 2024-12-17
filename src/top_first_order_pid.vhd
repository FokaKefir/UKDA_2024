----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/17/2024 10:19:39 AM
-- Design Name: 
-- Module Name: top_first_order_pid - Behavioral
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

entity top_first_order_pid is
Port ( 
    src_clk : in STD_LOGIC
);
end top_first_order_pid;

architecture Behavioral of top_first_order_pid is

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

component error_m
        Port ( exp_turn : in signed (14 downto 0);
               act_turn : in signed (14 downto 0);
               error_val : out signed (15 downto 0));
end component;

component first_order_system is
        generic(
            A : integer := 30000;
            B : integer := 5000
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

component PID is
    generic(
        -- PID parameters
        Kp : integer;
        Kd : integer;
        Ki : integer
    );
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

component vio_0
port (
    clk : in std_logic;
    probe_in0 : in std_logic_vector(14 downto 0);
    probe_out0 : out std_logic_vector(14 downto 0);
    probe_out1 : out std_logic_vector(0 downto 0)
);
end component;


    signal q_clk : std_logic := '0';
    signal src_ce : std_logic := '1';
    signal reset : std_logic := '1';
    signal error : std_logic_vector(15 downto 0) := (others => '0');
    signal output : std_logic_vector(15 downto 0) := "0000000000000000";
    signal dir : std_logic_vector(1 downto 0);

    signal period_pid : std_logic_vector(15 downto 0);
    signal period_fo : std_logic_vector(15 downto 0);
    signal div_val : STD_LOGIC_VECTOR (9 downto 0);
    signal mv_out_fo : std_logic := '0';
    signal mv_out_pid : std_logic := '0';
    
    signal sys_in : signed(15 downto 0) := (others => '0');
    signal sys_out : signed(14 downto 0); 
    
    signal exp_turn : signed (14 downto 0) := (others => '0');
    signal error_val : signed (15 downto 0);
    
    signal probe_sys : std_logic_vector(14 downto 0);
    signal probe_ref : std_logic_vector(14 downto 0);
    signal probe_reset : std_logic_vector(0 downto 0);

begin

    div_val <= "0100010000";
    period_pid <= "0000000000001010";
    period_fo <= "0000000000000101";

    custom_clk_uut: custom_clk
        port map ( src_clk => src_clk,
                   reset => reset,
                   div_val => div_val,
                   q_clk => q_clk);

    mv_signal_pid: mv_signal
        port map ( q_clk => q_clk,
                   reset => reset,
                   period => period_pid,
                   out_signal => mv_out_pid
        ); 
        
    mv_signal_fo: mv_signal
        port map ( q_clk => q_clk,
                   reset => reset,
                   period => period_fo,
                   out_signal => mv_out_fo
        ); 
    
    sys_in <= signed(output);
    
    first_order_system_peldany: first_order_system
        generic map(
            A => 30768,  
            B => 2000
        )
        port map(
            q_clk   => mv_out_fo,
            reset   => reset,
            enable  => src_ce,
            sys_in => sys_in,
            dir     => dir,
            sys_out => sys_out
        );
        
     error_peldany: error_m
        Port map (
            exp_turn => exp_turn,
            act_turn => sys_out,
            error_val => error_val
        );
    
    error <= std_logic_vector(error_val);

    -- Instantiate the PID module
    pid_peldany: PID
    generic map(
        Kp => 150,
        Kd => 50,
        Ki => 300
    )
    port map (
            q_clk => q_clk,
            src_ce => src_ce,
            src_reset => reset,
            start => mv_out_pid,
            error => error,
            output => output,
            dir => dir
    );
    
    probe_sys <= std_logic_vector(sys_out);
    exp_turn <= signed(probe_ref);
    
    vio_peldany : vio_0
    port map (
        clk => src_clk,
        probe_in0 => probe_sys,
        probe_out0 => probe_ref,
        probe_out1 => probe_reset
    );
    
    reset <= probe_reset(0);


end Behavioral;
