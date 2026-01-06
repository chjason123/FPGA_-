library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Top_V2 is
  port(
    i_clk     : in  std_logic;                      
    i_rst     : in  std_logic;                      
    mode      : in  std_logic_vector(1 downto 0); -- (保留介面相容性，可不用)

    -- 新增控制信號：決定哪顆球要顯示 (8 bits)
    i_ball_map: in  std_logic_vector(7 downto 0);

    -- 分數改為左右各 4 bit (0..15)
    scoreL    : in  std_logic_vector(3 downto 0);
    scoreR    : in  std_logic_vector(3 downto 0);

    h_sync    : out std_logic;
    v_sync    : out std_logic;
    red_out   : out std_logic_vector(3 downto 0);
    green_out : out std_logic_vector(3 downto 0);
    blue_out  : out std_logic_vector(3 downto 0)
  );
end VGA_Top_V2;

architecture rtl of VGA_Top_V2 is

  -- 僅保留 640x480 時序常數
  CONSTANT C_H_PIXELS_0 : INTEGER := 640;  CONSTANT C_H_FP_0 : INTEGER := 16; CONSTANT C_H_PULSE_0 : INTEGER := 96; CONSTANT C_H_BP_0 : INTEGER := 48; CONSTANT C_H_POL_0 : STD_LOGIC := '1';
  CONSTANT C_V_PIXELS_0 : INTEGER := 480; CONSTANT C_V_FP_0 : INTEGER := 11; CONSTANT C_V_PULSE_0 : INTEGER := 2; CONSTANT C_V_BP_0 : INTEGER := 31; CONSTANT C_V_POL_0 : STD_LOGIC := '1';

  -- Internal Signals (只保留 640 clock path)
  signal clk_640 : std_logic;
  signal mmcm_locked : std_logic;
  signal buf_clk_640 : std_logic;
  signal pixel_clk : std_logic;
  signal in_image : std_logic;
  
  signal h_sync_0, v_sync_0 : std_logic;
  signal h_count_0, v_count_0 : integer;
  signal h_count : integer;
  signal v_count : integer;
  
  signal red_singal   : std_logic_vector(3 downto 0) := (others => '0');
  signal blue_singal  : std_logic_vector(3 downto 0) := (others => '0');
  signal green_singal : std_logic_vector(3 downto 0) := (others => '0');

  signal vga_rst_0 : std_logic := '1';
  signal edge_pulse : std_logic := '0';

  -- Synchronizer signals for detecting pixel clock rising edge in i_clk domain
  signal sync0_1, sync0_2, prev_sync0_2 : std_logic := '0';

  --------------------------------------------------------------------
  -- Functions (保留原有函數)
  --------------------------------------------------------------------
  function is_in_circle(curr_h, curr_v, cx, cy, r_sq : INTEGER) return boolean is
    variable dist_sq : INTEGER;
  begin
    dist_sq := ((curr_h - cx) * (curr_h - cx)) + 
               ((curr_v - cy) * (curr_v - cy));
    if dist_sq < r_sq then return true; else return false; end if;
  end function;

  -- fuzzy_mean_shapes 仍接受 mode，但我們在呼叫時會以 "00" 固定為 640x480
  function fuzzy_mean_shapes(curr_h, curr_v : INTEGER; mode : std_logic_vector; ball_map : std_logic_vector) return std_logic_vector is
    variable seg_width : INTEGER;
    variable cy        : INTEGER;
    variable r_sq      : INTEGER;
    variable cx        : INTEGER;
  begin
    if mode = "00" then
        seg_width := C_H_PIXELS_0 / 8; cy := C_V_PIXELS_0 / 2; r_sq := 900; 
    else
        -- 若傳入非 "00"，還是以 640x480 設定處理
        seg_width := C_H_PIXELS_0 / 8; cy := C_V_PIXELS_0 / 2; r_sq := 900;
    end if;

    for i in 0 to 7 loop
        if ball_map(7-i) = '1' then
            cx := (i * seg_width) + (seg_width / 2);
            if is_in_circle(curr_h, curr_v, cx, cy, r_sq) then
                return "01"; 
            end if;
        end if;
    end loop;
    return "00"; 
  end function;

  -- Component Declarations (保留需要的)
  component VGA_Singal 
    generic(h_pixels, h_fp, h_pulse, h_bp : INTEGER; h_pol : STD_LOGIC; v_pixels, v_fp, v_pulse, v_bp : INTEGER; v_pol : STD_LOGIC);
    port(pixel_clk, rst : in std_logic; h_count_out, v_count_out : out integer; h_sync, v_sync, in_image : out std_logic);
  end component;
  component clk_wiz_0 port (clk_in1, reset : in std_logic; clk_out1, clk_out2, clk_out3, clk_out4, locked : out std_logic); end component;
  component BUFG port (O : out std_logic; I : in std_logic); end component;

  -- blk_num：使用者提供的 digit BRAM (10 digits, each 100x100, arranged horizontally => 1000 x 100)
  component blk_num
    PORT (
      clka : IN STD_LOGIC;
      addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
      douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
  end component;

  -- BRAM interface signals for rendering score
  signal num_addra   : std_logic_vector(16 downto 0) := (others => '0');
  signal num_dout    : std_logic_vector(7 downto 0);
  signal score_pixel_on : std_logic := '0';

  -- constants for digit bitmap
  constant DIGIT_W : integer := 100;
  constant DIGIT_H : integer := 100;
  constant BMP_W   : integer := 1000; -- 10 * 100
  constant BMP_H   : integer := 100;

begin
  -- Clock Instantiation & Buffer (僅使用 clk_out1 -> 640 path)
  clk_wiz_inst : clk_wiz_0 port map(
    clk_in1 => i_clk, reset => '0',
    clk_out1 => clk_640, clk_out2 => open, clk_out3 => open, clk_out4 => open,
    locked => mmcm_locked
  );

  buf_640: BUFG port map (O=>buf_clk_640, I=>clk_640);
  pixel_clk <= buf_clk_640;

  -- VGA Instance (只保留 640x480)
  vga0: VGA_Singal generic map(
    C_H_PIXELS_0, C_H_FP_0, C_H_PULSE_0, C_H_BP_0, C_H_POL_0,
    C_V_PIXELS_0, C_V_FP_0, C_V_PULSE_0, C_V_BP_0, C_V_POL_0
  ) port map(
    pixel_clk, vga_rst_0, h_count_0, v_count_0, h_sync_0, v_sync_0, in_image
  );

  -- Output Logic (單一解析度)
  vga_rst_0 <= '0' when i_rst = '0' else '1';
  h_sync <= h_sync_0;
  v_sync <= v_sync_0;
  h_count <= h_count_0;
  v_count <= v_count_0;
  red_out <= red_singal when in_image = '1' else "0000";
  green_out <= green_singal when in_image = '1' else "0000";
  blue_out <= blue_singal when in_image = '1' else "0000";

  -- BRAM instance for digits (clka 使用 pixel_clk)
  blk_num_inst : blk_num port map(
    clka  => pixel_clk,
    addra => num_addra,
    douta => num_dout
  );

  -- Compute num_addra and whether current pixel is within score area (簡化為固定 640x480)
  score_compute: process(h_count, v_count, scoreL, scoreR)
    variable H_PIXELS : integer := C_H_PIXELS_0;
    variable V_PIXELS : integer := C_V_PIXELS_0;
    variable margin : integer := 10; -- margin from top
    variable side_total_w : integer := 2 * DIGIT_W; -- each side 顯示兩位 (tens, ones)
    variable start_x_left : integer;
    variable start_x_right : integer;
    variable x_in_total : integer;
    variable slot : integer;
    variable x_in_digit : integer;
    variable y_in_digit : integer;
    variable sL_val : integer;
    variable sR_val : integer;
    variable dL_t, dL_o : integer;
    variable dR_t, dR_o : integer;
    variable digit_value : integer;
    variable addr_int : integer;
  begin
    -- 預設
    num_addra <= (others => '0');
    score_pixel_on <= '0';

    start_x_left := margin; -- 左上角
    start_x_right := H_PIXELS - margin - side_total_w; -- 右上角

    -- left side 顯示 scoreL (2 digits)
    if (h_count >= start_x_left) and (h_count < start_x_left + side_total_w) and (v_count >= margin) and (v_count < margin + DIGIT_H) then
      x_in_total := h_count - start_x_left; -- 0 .. side_total_w-1
      slot := x_in_total / DIGIT_W; -- 0 .. 1 (左->右)
      x_in_digit := x_in_total mod DIGIT_W; -- 0..99
      y_in_digit := v_count - margin; -- 0..99

      sL_val := to_integer(unsigned(scoreL));
      if sL_val < 0 then sL_val := 0; elsif sL_val > 15 then sL_val := 15; end if;
      dL_t := sL_val / 10; dL_o := sL_val mod 10;

      if slot = 0 then digit_value := dL_t; else digit_value := dL_o; end if;

      addr_int := y_in_digit * BMP_W + (digit_value * DIGIT_W) + x_in_digit;
      if addr_int < 2**17 then
        num_addra <= std_logic_vector(to_unsigned(addr_int, 17));
        score_pixel_on <= '1';
      else
        num_addra <= (others => '0');
        score_pixel_on <= '0';
      end if;

    -- right side 顯示 scoreR (2 digits)
    elsif (h_count >= start_x_right) and (h_count < start_x_right + side_total_w) and (v_count >= margin) and (v_count < margin + DIGIT_H) then
      x_in_total := h_count - start_x_right; -- 0 .. side_total_w-1
      slot := x_in_total / DIGIT_W; -- 0 .. 1 (左->右)
      x_in_digit := x_in_total mod DIGIT_W; -- 0..99
      y_in_digit := v_count - margin; -- 0..99

      sR_val := to_integer(unsigned(scoreR));
      if sR_val < 0 then sR_val := 0; elsif sR_val > 15 then sR_val := 15; end if;
      dR_t := sR_val / 10; dR_o := sR_val mod 10;

      if slot = 0 then digit_value := dR_t; else digit_value := dR_o; end if;

      addr_int := y_in_digit * BMP_W + (digit_value * DIGIT_W) + x_in_digit;
      if addr_int < 2**17 then
        num_addra <= std_logic_vector(to_unsigned(addr_int, 17));
        score_pixel_on <= '1';
      else
        num_addra <= (others => '0');
        score_pixel_on <= '0';
      end if;

    else
      num_addra <= (others => '0');
      score_pixel_on <= '0';
    end if;
  end process score_compute;

  -- Color Process (傳入 ball_map 與 score), 使用 i_clk 並以 edge_pulse 同步至 pixel clock
  process(i_clk, i_rst)
    variable calc_result : std_logic_vector(1 downto 0);
  begin
    if i_rst = '1' then
       red_singal <= "0000"; blue_singal <= "0000"; green_singal <= "0000";
    elsif rising_edge(i_clk) and edge_pulse = '1' then
        -- 由於現在只支援 640x480，讓 fuzzy_mean_shapes 固定以 "00" 處理
        calc_result := fuzzy_mean_shapes(h_count, v_count, "00", i_ball_map);

        -- 優先顯示 score 的像素 (若 BRAM 的 dout 非 0)
        if score_pixel_on = '1' and num_dout /= x"00" then
           -- score 採用白色顯示 (可改成其他顏色)
           red_singal <= "1111"; green_singal <= "1111"; blue_singal <= "1111";
        elsif calc_result = "01" then          
           red_singal <= "1111"; blue_singal <= "1111"; green_singal <= "0000"; -- 品紅球
        else                                
           -- 預設背景/球顏色 (可調)
           red_singal <= "1111"; blue_singal <= "0000"; green_singal <= "0000";
        end if;
    end if;
  end process;

  -- Synchronizer: 在 i_clk domain 偵測 pixel_clk 的上升緣，產生 edge_pulse
  process(i_clk) 
  begin 
    if rising_edge(i_clk) then
      sync0_1 <= buf_clk_640;
      sync0_2 <= sync0_1;
      prev_sync0_2 <= sync0_2;
      if (sync0_2 = '1' and prev_sync0_2 = '0') then
        edge_pulse <= '1';
      else
        edge_pulse <= '0';
      end if;
    end if;
  end process;

end rtl;