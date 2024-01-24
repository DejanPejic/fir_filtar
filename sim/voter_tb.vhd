----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/21/2024 10:46:58 PM
-- Design Name: 
-- Module Name: voter_tb - Behavioral
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
use work.util_pkg.all;

entity voter_tb is
    Generic (inputs_num: integer := 5;
             data_width: integer := 4);
end voter_tb;

architecture Behavioral of voter_tb is
    signal v_ins: std_logic_vector(inputs_num*data_width - 1 downto 0);
    signal v_out: std_logic_vector(data_width - 1 downto 0);
begin
    duv: entity work.voter(Behavioral)
    generic map (
        inputs_num => inputs_num,
        data_width => data_width
    )
    port map (
        v_ins => v_ins,
        v_out => v_out
    );
    
    stim_gen: process is
    begin
        v_ins <= X"44444";
        wait for 50 ns;
        v_ins <= X"44440";
        wait for 50 ns;
        v_ins <= X"44400";
        wait for 50 ns;
        v_ins <= X"44000";
        wait for 50 ns;
        v_ins <= X"40000";
        wait for 50 ns;
        wait;
    end process;
end Behavioral;
