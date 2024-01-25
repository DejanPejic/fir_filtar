library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mac is
    Generic (input_data_width: integer := 18;
             output_data_width: integer := 18);
    Port (clk: in std_logic;
          ce: in std_logic;
          rst: in std_logic;
          u: in std_logic_vector(input_data_width - 1 downto 0);
          b: in std_logic_vector(input_data_width - 1 downto 0);
          sec_i: in std_logic_vector(2*input_data_width - 1 downto 0);
          sec_o: out std_logic_vector(2*output_data_width - 1 downto 0));
end mac;

architecture Behavioral of mac is
    attribute use_dsp: string;
    attribute use_dsp of Behavioral: architecture is "yes";
    
    signal u_reg, u_next: std_logic_vector(input_data_width - 1 downto 0);
    signal b_reg, b_next: std_logic_vector(input_data_width - 1 downto 0);
    signal sec_reg, sec_next: std_logic_vector(2*input_data_width - 1 downto 0);
    signal res_reg, res_next: std_logic_vector(2*output_data_width - 1 downto 0);
begin
    registers: 
    process(clk) is 
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                u_reg <= (others => '0');
                b_reg <= (others => '0');
                sec_reg <= (others => '0');
                res_reg <= (others => '0');
            elsif (ce = '1') then
                u_reg <= u_next;
                b_reg <= b_next;
                sec_reg <= sec_next;
                res_reg <= res_next;
            end if;
        end if;
    end process;

    registers_next_states:
    u_next <= u;
    b_next <= b;
    sec_next <= sec_i;
    res_next <= std_logic_vector(signed(u_reg)*signed(b_reg) + signed(sec_reg)); 
    
    mac_output:
    sec_o <= res_reg;
end Behavioral;