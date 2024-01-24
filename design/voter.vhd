library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_MISC.ALL;
use work.util_pkg.all;

entity voter is
    Generic (inputs_num: integer := 5;
             data_width: integer := 18);
    Port (v_ins: in std_logic_vector(inputs_num*data_width - 1 downto 0);
          v_out: out std_logic_vector(data_width - 1 downto 0));
end voter;

architecture Behavioral of voter is
    signal reduced_ins: std_logic_vector(inputs_num - 1 downto 0);
    signal not_zeroes, threshold: std_logic_vector(log2c(inputs_num) - 1 downto 0);
    signal v_out_s: std_logic_vector(data_width - 1 downto 0);
    signal zero_s: std_logic_vector(log2c(inputs_num) - 1 downto 0) := (others => '0');
    
    type bits_sum_t is array (data_width - 1 downto 0) of std_logic_vector(log2c(inputs_num) - 1 downto 0); 
    signal bits_sum: bits_sum_t;
begin
    process(v_ins) is
    begin
        for i in 0 to inputs_num - 1 loop
            reduced_ins(inputs_num - 1 - i) <= or_reduce(v_ins((inputs_num - i)*data_width - 1 downto (inputs_num - i - 1)*data_width));
        end loop;
    end process;
    
    process(reduced_ins) is
        variable tmp: integer := 0;
    begin
        for i in 0 to inputs_num - 1 loop
            tmp := tmp + to_integer(unsigned'('0' & reduced_ins(i)));
        end loop;
        not_zeroes <= std_logic_vector(to_unsigned(tmp, log2c(inputs_num)));
        tmp := 0;
    end process;
    
    threshold <= '0' & not_zeroes(log2c(inputs_num) - 1 downto 1);
    
    process(v_ins) is
        variable tmp: integer := 0;
    begin
        for i in 0 to data_width - 1 loop
            for j in 0 to inputs_num - 1 loop
                tmp := tmp + to_integer(unsigned'('0' & v_ins((inputs_num - j)*data_width - 1 - i)));
            end loop;
            bits_sum(data_width - 1 - i) <= std_logic_vector(to_unsigned(tmp, log2c(inputs_num)));
            tmp := 0;
        end loop;
    end process;
    
    process(bits_sum, threshold, zero_s) is
    begin
        for i in 0 to data_width - 1 loop
            if (bits_sum(i) > threshold and threshold > zero_s) then
                v_out_s(i) <= '1';
            else
                v_out_s(i) <= '0';
            end if;
        end loop;
    end process;
    
    v_out <= v_out_s;
end Behavioral;