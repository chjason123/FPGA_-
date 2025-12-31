library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity two_counter is
    generic (
    count1_min_in : std_logic_vector(7 downto 0) := "00000000";  -- 8位元，預設為0
    count1_max_in : std_logic_vector(7 downto 0) := "11111111";  -- 8位元，預設為255
    count2_min_in : std_logic_vector(7 downto 0) := "00000000";  -- 8位元，預設為0
    count2_max_in : std_logic_vector(7 downto 0) := "11111111"   -- 8位元，預設為255
    );
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           count1_set : in STD_LOGIC;
           count2_set : in STD_LOGIC;
           count1_o : out STD_LOGIC_VECTOR (7 downto 0);
           count2_o : out STD_LOGIC_VECTOR (7 downto 0));
end two_counter;

architecture Behavioral of two_counter is

    signal fsm_flag_1 : std_logic ;
    signal fsm_flag_2 : std_logic ;
    signal count1 : std_logic_vector(7 downto 0) ;
    signal count2 : std_logic_vector(7 downto 0) ;
    type state_type is (S0, S1);
    signal state : state_type;
    signal count1_min_value : std_logic_vector(7 downto 0) ;
    signal count1_max_value : std_logic_vector(7 downto 0) ;
    signal count2_min_value : std_logic_vector(7 downto 0) ;
    signal count2_max_value : std_logic_vector(7 downto 0) ;
begin
    
    count1_o <= count1;
    count2_o <= count2;
    
    counter1_value_signal: process(clk, rst)
    begin
        if rst = '0' then
            case count1_set is
                when '0' =>
                    count1_min_value <=count1_min_in;
                    count1_max_value <=count1_max_in-1;
                when '1' =>
                    count1_min_value <=count1_min_in+1;
                    count1_max_value <=count1_max_in;
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    counter2_value_signal: process(clk, rst)
    begin
        if rst = '0' then
            case count2_set is
                when '0' =>
                    count2_min_value <=count2_min_in;
                    count2_max_value <=count2_max_in-1;
                when '1' =>
                    count2_min_value <=count2_min_in+1;
                    count2_max_value <=count2_max_in;
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    
    FSM: process(clk, rst)
    begin
        if rst = '0' then
            state <= S0;
        elsif clk'event and clk='1' then    --fsm程式碼內容
            case state is
                when S0 =>
                    
                    case count1_set is
                        when '0' =>
                            if count1 = count1_max_value  then 
                                state <= S1;
                            end if;
                        when '1' =>
                            if count1 = count1_min_value  then 
                                state <= S1;
                            end if;
                        when others =>
                            null;
                    end case;
                when S1 =>
                    case count2_set is
                        when '0' =>
                            if count2 = count2_max_value  then 
                                state <= S0;
                            end if;
                        when '1' =>
                            if count2 = count2_min_value  then 
                                state <= S0;
                            end if;
                        when others =>
                            null;
                    end case;
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    fsm_flag: process(clk, rst)
    begin
        if rst = '0' then
            fsm_flag_1 <= '0';
            fsm_flag_2 <= '0';
        elsif clk'event and clk='1' then    --fsm程式碼內容
            case state is
                when S0 =>
                    fsm_flag_1 <= '1';
                    fsm_flag_2 <= '0';
                when S1 =>
                    fsm_flag_1 <= '0';
                    fsm_flag_2 <= '1';
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    
    counter1: process(clk, rst)
    begin
        if rst = '0' then
            case count1_set is
                when '0' =>
                    count1 <=count1_min_in;
                when '1' =>
                    count1 <=count1_max_in;
                when others =>
                    null;
            end case;
        elsif rising_edge(clk) and fsm_flag_1='1'then
            case state is
                when S0 =>
                    case count1_set is
                        when '0' =>
                            count1 <=count1 + 1;
                        when '1' =>
                            count1 <=count1 - 1;
                        when others =>
                            null;
                    end case;
                when S1 =>
                    case count1_set is
                        when '0' =>
                            count1 <=count1_min_in;
                        when '1' =>
                            count1 <=count1_max_in;
                        when others =>
                            null;
                    end case;
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    counter2: process(clk, rst)
    begin
        if rst = '0' then
            case count2_set is
                when '0' =>
                    count2 <=count2_min_in;
                when '1' =>
                    count2 <=count2_max_in;
                when others =>
                    null;
            end case;
        elsif rising_edge(clk) and fsm_flag_2='1'then
            case state is
                when S0 =>
                    case count2_set is
                        when '0' =>
                            count2 <=count2_min_in;
                        when '1' =>
                            count2 <=count2_max_in;
                        when others =>
                            null;
                    end case;
                when S1 =>
                    case count2_set is
                        when '0' =>
                            count2 <=count2 + 1;
                        when '1' =>
                            count2 <=count2 - 1;
                        when others =>
                            null;
                    end case;
                when others =>
                    null;
            end case;
        end if;
    end process;

end Behavioral;
