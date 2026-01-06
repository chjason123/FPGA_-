library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- random_generator (generic output width)
-- Generics:
--  STATE_WIDTH : internal PRNG state width (default 16)
--  OUT_WIDTH   : number of bits to output (must be <= STATE_WIDTH)
--  SHIFT_A/B/C : xorshift shift amounts
--  SEED_HEX    : seed as hex string (most-significant nibble first)
--
-- Behaviour:
--  - synchronous active-high reset (i_rst = '1') loads SEED into state
--  - on rising_edge(i_clk) and i_enable='1' state <= xorshift(state)
--  - o_random_num returns state(STATE_WIDTH-1 downto STATE_WIDTH-OUT_WIDTH)
--    i.e. the MSB side of the state (most-significant OUT_WIDTH bits)

entity random_generator is
  generic (
    STATE_WIDTH : integer := 16;
    OUT_WIDTH   : integer := 16;
    SHIFT_A     : integer := 7;
    SHIFT_B     : integer := 9;
    SHIFT_C     : integer := 8;
    SEED_HEX    : string  := "ACE1"  -- hex string (e.g. "ACE1" -> 0xACE1)
  );
  port (
    i_clk        : in  std_logic;
    i_enable     : in  std_logic;
    i_rst        : in  std_logic; -- synchronous active-high
    o_random_num : out std_logic_vector(OUT_WIDTH-1 downto 0)
  );
end entity random_generator;

architecture rtl of random_generator is

  -- helper: convert hex character to 4-bit vector
  function hexchar_to_nibble(c : character) return std_logic_vector is
    variable res : std_logic_vector(3 downto 0) := (others=>'0');
    variable up  : character := c;
  begin
    if up >= 'a' and up <= 'f' then
      up := character'val(character'pos(up) - 32); -- to upper
    end if;
    if up >= '0' and up <= '9' then
      res := std_logic_vector(to_unsigned(character'pos(up) - character'pos('0'), 4));
    elsif up >= 'A' and up <= 'F' then
      res := std_logic_vector(to_unsigned(10 + character'pos(up) - character'pos('A'), 4));
    else
      res := (others => '0');
    end if;
    return res;
  end function;

  -- helper: convert hex string to std_logic_vector of given width (MSB-first)
  function hexstr_to_slv(s : string; width : integer) return std_logic_vector is
    variable hexlen : integer := s'length;
    variable tmp_len : integer := hexlen * 4;
    variable tmp : std_logic_vector(tmp_len-1 downto 0) := (others => '0');
    variable outv : std_logic_vector(width-1 downto 0) := (others => '0');
    variable i : integer;
    variable nib : std_logic_vector(3 downto 0);
  begin
    -- build tmp (most-significant nibble at tmp(tmp_len-1 downto tmp_len-4))
    for i in 1 to hexlen loop
      nib := hexchar_to_nibble(s(i));
      tmp((tmp_len - 1) - (i-1)*4 downto (tmp_len - i*4)) := nib;
    end loop;

    if width <= tmp_len then
      outv := tmp(tmp_len-1 downto tmp_len-width);
    else
      -- pad MSB side with zeros if requested width > provided hex string bits
      outv(width-1 downto width-tmp_len) := tmp(tmp_len-1 downto 0);
      for i in 0 to width - tmp_len - 1 loop
        outv(i) := '0';
      end loop;
    end if;
    return outv;
  end function;

  -- internal state
  signal state : std_logic_vector(STATE_WIDTH-1 downto 0);

  -- compute SEED constant from SEED_HEX
  constant SEED : std_logic_vector(STATE_WIDTH-1 downto 0) := hexstr_to_slv(SEED_HEX, STATE_WIDTH);

begin



  process(i_clk)
    variable tmp : std_logic_vector(STATE_WIDTH-1 downto 0);
  begin
    if rising_edge(i_clk) then
      if i_rst = '0' then
        state <= SEED;
      elsif i_enable = '1' then
        tmp := state;
        -- xorshift steps (use numeric_std shift_left/shift_right on unsigned)
        tmp := tmp xor std_logic_vector( shift_left(unsigned(tmp), SHIFT_A) );
        tmp := tmp xor std_logic_vector( shift_right(unsigned(tmp), SHIFT_B) );
        tmp := tmp xor std_logic_vector( shift_left(unsigned(tmp), SHIFT_C) );
        state <= tmp;
      end if;
    end if;
  end process;

  -- map MSB OUT_WIDTH bits of state to output
  o_random_num <= state(STATE_WIDTH-1 downto STATE_WIDTH-OUT_WIDTH);

end architecture rtl;