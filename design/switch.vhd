library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity switch is
    Generic (data_width: integer := 18);
    Port (clk: in std_logic;
          set: in std_logic;
          mac_in: in std_logic_vector(2*data_width - 1 downto 0);
          voter_in: in std_logic_vector(2*data_width - 1 downto 0);
          switch_out: out std_logic_vector(2*data_width - 1 downto 0));
end switch;

architecture Behavioral of switch is
    signal q, d: std_logic;
    signal switch_s: std_logic_vector(2*data_width - 1 downto 0);
begin
    process(clk) is
    begin
        if (rising_edge(clk)) then
            if (set = '1') then
                q <= '1';
            else
                q <= d;
            end if;
        end if;
    end process;
    
    d <= '1' when (voter_in = switch_s and q = '1') else
         '0';
       
    switch_s <= (others => '0') when (q = '0') else
                mac_in; 
                
    switch_out <= switch_s;
end Behavioral;
