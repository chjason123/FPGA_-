library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Top_V2 is
  port(
    i_clk     : in  std_logic;                      
    i_rst     : in  std_logic;                      
    mode      : in  std_logic_vector(1 downto 0);   
    
    h_sync    : out std_logic;
    v_sync    : out std_logic;
    red_out   : out std_logic_vector(3 downto 0);
    green_out : out std_logic_vector(3 downto 0);
    blue_out  : out std_logic_vector(3 downto 0)
  );
end VGA_Top_V2;

architecture rtl of VGA_Top_V2 is

  --------------------------------------------------------------------
  -- VGA Timing Constants (VGA 時序參數定義)
  --------------------------------------------------------------------
  -- 640x480 @ 60Hz
  CONSTANT C_H_PIXELS_0 : INTEGER := 640;
  CONSTANT C_H_FP_0     : INTEGER := 16;
  CONSTANT C_H_PULSE_0  : INTEGER := 96;
  CONSTANT C_H_BP_0     : INTEGER := 48;
  CONSTANT C_H_POL_0    : STD_LOGIC := '1'; -- Negative polarity often '0', code used '1'
  CONSTANT C_V_PIXELS_0 : INTEGER := 480;
  CONSTANT C_V_FP_0     : INTEGER := 11;
  CONSTANT C_V_PULSE_0  : INTEGER := 2;
  CONSTANT C_V_BP_0     : INTEGER := 31;
  CONSTANT C_V_POL_0    : STD_LOGIC := '1';

  -- 800x600 @ 60Hz
  CONSTANT C_H_PIXELS_1 : INTEGER := 800;
  CONSTANT C_H_FP_1     : INTEGER := 56;
  CONSTANT C_H_PULSE_1  : INTEGER := 120;
  CONSTANT C_H_BP_1     : INTEGER := 64;
  CONSTANT C_H_POL_1    : STD_LOGIC := '1';
  CONSTANT C_V_PIXELS_1 : INTEGER := 600;
  CONSTANT C_V_FP_1     : INTEGER := 37;
  CONSTANT C_V_PULSE_1  : INTEGER := 6;
  CONSTANT C_V_BP_1     : INTEGER := 23;
  CONSTANT C_V_POL_1    : STD_LOGIC := '1';

  -- 1024x768 @ 60Hz
  CONSTANT C_H_PIXELS_2 : INTEGER := 1024;
  CONSTANT C_H_FP_2     : INTEGER := 24;
  CONSTANT C_H_PULSE_2  : INTEGER := 136;
  CONSTANT C_H_BP_2     : INTEGER := 144;
  CONSTANT C_H_POL_2    : STD_LOGIC := '1';
  CONSTANT C_V_PIXELS_2 : INTEGER := 768;
  CONSTANT C_V_FP_2     : INTEGER := 3;
  CONSTANT C_V_PULSE_2  : INTEGER := 6;
  CONSTANT C_V_BP_2     : INTEGER := 29;
  CONSTANT C_V_POL_2    : STD_LOGIC := '1';

  -- 1280x720 (Assuming same timing as 1024x768 per your original code logic, or define new ones)
  -- If you meant true 1280x720, please update these constants. 
  -- Here I just copy constants from mode 2 as per your previous request context.
  CONSTANT C_H_PIXELS_3 : INTEGER := 1024; 
  CONSTANT C_H_FP_3     : INTEGER := 24;
  CONSTANT C_H_PULSE_3  : INTEGER := 136;
  CONSTANT C_H_BP_3     : INTEGER := 144;
  CONSTANT C_H_POL_3    : STD_LOGIC := '1';
  CONSTANT C_V_PIXELS_3 : INTEGER := 768;
  CONSTANT C_V_FP_3     : INTEGER := 3;
  CONSTANT C_V_PULSE_3  : INTEGER := 6;
  CONSTANT C_V_BP_3     : INTEGER := 29;
  CONSTANT C_V_POL_3    : STD_LOGIC := '1';

  --------------------------------------------------------------------
  -- Internal Signals
  --------------------------------------------------------------------
  signal clk_640, clk_800, clk_1024, clk_1280 : std_logic;
  signal mmcm_locked : std_logic;
  
  signal buf_clk_640, buf_clk_800, buf_clk_1024, buf_clk_1280 : std_logic;
  signal sel_clk_a, pixel_clk : std_logic;
  signal in_image : std_logic;
  
  signal h_sync_0, h_sync_1, h_sync_2, h_sync_3 : std_logic;
  signal v_sync_0, v_sync_1, v_sync_2, v_sync_3 : std_logic;
  signal in_image_0, in_image_1, in_image_2, in_image_3 : std_logic;
  signal h_count_0, h_count_1, h_count_2, h_count_3 : integer;
  signal v_count_0, v_count_1, v_count_2, v_count_3 : integer;
  
  signal h_count : integer;
  signal v_count : integer;
  
  signal red_singal   : std_logic_vector(3 downto 0) := (others => '0');
  signal blue_singal  : std_logic_vector(3 downto 0) := (others => '0');
  signal green_singal : std_logic_vector(3 downto 0) := (others => '0');

  signal vga_reset : std_logic := '1';
  signal vga_rst_0, vga_rst_1, vga_rst_2, vga_rst_3 : std_logic := '1';

  signal sync0_1, sync0_2 : std_logic := '0';
  signal sync1_1, sync1_2 : std_logic := '0';
  signal sync2_1, sync2_2 : std_logic := '0';
  signal sync3_1, sync3_2 : std_logic := '0';
  
  signal prev_sync0_2, prev_sync1_2, prev_sync2_2, prev_sync3_2 : std_logic := '0';
  signal edge_pulse_0, edge_pulse_1, edge_pulse_2, edge_pulse_3, edge_pulse : std_logic := '0';

  --------------------------------------------------------------------
  -- Functions
  --------------------------------------------------------------------
  function is_in_circle(curr_h, curr_v, cx, cy, r_sq : INTEGER) return boolean is
    variable dist_sq : INTEGER;
  begin
    dist_sq := ((curr_h - cx) * (curr_h - cx)) + 
               ((curr_v - cy) * (curr_v - cy));
    if dist_sq < r_sq then return true; else return false; end if;
  end function;

  function fuzzy_mean_shapes(curr_h, curr_v : INTEGER; mode : std_logic_vector(1 downto 0)) return std_logic_vector is
    variable seg_width : INTEGER;
    variable cy        : INTEGER;
    variable r_sq      : INTEGER;
    variable cx        : INTEGER;
  begin
    -- Dynamic sizing based on resolution constants
    case mode is
      when "00" => 
        seg_width := C_H_PIXELS_0 / 8;
        cy        := C_V_PIXELS_0 / 2;
        r_sq      := 900; 
      when "01" => 
        seg_width := C_H_PIXELS_1 / 8;
        cy        := C_V_PIXELS_1 / 2;
        r_sq      := 1600;
      when "10" => 
        seg_width := C_H_PIXELS_2 / 8;
        cy        := C_V_PIXELS_2 / 2;
        r_sq      := 2500;
      when "11" => 
        -- Assuming you eventually want real 1280x720 logic, using placeholders for now
        seg_width := 1280 / 8; 
        cy        := 720 / 2;
        r_sq      := 3600;
      when others =>
        seg_width := 80; cy := 240; r_sq := 900;
    end case;

    for i in 0 to 7 loop
        cx := (i * seg_width) + (seg_width / 2);
        if is_in_circle(curr_h, curr_v, cx, cy, r_sq) then
            return "01"; 
        end if;
    end loop;
    return "00"; 
  end function;

  --------------------------------------------------------------------
  -- Components
  --------------------------------------------------------------------
  component VGA_Singal 
    generic(
      h_pixels, h_fp, h_pulse, h_bp : INTEGER; h_pol : STD_LOGIC;
      v_pixels, v_fp, v_pulse, v_bp : INTEGER; v_pol : STD_LOGIC
    );
    port(
      pixel_clk, rst : in std_logic;
      h_count_out, v_count_out : out integer;
      h_sync, v_sync, in_image : out std_logic
    );
  end component;

  component clk_wiz_0
    port (
      clk_in1, reset : in std_logic;
      clk_out1, clk_out2, clk_out3, clk_out4, locked : out std_logic
    );
  end component;

  component BUFG port (O : out std_logic; I : in std_logic); end component;
  component BUFGMUX port (I0, I1, S : in std_logic; O : out std_logic); end component;

