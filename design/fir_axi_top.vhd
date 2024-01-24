library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity fir_axi_top is
    Generic (red_num: integer := 5;
             fir_ord: integer := 5;
             input_data_width: integer := 18;
             output_data_width: integer := 18);
    Port (clk: in std_logic;
          rst: in std_logic;
          we: in std_logic;
          coef_addr: in std_logic_vector(log2c(fir_ord + 1) - 1 downto 0);
          coef: in std_logic_vector(input_data_width - 1 downto 0);
          -- axi input (slave)
          ain_tvalid: in std_logic;
          ain_tready: out std_logic;
          ain_tdata: in std_logic_vector(input_data_width - 1 downto 0);
          ain_tlast: in std_logic;
          -- axi output (master)
          aout_tvalid: out std_logic;
          aout_tready: in std_logic;
          aout_tdata: out std_logic_vector(output_data_width - 1 downto 0);
          aout_tlast: out std_logic);
end fir_axi_top;

architecture Behavioral of fir_axi_top is
    type ain_state_t is (ain_idle, ain_read);
    signal ain_state_reg, ain_state_next: ain_state_t;
    type aout_state_t is (aout_idle, aout_write);
    signal aout_state_reg, aout_state_next: aout_state_t;
    
    signal last_flag_reg, last_flag_next: std_logic;
    signal last_count_reg, last_count_next: std_logic_vector(log2c(2*fir_ord) - 1 downto 0);
    
    signal data_i: std_logic_vector(input_data_width - 1 downto 0);
    signal data_o: std_logic_vector(output_data_width - 1 downto 0);
begin
    self_purging_fir:
    entity work.self_purging_fir(Behavioral)
    generic map (
        red_num => red_num,
        fir_ord => fir_ord,
        input_data_width => input_data_width,
        output_data_width => output_data_width
    )
    port map (
        clk => clk,
        rst => rst,
        we => we,
        coef_addr => coef_addr,
        coef => coef,
        data_i => data_i,
        data_o => data_o
    );
    
    registers:
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                ain_state_reg <= ain_idle;
                aout_state_reg <= aout_idle;
                last_count_reg <= (others => '0');
                last_flag_reg <= '0';
            else 
                ain_state_reg <= ain_state_next;
                aout_state_reg <= aout_state_next;
                last_count_reg <= last_count_next;
                last_flag_reg <= last_flag_next;
            end if;
        end if;
    end process;
    
    ain_protocol:
    process (ain_state_reg, ain_tvalid, aout_tready, ain_tdata, ain_tlast) is
    begin
        ain_state_next <= ain_state_reg;
        ain_tready <= '0';
        data_i <= (others => '0');
        
        case ain_state_reg is
            when ain_idle =>
                if (ain_tvalid = '1' and aout_tready = '1') then
                    ain_state_next <= ain_read;
                end if;
            when ain_read =>
                ain_tready <= '1';
                
                if (ain_tvalid = '1') then
                    data_i <= ain_tdata;
                    if (ain_tlast = '1') then
                        ain_state_next <= ain_idle;
                    end if;
                end if;
            when others =>
        end case;
    end process;
    
    aout_protocol:
    process (aout_state_reg, last_count_reg, last_flag_reg, ain_tvalid, ain_tlast, aout_tready, data_o) is
    begin
        aout_state_next <= aout_state_reg;
        last_count_next <= last_count_reg;
        last_flag_next <= last_flag_reg;
        aout_tvalid <= '0';
        aout_tlast <= '0';
        aout_tdata <= (others => '0');
        
        case aout_state_reg is
            when aout_idle =>
                if (ain_tvalid = '1' and aout_tready = '1') then
                    aout_state_next <= aout_write;
                end if;
            when aout_write =>
                aout_tdata <= data_o;
                aout_tvalid <= '1';
                
                if (ain_tlast = '1') then
                    last_count_next <= std_logic_vector(to_unsigned(1, log2c(2*fir_ord)));
                    last_flag_next <= '1';
                end if;
                
                if (last_flag_reg = '1') then
                    last_count_next <= std_logic_vector(unsigned(last_count_reg) + 1);
                end if;
                
                if (last_count_reg = std_logic_vector(to_unsigned(2*fir_ord - 1, log2c(2*fir_ord)))) then
                    aout_state_next <= aout_idle;
                    aout_tlast <= '1';
                    last_count_next <= (others => '0');
                    last_flag_next <= '0';
                end if;
            when others =>
        end case;
    end process;
end Behavioral;
