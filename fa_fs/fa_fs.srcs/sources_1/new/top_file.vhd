library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_file is
  Port (clk : in STD_LOGIC;
        all_rez: out std_logic_vector(1 downto 0));
end top_file;

architecture Behavioral of top_file is
component neural_network_control is
        GENERIC (         
        NUM_OF_INPUTS : integer range 0 to 31 := 4;  
        NUM_OF_EXAMPLES : integer range 0 to 31:= 16;               
        BIT_WIDTH : integer range 0 to 31 := 16;
        MAX_NEURONS : integer range 0 to 31  := 4;
        NUM_OF_LAYERS : integer range 0 to 31  := 2;
        F : integer range 0 to 31  := 8;
        NEURONS_IN_LAYER : signed (31 downto 0) := x"44200000"
     );
     port(
        ETA : IN signed(BIT_WIDTH - 1 downto 0);
        clk : in STD_LOGIC;
        enable : in STD_LOGIC;
        min_error : in signed(BIT_WIDTH - 1 downto 0);
        done_learning : out std_logic := '0';
        done_test : out std_logic := '0';
        reset : in std_logic := '0';
        inputs : in signed(MAX_NEURONS * NUM_OF_EXAMPLES * BIT_WIDTH - 1 downto 0);
        goals : in signed(MAX_NEURONS * NUM_OF_EXAMPLES * BIT_WIDTH - 1 downto 0);
        learn : in std_logic := '0';
        init_ram : in std_logic := '0';
        total_error_out : out signed(BIT_WIDTH - 1 downto 0) := (others => '0');
        --data_out_test : out signed(MAX_NEURONS * (MAX_NEURONS + 1) * NUM_OF_LAYERS * BIT_WIDTH - 1 downto 0);
        current_y_out : out signed(BIT_WIDTH * MAX_NEURONS - 1  downto 0);
        --current_all_outputs : out signed(MAX_NEURONS * NUM_OF_LAYERS * BIT_WIDTH - 1 downto 0) := (others => '0');
        all_rez : out std_logic_vector(1 downto 0) := (others => '0');
        svl_10 : in std_logic_vector(31 downto 0);
        svl_11 :  in std_logic_vector(31 downto 0);
        svl_12 : in std_logic_vector(31 downto 0);
        svl_13 : in std_logic_vector(31 downto 0)
		--max_epoch_num : in integer
     );
end component;

        signal eta : signed(15 downto 0) := x"0080";
        signal enable :STD_LOGIC := '0';
        signal min_error : signed(15 downto 0) := x"0000";
        signal done_learning :  std_logic := '0';
        signal reset : std_logic := '0';
        signal done_test :  std_logic := '0';
        signal inputs : signed(1024- 1 downto 0) := x"0000000000000000000000000000010000000000010000000000000001000100000001000000000000000100000001000000010001000000000001000100010001000000000000000100000000000100010000000100000001000000010001000100010000000000010001000000010001000100010000000100010001000100";
        signal goals : signed(1024 - 1 downto 0) := x"0000000000000000000001000000000000000100000000000100000000000000000001000000000001000000000000000100000000000000010001000000000000000000000000000000010000000000010001000000000001000000000000000000010000000000000000000000000000000000000000000100010000000000";
        signal learn :  std_logic := '1';
        signal init_ram : std_logic := '0';
        signal done_epoch :  std_logic := '0';
        signal data_out_test :  signed(4 * (4 + 1) * 4 * 16 - 1 downto 0);
        signal current_y_out :  signed(4 * 16 - 1 downto 0);
        signal current_all_outputs :  signed(4 * 4 * 16 - 1 downto 0) := (others => '0');
        signal total_error_out : signed(15 downto 0) := (others => '0');
        
        signal svl_10 : std_logic_vector(31 downto 0) := x"00000000";
        signal svl_11 : std_logic_vector(31 downto 0) := x"00000000";
        signal svl_12 : std_logic_vector(31 downto 0) := x"00000000";
        signal svl_13 : std_logic_vector(31 downto 0) := x"00000000";
begin
nn_c : neural_network_control
generic map(
        NUM_OF_INPUTS => 4, 
        NUM_OF_EXAMPLES => 16,               
        BIT_WIDTH =>16,
        MAX_NEURONS => 4,
        NUM_OF_LAYERS => 2,
        F => 8,
        NEURONS_IN_LAYER => x"44200000")
port map(
        ETA => ETA,
        clk => clk,
        enable => enable,
        min_error => min_error,
        done_learning => done_learning,
        done_test => done_test,
        reset => reset,
        inputs => inputs,
        goals => goals,
        learn => learn,
        init_ram => init_ram,
        total_error_out => total_error_out,
        current_y_out => current_y_out,
        all_rez => all_rez,
        svl_10 => svl_10,
        svl_11 => svl_11,
        svl_12 => svl_12,
        svl_13 => svl_13
);
end Behavioral;