begin

  --------------------------------------------------------------------
  -- Clock Instantiation
  --------------------------------------------------------------------
  clk_wiz_inst : clk_wiz_0
    port map(
      clk_in1 => i_clk, reset => '0',
      clk_out1 => clk_640, clk_out2 => clk_800, 
      clk_out3 => clk_1024, clk_out4 => clk_1280, locked => mmcm_locked
    );

  buf_640:  BUFG port map (O => buf_clk_640,  I => clk_640);
  buf_800:  BUFG port map (O => buf_clk_800,  I => clk_800);
  buf_1024: BUFG port map (O => buf_clk_1024, I => clk_1024);
  buf_1280: BUFG port map (O => buf_clk_1280, I => clk_1280);

  bufgmux_a: BUFGMUX port map(I0 => buf_clk_640, I1 => buf_clk_800, S => mode(0), O => sel_clk_a);
  bufgmux_b: BUFGMUX port map(I0 => sel_clk_a, I1 => buf_clk_1024, S => mode(1), O => pixel_clk);

  --------------------------------------------------------------------
  -- VGA Instances (using CONSTANTS)
  --------------------------------------------------------------------
  -- Mode 00: 640x480
  vga0: VGA_Singal generic map(
      h_pixels => C_H_PIXELS_0, h_fp => C_H_FP_0, h_pulse => C_H_PULSE_0, h_bp => C_H_BP_0, h_pol => C_H_POL_0,
      v_pixels => C_V_PIXELS_0, v_fp => C_V_FP_0, v_pulse => C_V_PULSE_0, v_bp => C_V_BP_0, v_pol => C_V_POL_0
    )
    
    port map(buf_clk_640, vga_rst_0, h_count_0, v_count_0, h_sync_0, v_sync_0, in_image_0);
  
  -- Mode 01: 800x600
  vga1: VGA_Singal generic map(
      h_pixels => C_H_PIXELS_1, h_fp => C_H_FP_1, h_pulse => C_H_PULSE_1, h_bp => C_H_BP_1, h_pol => C_H_POL_1,
      v_pixels => C_V_PIXELS_1, v_fp => C_V_FP_1, v_pulse => C_V_PULSE_1, v_bp => C_V_BP_1, v_pol => C_V_POL_1
    )
    port map(buf_clk_800, vga_rst_1, h_count_1, v_count_1, h_sync_1, v_sync_1, in_image_1);

  -- Mode 10: 1024x768
  vga2: VGA_Singal generic map(
      h_pixels => C_H_PIXELS_2, h_fp => C_H_FP_2, h_pulse => C_H_PULSE_2, h_bp => C_H_BP_2, h_pol => C_H_POL_2,
      v_pixels => C_V_PIXELS_2, v_fp => C_V_FP_2, v_pulse => C_V_PULSE_2, v_bp => C_V_BP_2, v_pol => C_V_POL_2
    )
    port map(buf_clk_1024, vga_rst_2, h_count_2, v_count_2, h_sync_2, v_sync_2, in_image_2);

  -- Mode 11: 1280x720 (Currently using constants set to 1024x768 values per original code)
  vga3: VGA_Singal generic map(
      h_pixels => C_H_PIXELS_3, h_fp => C_H_FP_3, h_pulse => C_H_PULSE_3, h_bp => C_H_BP_3, h_pol => C_H_POL_3,
      v_pixels => C_V_PIXELS_3, v_fp => C_V_FP_3, v_pulse => C_V_PULSE_3, v_bp => C_V_BP_3, v_pol => C_V_POL_3
    )
    port map(buf_clk_1280, vga_rst_3, h_count_3, v_count_3, h_sync_3, v_sync_3, in_image_3);

  --------------------------------------------------------------------
  -- Output Mux Logic
  --------------------------------------------------------------------
  vga_rst_0 <= '0' when mode = "00" and i_rst = '0' else '1';
  vga_rst_1 <= '0' when mode = "01" and i_rst = '0' else '1';
  vga_rst_2 <= '0' when mode = "10" and i_rst = '0' else '1';
  vga_rst_3 <= '0' when mode = "11" and i_rst = '0' else '1';

  with mode select h_sync <= h_sync_0 when "00", h_sync_1 when "01", h_sync_2 when "10", h_sync_3 when others;
  with mode select v_sync <= v_sync_0 when "00", v_sync_1 when "01", v_sync_2 when "10", v_sync_3 when others;
  with mode select in_image <= in_image_0 when "00", in_image_1 when "01", in_image_2 when "10", in_image_3 when others;
  with mode select h_count <= h_count_0 when "00", h_count_1 when "01", h_count_2 when "10", h_count_3 when others;
  with mode select v_count <= v_count_0 when "00", v_count_1 when "01", v_count_2 when "10", v_count_3 when others;
  
  edge_pulse <= edge_pulse_0 when mode = "00" else 
                edge_pulse_1 when mode = "01" else 
                edge_pulse_2 when mode = "10" else edge_pulse_3;

  red_out   <= red_singal   when in_image = '1' else "0000";
  green_out <= green_singal when in_image = '1' else "0000";
  blue_out  <= blue_singal  when in_image = '1' else "0000";

  --------------------------------------------------------------------
  -- Color Process
  --------------------------------------------------------------------
  process(i_clk, i_rst)
    variable calc_result : std_logic_vector(1 downto 0);
  begin
    if i_rst = '1' then
       red_singal <= "0000"; blue_singal <= "0000"; green_singal <= "0000";
    elsif rising_edge(i_clk) and edge_pulse = '1' then
    
        calc_result := fuzzy_mean_shapes(h_count, v_count, mode);
        
        if calc_result = "01" then          
           red_singal <= "1111"; blue_singal <= "1111"; green_singal <= "0000";
        else                                
           CASE mode IS
            WHEN "00" => red_singal <= "1111"; blue_singal <= "0000"; green_singal <= "0000";
            WHEN "01" => red_singal <= "0000"; blue_singal <= "0111"; green_singal <= "0000";
            WHEN "10" => red_singal <= "0000"; blue_singal <= "0000"; green_singal <= "1111";
            WHEN "11" => red_singal <= "1111"; blue_singal <= "1111"; green_singal <= "1111";
            WHEN OTHERS => red_singal <= "0000"; blue_singal <= "0000"; green_singal <= "0000";
            END CASE;
        end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Synchronizers
  --------------------------------------------------------------------
  process(i_clk)
  begin
    if rising_edge(i_clk) then
      sync0_1 <= buf_clk_640;  sync0_2 <= sync0_1;
      sync1_1 <= buf_clk_800;  sync1_2 <= sync1_1;
      sync2_1 <= buf_clk_1024; sync2_2 <= sync2_1;
      sync3_1 <= buf_clk_1280; sync3_2 <= sync3_1;

      if (sync0_2 = '1' and prev_sync0_2 = '0') then edge_pulse_0 <= '1'; else edge_pulse_0 <= '0'; end if;
      prev_sync0_2 <= sync0_2;

      if (sync1_2 = '1' and prev_sync1_2 = '0') then edge_pulse_1 <= '1'; else edge_pulse_1 <= '0'; end if;
      prev_sync1_2 <= sync1_2;

      if (sync2_2 = '1' and prev_sync2_2 = '0') then edge_pulse_2 <= '1'; else edge_pulse_2 <= '0'; end if;
      prev_sync2_2 <= sync2_2;

      if (sync3_2 = '1' and prev_sync3_2 = '0') then edge_pulse_3 <= '1'; else edge_pulse_3 <= '0'; end if;
      prev_sync3_2 <= sync3_2;
    end if;
  end process;

end rtl;