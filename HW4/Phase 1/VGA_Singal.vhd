library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY VGA_Singal IS
  generic(
    h_pixels  : INTEGER  := 800;
    h_fp      : INTEGER  := 56;
    h_pulse   : INTEGER  := 120;
    h_bp      : INTEGER  := 64;
    h_pol     : STD_LOGIC := '1';
    v_pixels  : INTEGER  := 600;
    v_fp      : INTEGER  := 37;
    v_pulse   : INTEGER  := 6;
    v_bp      : INTEGER  := 23;
    v_pol     : STD_LOGIC := '1'
  );
  PORT (
    pixel_clk   : IN  STD_LOGIC;   -- 由 Clocking Wizard / BUFGMUX 輸入的像素時鐘
    rst         : IN  STD_LOGIC;   -- 同步/非同步重置，外部切換時先拉高
    h_count_out : OUT INTEGER;     -- 以 INTEGER 輸出目前 horizontal count
    v_count_out : OUT INTEGER;     -- 以 INTEGER 輸出目前 vertical count
    h_sync      : OUT STD_LOGIC;
    v_sync      : OUT STD_LOGIC;
    in_image    : OUT STD_LOGIC    -- 當在顯示畫面內時為 '1' (使用 when ... else 實作)
  );
END VGA_Singal;

ARCHITECTURE behavior OF VGA_Singal IS
    CONSTANT h_period : INTEGER := h_pixels + h_fp + h_pulse + h_bp ;
    CONSTANT v_period : INTEGER := v_pixels + v_fp + v_pulse + v_bp ;
    signal h_count : INTEGER RANGE 0 TO h_period - 1 := 0;
    signal v_count : INTEGER RANGE 0 TO v_period - 1 := 0;
begin

  -- VGA 靜態控制與像素計數 (以 pixel_clk 為時鐘)
  process(pixel_clk, rst)
  begin
    if rst = '1' then
      h_count <= 0; 
      v_count <= 0;
      h_sync  <= NOT h_pol;
      v_sync  <= NOT v_pol;
      h_count_out <= 0;
      v_count_out <= 0;
    elsif rising_edge(pixel_clk) then
      -- horizontal counter
      if h_count < h_period - 1 then
        h_count <= h_count + 1;
      else
        h_count <= 0;
        -- vertical counter
        if v_count < v_period - 1 then
          v_count <= v_count + 1;
        else
          v_count <= 0;
        end if;
      end if;

      -- horizontal sync (active based on h_pol and pulse window)
      if h_count < h_pixels + h_fp or h_count >= h_pixels + h_fp + h_pulse then
        h_sync <= NOT h_pol;
      else
        h_sync <= h_pol;
      end if;

      -- vertical sync
      if v_count < v_pixels + v_fp or v_count >= v_pixels + v_fp + v_pulse then
        v_sync <= NOT v_pol;
      else
        v_sync <= v_pol;
      end if;

      -- 將計數器輸出到外部 port（INTEGER）
      h_count_out <= h_count;
      v_count_out <= v_count;
    end if;
  end process;

  -- Concurrent assignment: 使用 when ... else（不在 process 內）
  -- 當在可顯示區域時 in_image 為 '1'，否則為 '0'
  in_image <= '1' when (h_count < h_pixels and v_count < v_pixels and rst='0') else '0';

END behavior;