library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.txt_util.all;
use work.util_pkg.all;

entity self_purging_fir_tb is
    Generic (red_num: integer := 5;
             fir_ord: integer := 5;
             input_data_width: integer := 18;
             output_data_width: integer := 18);
end self_purging_fir_tb;

architecture Behavioral of self_purging_fir_tb is
    constant period: time := 20 ns;
    signal clk: std_logic;
    signal rst: std_logic;
    file input_test_vector: text open read_mode is "..\..\..\..\..\..\matlab\input.txt";
    file output_check_vector: text open read_mode is "..\..\..\..\..\..\matlab\expected.txt";
    file input_coef: text open read_mode is "..\..\..\..\..\..\matlab\coef.txt";
    signal data_i: std_logic_vector(input_data_width - 1 downto 0);
    signal data_o: std_logic_vector(output_data_width - 1 downto 0);
    signal coef_addr: std_logic_vector(log2c(fir_ord + 1) - 1 downto 0);
    signal coef: std_logic_vector(input_data_width - 1 downto 0);
    signal we: std_logic;
    signal start_check: std_logic := '0';
begin
    duv: entity work.self_purging_fir(Behavioral) 
    generic map (
        fir_ord => fir_ord,
        input_data_width => input_data_width,
        output_data_width => output_data_width
    )
    port map (
        clk => clk,
        rst => rst,
        we => we,
        coef => coef,
        coef_addr => coef_addr,
        data_i => data_i,
        data_o => data_o
    );
    
    clk_gen: process is
    begin
        clk <= '0', '1' after period/2;
        wait for period;
    end process;
    
    stim_gen: process is
        variable tv: line;
    begin     
        -- reset and coefficients input
        data_i <= (others => '0');
        rst <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        for i in 0 to fir_ord loop
            we <= '1';
            coef_addr <= std_logic_vector(to_unsigned(i, log2c(fir_ord + 1)));
            readline(input_coef, tv);
            coef <= to_std_logic_vector(string(tv));
            wait until falling_edge(clk);
        end loop;
        -- input for filtering
        while not endfile(input_test_vector) loop
            readline(input_test_vector, tv);
            data_i <= to_std_logic_vector(string(tv));
            wait until falling_edge(clk);
            start_check <= '1';
        end loop;
        start_check <= '0';
        report "Verification done!" severity failure;
    end process;
    
    check_process: process is
        variable check_v: line;
        variable tmp: std_logic_vector(input_data_width - 1 downto 0);
    begin
        wait until start_check = '1';
        for i in 0 to fir_ord loop
            wait until rising_edge(clk); 
        end loop;
        while (true) loop
            wait until rising_edge(clk);
            readline(output_check_vector, (check_v));
            tmp := to_std_logic_vector(string(check_v));
            if (abs(signed(tmp) - signed(data_o)) > "000000000000001111") then
                report "result mismatch!" severity failure;
            end if;
        end loop;
    end process;
end Behavioral;
