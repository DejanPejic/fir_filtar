library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity fir is
    Generic (fir_ord: integer := 5;
             input_data_width: integer := 18;
             output_data_width: integer := 18);
    Port (clk: in std_logic;
          rst: in std_logic;
          we: in std_logic;
          coef_addr: in std_logic_vector(log2c(fir_ord + 1) - 1 downto 0);
          coef: in std_logic_vector(input_data_width - 1 downto 0);
          data_i: in std_logic_vector(input_data_width - 1 downto 0);
          data_o: out std_logic_vector(output_data_width - 1 downto 0));
end fir;

architecture Behavioral of fir is
    type std_2d is array (fir_ord downto 0) of std_logic_vector(2*input_data_width - 1 downto 0);
    signal mac_inter: std_2d := (others => (others => '0'));
    
    type coef_t is array (fir_ord downto 0) of std_logic_vector(input_data_width - 1 downto 0);
    signal b_s: coef_t := (others => (others => '0'));
    
    type u_delay_type is array (1 to fir_ord) of std_logic_vector(input_data_width - 1 downto 0);
    signal u_delay_reg, u_delay_next: u_delay_type;
    
    attribute dont_touch: string;
    attribute dont_touch of mac_inter : signal is "true"; 
begin
    coefficients_loading:
    process(clk) is
    begin
        if (rising_edge(clk)) then
            if (we = '1') then
                b_s(to_integer(unsigned(coef_addr))) <= coef;
            end if;
        end if;
    end process;
    
    u_delay_registers:
    process(clk) is
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                u_delay_reg <= (others => (others => '0'));
            else
                for i in 1 to fir_ord loop
                    u_delay_reg(i) <= u_delay_next(i);
                end loop;
            end if;
        end if;
    end process; 
    
    u_delay1_next_states:
    u_delay_next(1) <= data_i;
    u_delay_next_states:
    for i in 2 to fir_ord generate
        u_delay_next(i) <= u_delay_reg(i - 1);
    end generate;
    
    first_mac:
    entity work.mac(Behavioral)
    generic map (
        input_data_width => input_data_width,
        output_data_width => output_data_width
    )
    port map (
        clk => clk,
        rst => rst,
        u => data_i,
        b => b_s(fir_ord),
        sec_i => (others => '0'),
        sec_o => mac_inter(0)
    );
    
    other_macs:
    for i in 1 to fir_ord generate
        mac: 
        entity work.mac(Behavioral) 
        generic map (
            input_data_width => input_data_width,
            output_data_width => output_data_width
        )
        port map (
            clk => clk,
            rst => rst,
            u => u_delay_reg(i),
            b => b_s(fir_ord - i),
            sec_i => mac_inter(i - 1),
            sec_o => mac_inter(i)
        );
    end generate;
    
    filtar_output:
    data_o <= mac_inter(fir_ord)(2*input_data_width - 2 downto 2*input_data_width - output_data_width - 1);
end Behavioral;