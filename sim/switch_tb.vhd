library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity switch_tb is
    Generic (data_width: integer := 2);
end switch_tb;

architecture Behavioral of switch_tb is
    signal clk, rst: std_logic;
    signal mac_in, voter_in: std_logic_vector(2*data_width - 1 downto 0);
    signal switch_out: std_logic_vector(2*data_width - 1 downto 0);
begin
    duv: entity work.switch(Behavioral)
    generic map (
        data_width => data_width
    )
    port map (
        clk => clk,
        set => rst,
        mac_in => mac_in,
        voter_in => voter_in,
        switch_out => switch_out
    );
    
    clk_gen: process is
    begin
        clk <= '0', '1' after 10 ns;
        wait for 20 ns;
    end process;

    stim_gen: process is
    begin
        mac_in <= X"4";
        voter_in <= X"4";
        rst <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        wait for 100 ns;
        mac_in <= X"D";
        voter_in <= X"D";
        wait;
    end process;
end Behavioral;
