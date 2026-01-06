
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY pingpong_tb IS
END pingpong_tb;

ARCHITECTURE behavior OF pingpong_tb IS

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT pingpong
        Port (
            i_clk : in STD_LOGIC;
            i_rst : in STD_LOGIC;
            i_swL : in STD_LOGIC;
            i_swR : in STD_LOGIC;
            i_random_speed : in STD_LOGIC;
            o_led : out STD_LOGIC_VECTOR (7 downto 0)
        );
    END COMPONENT;

    -- Inputs
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';
    signal swL : std_logic := '0';
    signal swR : std_logic := '0';
    signal random_speed : std_logic := '0'; -- 隨機速度設定為固定低速模式

    -- Outputs
    signal led : std_logic_vector(7 downto 0);

    -- Clock period definitions
    constant clock_period : time := 20 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: pingpong PORT MAP (
        i_clk => clock,
        i_rst => reset,
        i_swL => swL,
        i_swR => swR,
        i_random_speed => random_speed,
        o_led => led
    );

    -- Clock process definitions
    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    -- Stimulus process for simulating the "Ping Pong" game
    stim_proc: process
    begin
        -- Initialize reset
        reset <= '0';
        wait for 100 ns;

        -- Release reset and start game
        reset <= '1';
        wait for 1170 ns;

        -- Simulate: Right player hits the ball, and the ball moves left
        swR <= '1';
        wait for 40 ns;
        swR <= '0';
        wait for 1100 ns;

        -- Simulate: Left player hits the ball, and the ball moves right
        swL <= '1';
        wait for 40 ns;
        swL <= '0';
        wait for 6000 ns;

        -- Repeat the above steps to simulate multiple back-and-forth hits
        swR <= '1';
        wait for 40 ns;
        swR <= '0';
        wait for 600 ns;

        swL <= '1';
        wait for 40 ns;
        swL <= '0';
        wait for 600 ns;

        swR <= '1';
        wait for 40 ns;
        swR <= '0';
        wait for 600 ns;

        swL <= '1';
        wait for 40 ns;
        swL <= '0';
        wait for 600 ns;

        -- Simulate a longer match if necessary
        -- Continue the pattern of hitting the ball between the two players

        wait;
    end process;

END behavior;