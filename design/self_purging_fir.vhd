library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity self_purging_fir is
    Generic (red_num: integer := 5;
             fir_ord: integer := 5;
             input_data_width: integer := 18;
             output_data_width: integer := 18);
    Port (clk: in std_logic;
          ce: in std_logic;
          rst: in std_logic;
          we: in std_logic;
          coef_addr: in std_logic_vector(log2c(fir_ord + 1) - 1 downto 0);
          coef: in std_logic_vector(input_data_width - 1 downto 0);
          data_i: in std_logic_vector(input_data_width - 1 downto 0);
          data_o: out std_logic_vector(output_data_width - 1 downto 0));
end self_purging_fir;

architecture Behavioral of self_purging_fir is
    type instances_column_t is array (0 to red_num - 1) of std_logic_vector(2*input_data_width - 1 downto 0);
    type instances_array_t is array (fir_ord downto 0) of instances_column_t;
    signal mac_inter: instances_array_t := (others => (others => (others => '0')));
    signal switch_inter: instances_array_t:= (others => (others => (others => '0'))); 
    
    type voter_input_t is array (fir_ord downto 0) of std_logic_vector(red_num*2*input_data_width - 1 downto 0);
    signal voter_input: voter_input_t; 
    
    type voter_array_t is array (fir_ord downto 0) of std_logic_vector(2*input_data_width - 1 downto 0);
    signal voter_inter: voter_array_t; 
    
    type coef_t is array (fir_ord downto 0) of std_logic_vector(input_data_width - 1 downto 0);
    signal b_s: coef_t := (others => (others => '0'));
    
    type u_delay_type is array (1 to fir_ord) of std_logic_vector(input_data_width - 1 downto 0);
    signal u_delay_reg, u_delay_next: u_delay_type;
    
    attribute dont_touch: string;
    attribute dont_touch of mac_inter : signal is "true"; 
    attribute dont_touch of switch_inter : signal is "true"; 
    attribute dont_touch of voter_inter : signal is "true"; 
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
            elsif (ce = '1') then
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
    
    first_mac_modules:
    for i in 0 to red_num - 1 generate
        mac_component:
        entity work.mac(Behavioral)
        generic map (
            input_data_width => input_data_width,
            output_data_width => output_data_width
        )
        port map (
            clk => clk,
            ce => ce,
            rst => rst,
            u => data_i,
            b => b_s(fir_ord),
            sec_i => (others => '0'),
            sec_o => mac_inter(0)(i)
        );
    end generate;
    
    other_macs:
    for j in 1 to fir_ord generate
        mac_modules:
        for i in 0 to red_num - 1 generate
            mac_component:
            entity work.mac(Behavioral)
            generic map (
                input_data_width => input_data_width,
                output_data_width => output_data_width
            )
            port map (
                clk => clk,
                ce => ce,
                rst => rst,
                u => u_delay_reg(j),
                b => b_s(fir_ord - j),
                sec_i => voter_inter(j - 1),
                sec_o => mac_inter(j)(i)
            );
        end generate;
    end generate;
    
    switches:
    for j in 0 to fir_ord generate
        switch_modules:
        for i in 0 to red_num - 1 generate
            switch_component:
            entity work.switch(Behavioral)
            generic map (
                data_width => input_data_width
            )
            port map (
                clk => clk,
                set => rst,
                mac_in => mac_inter(j)(i),
                voter_in => voter_inter(j),
                switch_out => switch_inter(j)(i)
            );
        end generate;
    end generate;
    
    voters:
    for j in 0 to fir_ord generate
        voter_inputs:
        for i in 0 to red_num - 1 generate
            voter_input(j)((red_num - i)*2*input_data_width - 1 downto (red_num - i - 1)*2*input_data_width) <= switch_inter(j)(i);
        end generate;
        
        voter_component:
        entity work.voter(Behavioral)
        generic map (
            inputs_num => red_num,
            data_width => 2*input_data_width
        )
        port map (
            v_ins => voter_input(j),
            v_out => voter_inter(j)
        );
    end generate;
    
    filter_output:
    data_o <= voter_inter(fir_ord)(2*input_data_width - 2 downto 2*input_data_width - output_data_width - 1);
end Behavioral;