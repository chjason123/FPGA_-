library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_two_counter is
end tb_two_counter;

architecture behavior of tb_two_counter is

    -- 宣告待測元件
    component two_counter
        generic (
            count1_min_in : std_logic_vector(7 downto 0) := "00000001";
            count1_max_in : std_logic_vector(7 downto 0) := "00000011"; -- 測試方便，設最大值為3
            count2_min_in : std_logic_vector(7 downto 0) := "00000001";
            count2_max_in : std_logic_vector(7 downto 0) := "00000010"  -- 測試方便，設最大值為2
        );
        port (
            rst      : in  std_logic;
            clk      : in  std_logic;
			count1_set      : in  std_logic;
			count2_set      : in  std_logic;
            count1_o : out std_logic_vector(7 downto 0);
            count2_o : out std_logic_vector(7 downto 0)
        );
    end component;

    -- 測試訊號
    signal rst      : std_logic := '0';
    signal clk      : std_logic := '0';
	signal count1_set      : std_logic := '1';
	signal count2_set      : std_logic := '0';
    signal count1_o : std_logic_vector(7 downto 0);
    signal count2_o : std_logic_vector(7 downto 0);

begin

    -- 例化 DUT
    uut: two_counter
        generic map (
            count1_min_in => std_logic_vector(to_unsigned(0, 8)),
            count1_max_in => std_logic_vector(to_unsigned(9, 8)), -- 3
            count2_min_in => std_logic_vector(to_unsigned(79, 8)),
            count2_max_in => std_logic_vector(to_unsigned(253, 8))  -- 2
        )
        port map (
            rst      => rst,
            clk      => clk,
            count1_set => count1_set,
            count2_set => count2_set,
            count1_o => count1_o,
            count2_o => count2_o
        );

    -- 產生時脈
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
        wait;
    end process;

    -- 測試流程
    stim_proc: process
    begin
        -- 初始化
        rst <= '0';
        wait for 30 ns;
        rst <= '1';
        wait for 20 ns;
        
  
        -- 讓計數器持續運作
        wait for 200 ns;
        -- 結束模擬
        wait;
    end process;

end behavior;