library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb is
--  Port ( );
end tb;

architecture Behavioral of tb is
        signal clk : STD_LOGIC := '0';
        signal eta : signed(15 downto 0) := x"0080";
        signal enable :STD_LOGIC := '1';
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
        signal all_rez : std_logic_vector(1 downto 0);
        
        signal svl_10 : std_logic_vector(31 downto 0) := x"00000000";
        signal svl_11 : std_logic_vector(31 downto 0) := x"00000000";
        signal svl_12 : std_logic_vector(31 downto 0) := x"00000000";
        signal svl_13 : std_logic_vector(31 downto 0) := x"00000000";
        
begin

    UUT : entity work.neural_network_control port map ( clk => clk,
                                         eta => eta,
                                         reset => reset,
                                         min_error => min_error,
                                         done_learning => done_learning,
                                         done_test => done_test,
                                         enable => enable,
                                         inputs => inputs,
                                         goals => goals,
                                         learn => learn,
                                         all_rez => all_rez,
                                         init_ram => init_ram,
                                         total_error_out => total_error_out,
                                         --data_out_test => data_out_test,
                                         svl_10=> svl_10,
                                         svl_11 => svl_11,
                                         svl_12 => svl_12,
                                         svl_13 => svl_13,
                                         current_y_out => current_y_out);
                                         --current_all_outputs => current_all_outputs);
    
    CLOCK:
        clk <=  '1' after 7.5 ns when clk = '0' else
        '0' after 7.5 ns when clk = '1';
        
    STIMULUS: process
    begin    
    enable <= '1';
    wait for 3ms;
    --enable <= '0';
    --init_ram <= '0';
    --learn <= '0';
    --inputs <= x"01000000000000000000000000000000";
    --wait for 10ns;
    --enable <= '1';
    --wait for 1500ns;
    --enable <= '0';
    --init_ram <= '0';
    --learn <= '0';
    --inputs <= x"01000100000000000000000000000000";
    --wait for 10ns;
    --enable <= '1';
    --wait for 1500ns;
--    wait for 8000ns;
--    enable <= '0';
--    wait for 10ns;
--    learn <= '0';
--    init_ram <= '0';
--    inputs <= x"01000000000000000000000000000000";
--    wait for 10ns;
--    enable <= '1';
--    wait for 8000ns;
--    enable <= '0';
    end process;

end Behavioral;
