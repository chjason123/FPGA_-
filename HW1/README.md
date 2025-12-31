# hw_1

## 簡介

`two_counter` 是一個 VHDL 模組，實現了兩個獨立計數器的功能。每個計數器都是 8 位元，並且可以設定最小值和最大值。此模組使用有限狀態機 (FSM) 來控制兩個計數器之間的切換。

## 模擬結果
<img width="942" height="265" alt="image" src="https://github.com/user-attachments/assets/201f8a04-e2a9-4b4f-9c5b-be5b89af63e6" />
<img width="1050" height="261" alt="image" src="https://github.com/user-attachments/assets/bf8e4c2a-b8d4-466b-bd12-d5bbc9a6b1eb" />


## 模組介面

### Generic 參數

| 參數名稱    | 資料類型          | 預設值     | 說明                                                         |
| ----------- | ----------------- | ---------- | ------------------------------------------------------------ |
| `count1_min_in` | `std_logic_vector(7 downto 0)` | `"00000000"` | 第一個計數器的最小值。                                           |
| `count1_max_in` | `std_logic_vector(7 downto 0)` | `"11111111"` | 第一個計數器的最大值。                                           |
| `count2_min_in` | `std_logic_vector(7 downto 0)` | `"00000000"` | 第二個計數器的最小值。                                           |
| `count2_max_in` | `std_logic_vector(7 downto 0)` | `"11111111"` | 第二個計數器的最大值。                                           |

### Port

| Port 名稱  | 方向 | 資料類型          | 說明                                                         |
| -------- | ---- | ----------------- | ------------------------------------------------------------ |
| `rst`    | in   | `STD_LOGIC`       | 重置訊號。當 `rst` 為 '0' 時，計數器重置為初始狀態。                        |
| `clk`    | in   | `STD_LOGIC`       | 時鐘訊號。                                                     |
| `count1_set` | in   | `STD_LOGIC`       | 第一個計數器的設定訊號。控制計數方向。                               |
| `count2_set` | in   | `STD_LOGIC`       | 第二個計數器的設定訊號。控制計數方向。                               |
| `count1_o` | out  | `STD_LOGIC_VECTOR (7 downto 0)` | 第一個計數器的輸出值。                                           |
| `count2_o` | out  | `STD_LOGIC_VECTOR (7 downto 0)` | 第二個計數器的輸出值。                                           |


## 功能說明

1.  **計數器設定：**
    *   `counter1_value_signal` 和 `counter2_value_signal` 進程根據 `count1_set` 和 `count2_set` 的值，設定計數器的最小值和最大值。
    *   當 `count1_set` 或 `count2_set` 為 '0' 時，最小值保持不變，最大值減 1。
    *   當 `count1_set` 或 `count2_set` 為 '1' 時，最小值加 1，最大值保持不變。

2.  **有限狀態機 (FSM)：**
    *   `FSM` 進程實現了狀態機，用於控制兩個計數器之間的切換。
    *   狀態 `S0` 和 `S1` 分別對應於第一個和第二個計數器的活動狀態。
    *   根據當前狀態和計數器的值，狀態機在 `S0` 和 `S1` 之間切換。


3.  **計數器實現：**
    *   `counter1` 和 `counter2` 進程分別實現了兩個計數器的邏輯。
    *   當 `rst` 為 '0' 時，計數器重置為最小值或最大值，具體取決於 `count1_set` 和 `count2_set` 的值。
    *   在時鐘上升沿，如果對應的 FSM 旗標為 '1'，則計數器遞增或遞減，具體取決於 `count1_set` 和 `count2_set` 的值。

## 使用方法

1.  根據需要設定 generic 參數 `count1_min_in`、`count1_max_in`、`count2_min_in` 和 `count2_max_in`。
2.  將 `rst`、`clk`、`count1_set` 和 `count2_set` 連接到適當的訊號。
3.  從 `count1_o` 和 `count2_o` 讀取計數器的輸出值。
