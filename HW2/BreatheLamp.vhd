library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BreatheLamp is
    port (
        i_clk         : in std_logic;
        i_rst         : in std_logic;
        i_sw          : in std_logic;
        i_up_button   : in std_logic;
        i_down_button : in std_logic;
        o_State       : out std_logic
    );
end BreatheLamp;

architecture Behavioral of BreatheLamp is

    constant up_limit_max_default       : std_logic_vector(7 downto 0) := "11111110";  -- 254
    constant down_limit_max_default     : std_logic_vector(7 downto 0) := "11111110";  -- 254
    constant up_limit_max_fast_default  : std_logic_vector(7 downto 0) := "10000000";  -- 128
    constant down_limit_max_fast_default: std_logic_vector(7 downto 0) := "10000000";  -- 128
    

    signal FSM_1_state : std_logic;
    signal FSM_2_state : std_logic;
    
    signal up_limit    : std_logic_vector(7 downto 0);
    signal down_limit  : std_logic_vector(7 downto 0);
    signal count1      : std_logic_vector(7 downto 0);
    signal count2      : std_logic_vector(7 downto 0);
    

    signal up_limit_max   : std_logic_vector(7 downto 0);
    signal down_limit_max : std_logic_vector(7 downto 0);
    

    signal pwm_state               : std_logic;
    signal pwm_count               : integer range 0 to 20000;
    signal n_cycle_PWM             : integer range 0 to 20000;
    signal n_cycle_PWM_complete    : std_logic;

    
    constant default_n   : integer := 0;--2000;
    constant n_MIN_cycle : integer := 0;
    constant n_MAX_cycle : integer := 20000;
    constant det_n       : integer := 1000;
    

    signal counter : std_logic_vector(24 downto 0);
    signal sw      : std_logic_vector(1 downto 0);
 
    
begin
    o_State <= FSM_2_state;
    sw      <= i_up_button & i_down_button;
   
    

    counter1_value_signal: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            if i_sw = '0' then
                down_limit_max <= down_limit_max_default;
                up_limit_max   <= std_logic_vector(unsigned(up_limit_max_default) );
            else
                down_limit_max <= std_logic_vector(unsigned(down_limit_max_fast_default) );
                up_limit_max   <= up_limit_max_fast_default;
            end if;
        elsif rising_edge(i_clk) then
            if i_sw = '0' then
                down_limit_max <= down_limit_max_default;
                up_limit_max   <= std_logic_vector(unsigned(up_limit_max_default) );
            else
                down_limit_max <= std_logic_vector(unsigned(down_limit_max_fast_default) );
                up_limit_max   <= up_limit_max_fast_default;
            end if;
        end if;
    end process;

    BFA: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            n_cycle_PWM <= default_n; 
        elsif rising_edge(i_clk) then
            case sw is
                when "01" => 
                    if n_cycle_PWM > n_MIN_cycle then
                        n_cycle_PWM <= n_cycle_PWM - det_n;
                    end if;
                when "10" =>  
                    if n_cycle_PWM < n_MAX_cycle then
                        n_cycle_PWM <= n_cycle_PWM + det_n;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;
    

    PWM_cycle_counter: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            n_cycle_PWM_complete <= '0'; 
            pwm_count            <= 0;
        elsif rising_edge(i_clk) then
            if count2 = std_logic_vector(unsigned(down_limit) ) then 
                if pwm_count < n_cycle_PWM then
                    pwm_count            <= pwm_count + 1;
                    n_cycle_PWM_complete <= '0';
                else
                    n_cycle_PWM_complete <= '1';
                    pwm_count            <= 0;
                end if;    
            else
                n_cycle_PWM_complete <= '0';
            end if;
        end if;
    end process;
    

    clk_Frequency_Division: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            counter <= (others => '0');
        elsif rising_edge(i_clk) then
            counter <= std_logic_vector(unsigned(counter) + 1);
        end if;
    end process;
    
    FSM_1: process(i_rst, i_clk)
    begin
        if i_rst = '0' then
            FSM_1_state <= '0';
        elsif rising_edge(i_clk) then    
            case FSM_1_state is
                when '0' =>
                    if up_limit = up_limit_max then 
                        FSM_1_state <= '1';
                    end if;
                when '1' =>
                    if down_limit = down_limit_max then 
                        FSM_1_state <= '0';
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;


    upbnd1: process(i_rst, i_clk)
    begin
        if i_rst = '0' then
            up_limit <= "00000001";
        elsif rising_edge(i_clk) then
            if n_cycle_PWM_complete = '1' then
                if FSM_1_state = '0' then 
                    up_limit <= std_logic_vector(unsigned(up_limit) + 1);
                elsif FSM_1_state = '1' then
                    up_limit <= std_logic_vector(unsigned(up_limit) - 1); 
                end if;
            end if;
        end if;
    end process;

    upbnd2: process(i_rst, i_clk)
    begin
        if i_rst = '0' then
            down_limit <= down_limit_max;
        elsif rising_edge(i_clk) then
            if n_cycle_PWM_complete = '1' then
                if FSM_1_state = '0' then 
                    down_limit <= std_logic_vector(unsigned(down_limit) - 1);
                elsif FSM_1_state = '1' then
                    down_limit <= std_logic_vector(unsigned(down_limit) + 1); 
                end if;
            end if;
        end if;
    end process;
    

    FSM_2: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            FSM_2_state <= '1';
        elsif rising_edge(i_clk) then    
            case FSM_2_state is
                when '0' =>
                    if count2 >= std_logic_vector(unsigned(down_limit) -1) then 
                        FSM_2_state <= '1';
                    end if;
                when '1' =>
                    if count1 >= std_logic_vector(unsigned(up_limit) -1) then 
                        FSM_2_state <= '0';
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;


    counter1: process(i_rst, i_clk)
    begin
        if i_rst = '0' then
            count1 <= (others => '0');
        elsif rising_edge(i_clk) then
            case FSM_2_state is
                when '1' =>
                    count1 <= std_logic_vector(unsigned(count1) + 1);
                when '0' =>
                    count1 <= (others => '0');
                when others =>
                    null;
            end case;
        end if;
    end process;


    counter2: process(i_rst, i_clk)
    begin
        if i_rst = '0' then
            count2 <= (others => '0');
        elsif rising_edge(i_clk) then
            case FSM_2_state is
                when '1' =>
                    count2 <= (others => '0');
                when '0' =>
                    count2 <= std_logic_vector(unsigned(count2) + 1);
                when others =>
                    null;
            end case;
        end if;
    end process;

end Behavioral;