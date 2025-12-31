library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BreatheLamp_tb is
end BreatheLamp_tb;

architecture Testbench of BreatheLamp_tb is
    component BreatheLamp
        port (
            i_clk         : in std_logic;
            i_rst         : in std_logic;
            i_sw         : in std_logic;
            i_up_button   : in std_logic;
            i_down_button : in std_logic;
            o_State       : out std_logic
        );
    end component;

    signal i_sw         : std_logic := '1';
    signal i_clk         : std_logic := '0';
    signal i_rst         : std_logic := '1';
    signal i_up_button   : std_logic := '0';
    signal i_down_button : std_logic := '0';
    signal o_State       : std_logic := '0';


    constant clk_period : time := 10 ns;

begin
    DUT: BreatheLamp
        port map (
            i_clk         => i_clk,
            i_rst         => i_rst,
            i_sw         => i_sw,
            i_up_button   => i_up_button,
            i_down_button => i_down_button,
            o_State       => o_State
        );

    clk_gen: process
    begin
        while true loop
            i_clk <= '0';
            wait for clk_period / 2;
            i_clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;


    stim_proc: process
    begin

		wait for clk_period * 0;
        i_rst <= '0';
        wait for clk_period * 1;
        i_rst <= '1';
        wait for clk_period * 256*12;
--		i_up_button <= '1';
--        wait for clk_period * 1;
--        i_up_button <= '0';
--        wait for clk_period * 1;
--		wait for clk_period * 256*24;
--        i_down_button <= '1';
--        wait for clk_period ;
--        i_down_button <= '0';
--        wait for clk_period ;
--        i_down_button <= '1';
--        wait for clk_period ;
--        i_down_button <= '0';
		wait for clk_period *30;
		
        wait for clk_period * 10;



        wait for clk_period * 100;

        wait;
    end process;
end Testbench;
