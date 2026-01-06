


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;



entity pingpong is
    generic (
        STATE_WIDTH : integer := 16;
        OUT_WIDTH   : integer := 2;
        win_display_count_updown: STD_LOGIC_VECTOR := "00000010"
    );
    Port ( i_clk : in STD_LOGIC; 
           i_rst : in STD_LOGIC;
           i_swL : in STD_LOGIC;
           i_swR : in STD_LOGIC;
           i_random_speed : in STD_LOGIC;
           o_led : out STD_LOGIC_VECTOR (7 downto 0)
           );
end pingpong;

architecture Behavioral of pingpong is
    type STATE_TYPE is (MovingL, MovingR, Lwin, Rwin);
    constant random_count_highest : std_logic_vector(OUT_WIDTH-1 downto 0) := (others => '1');
    signal state : STATE_TYPE;
    signal Slow_pre_state : STATE_TYPE;
    signal High_pre_state : STATE_TYPE;
    signal led_r : STD_LOGIC_VECTOR (7 downto 0);
    signal scoreL : STD_LOGIC_VECTOR (3 downto 0);
    signal scoreR : STD_LOGIC_VECTOR (3 downto 0);
    signal counter : std_logic_vector(24 downto 0);
    signal div_clock    : std_logic;
    signal random_generator_enable    : std_logic;
    signal random_num : std_logic_vector(OUT_WIDTH-1 downto 0) ;
	signal win_display_count : std_logic_vector(7 downto 0);
	signal random_count : std_logic_vector(OUT_WIDTH-1 downto 0) ;
begin

 o_led <= led_r;

 div_clock    <= counter(0); 

 uut: entity work.random_generator
    generic map (
      STATE_WIDTH => STATE_WIDTH,
      OUT_WIDTH   => OUT_WIDTH,
      SHIFT_A     => 7,
      SHIFT_B     => 9,
      SHIFT_C     => 8,
      SEED_HEX    => "ACE1"
    )
    port map (
      i_clk => i_clk,
      i_enable => random_generator_enable,
      i_rst => i_rst,
      o_random_num => random_num
    );

random_enable: process(div_clock, i_rst)
begin
    if i_rst = '0' then
        random_generator_enable <= '0';
    elsif rising_edge(div_clock) then
        if (random_count=random_num and i_random_speed='1') or (random_count=random_count_highest and i_random_speed='0')then
            random_generator_enable <= '1';
        else
            random_generator_enable <= '0';
        end if;
    end if;
end process;

random_counter: process(div_clock, i_rst)
begin
    if i_rst = '0' then
        random_count <= (others => '0');
    elsif rising_edge(div_clock) then
        random_count <= std_logic_vector(unsigned(random_count) + 1);
    end if;
end process;

div_counter: process(i_clk, i_rst)
begin
    if i_rst = '0' then
        counter <= (others => '0');
    elsif rising_edge(i_clk) then
        counter <= std_logic_vector(unsigned(counter) + 1);
    end if;
end process;

win_display_counter: process(i_clk, i_rst)
begin
    if i_rst = '0' then
        win_display_count <= (others => '0');
    elsif rising_edge(i_clk) then
        
        case state is
            when MovingR => --S0 �k����
                win_display_count <= (others => '0');
            when MovingL => --S1 ������
                win_display_count <= (others => '0');
            when Lwin =>    --S3 
                
                if Slow_pre_state = MovingR or (win_display_count<win_display_count_updown and win_display_count/="00000000") then
                    win_display_count <= std_logic_vector(unsigned(win_display_count) + 1);
                else
                    win_display_count <= (others => '0');
                end if;
            when Rwin =>    --S2
                
                if Slow_pre_state = MovingL or (win_display_count<win_display_count_updown and win_display_count/="00000000") then
                    win_display_count <= std_logic_vector(unsigned(win_display_count) + 1);
                else
                    win_display_count <= (others => '0');
                end if;
            when others => 
                 null;
         end case;    
    end if;
end process;

FSM:process(i_clk, i_rst, i_swL, i_swR, led_r)
begin
    if i_rst='0' then
        state <= MovingR;
    elsif i_clk'event and i_clk='1' then
         case state is
            when MovingR => --S0 �k����
                 if (led_r<"00000001") or (led_r > "00000001" and i_swR = '1') then --�klost�δ���
                 --if (led_r > "00000001" and i_swR = '1') then --�klost�δ���
                     state <= Lwin;
                 elsif led_r(0)='1' and i_swR ='1' then --�k���� then
                     state <= MovingL;                     
                 end if;
            when MovingL => --S1 ������
                 if (led_r="00000000") or (led_r < "10000000" and i_swL = '1') then--��lost�δ���
                 --if (led_r < "10000000" and i_swL = '1') then--��lost�δ���
                     state <= Rwin;
                 elsif led_r(7)='1' and i_swL ='1' then --������ then
                     state <= MovingR;                                          
                 end if;
            when Lwin =>    --S3 
                 if i_swL ='1' then
                     state <= MovingR;
                 end if;
            when Rwin =>    --S2
                 if i_swR ='1' then
                     state <= MovingL;
                 end if;
            when others => 
                 null;
        end case;
        High_pre_state<=state;
        
        
    end if;
end process;

LED_P:process(div_clock, i_rst, state,Slow_pre_state)
begin
    if i_rst='0' then
        led_r <= "10000000";
    elsif div_clock'event and div_clock='1' then
        Slow_pre_state<=state;
        case state is
            when MovingR => --S0 �k����
                if Slow_pre_state = Lwin then
                    led_r <= "10000000";
                elsif random_generator_enable='1'then
                    led_r(7) <= '0';
                    led_r(6 downto 0) <= led_r(7 downto 1); --led_r >> 1  
                end if;
            when MovingL => --S1 ������
                if Slow_pre_state = Rwin then
                    led_r <= "00000001";
                elsif random_generator_enable='1'  then
                    led_r(0) <= '0';
                    led_r(7 downto 1) <= led_r(6 downto 0); --led_r << 1      
                end if;
            when Lwin =>    --S3 
                
                if Slow_pre_state = MovingR or (win_display_count<win_display_count_updown and win_display_count/="00000000") then
                    led_r <= "11110000";
                else
                    led_r <= scoreL&scoreR;
                end if;
            when Rwin =>    --S2
                
                if Slow_pre_state = MovingL or (win_display_count<win_display_count_updown and win_display_count/="00000000")then
                    led_r <= "00001111";
                else
                    led_r <= scoreL&scoreR;
                end if;
            when others => 
                 null;
         end case;    
    end if;
end process;

score_L_p:process(i_clk, i_rst, state,High_pre_state)
begin
    if i_rst='0' then
        scoreL <= "0000";
    elsif i_clk'event and i_clk='1' then
         case state is
            when MovingR => --S0 �k����
                null;
            when MovingL => --S1 ������
                null;
            when Lwin =>    --S3 
                if High_pre_state = MovingR then
                    scoreL <= scoreL + '1';
                end if;
            when Rwin =>    --S2
                 null;
            when others => 
                 null;
         end case;    
    end if;
end process;

score_R_p:process(i_clk, i_rst, state,High_pre_state)
begin
    if i_rst='0' then
        scoreR <= "0000";
    elsif i_clk'event and i_clk='1' then
         case state is
            when MovingR => --S0 �k����
                null;
            when MovingL => --S1 ������
                null;
            when Lwin =>    --S3 
                 null; 
            when Rwin =>    --S2
                if High_pre_state = MovingL then
                    scoreR <= scoreR + '1';
                end if;
            when others => 
                 null;
         end case;    
    end if;
end process;


end Behavioral;
