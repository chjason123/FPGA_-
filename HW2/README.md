BreatheLamp 
功能：產生可調整週期/呼吸效果的 PWM 控制訊號（o_State），可由上下按鈕調整 PWM 週期（n_cycle_PWM），並由內部兩個 FSM 與兩組計數器（count1、count2）控制呼吸上升/下降邊界與 PWM 輸出時序。
時序：所有順序邏輯以 rising_edge(i_clk) 為時脈邊緣。
Reset：i_rst 為（active-low）。
Port（外部介面）
i_clk 
功能：系統時脈。所有同步邏輯於時脈上升緣更新。

i_rst 
功能：系統復位，低有效（i_rst = '0' 表示 reset）。

i_sw 
功能：速度模式選擇（slow/fast）。
0 slow / 1 fast

i_up_button 
功能：增加 n_cycle_PWM

i_down_button 
功能：減少 n_cycle_PWM

按鍵行為彙整（由 sw = i_up_button & i_down_button 決定）：
"10" (i_up_button='1', i_down_button='0') → 增加 n_cycle_PWM
"01" (i_up_button='0', i_down_button='1') → 減少 n_cycle_PWM
"00" / "11" → 無動作
o_State : 等於 FSM_2_state。代表 PWM 的狀態輸出