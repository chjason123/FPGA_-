# BreatheLamp

### 功能
- **產生可調整週期/呼吸效果的 PWM 控制訊號（`o_State`）**
- 可由上下按鈕調整 PWM 週期（`n_cycle_PWM`）
- 由內部兩個 FSM 與兩組計數器（`count1`、`count2`）控制：
  - 呼吸上升/下降邊界
  - PWM 輸出時序

### 時序
- 所有順序邏輯以 **`rising_edge(i_clk)`** 為時脈邊緣

### Reset
- **`i_rst`** 為 Active-Low（低有效）

---

## Port（外部介面）

### `i_clk`
- **功能**: 系統時脈。所有同步邏輯於時脈上升緣更新。

---

### `i_rst`
- **功能**: 系統復位，低有效
- **訊號說明**: `i_rst = '0'` 表示 **Reset**

---

### `i_sw`
- **功能**: 速度模式選擇（快丶慢模式）
- **狀態說明**:
  - `0`: **slow 模式**
  - `1`: **fast 模式**

---

### `i_up_button`
- **功能**: 增加 `n_cycle_PWM`

---

### `i_down_button`
- **功能**: 減少 `n_cycle_PWM`

---

### 按鍵行為彙整
透過條件 `sw = i_up_button & i_down_button` 決定：

| **`i_up_button`** | **`i_down_button`** | **功能**            |
|--------------------|---------------------|---------------------|
| `1`                | `0`                | 增加 `n_cycle_PWM`  |
| `0`                | `1`                | 減少 `n_cycle_PWM`  |
| `0`                | `0`                | 無動作              |
| `1`                | `1`                | 無動作              |

---

### `o_State` 
- **功能**: 等於 FSM_2_state，代表 PWM 的狀態輸出

---

### 呼吸邏輯說明
- **`duty_cycle`** 會隨著 **`up_limit`** 與 **`down_limit`** 變大或變小。

---

## 圖片範例
### 圖片 1
![image1](https://github.com/user-attachments/assets/fc01d9b4-9d2b-419b-b2c6-5989e922ded3)

### 圖片 2
![image2](https://github.com/user-attachments/assets/8f69579f-8866-412f-a715-123a9885e766)

---
## 影片範例
[影片](https://youtube.com/shorts/d3pL1bT0k8s)
