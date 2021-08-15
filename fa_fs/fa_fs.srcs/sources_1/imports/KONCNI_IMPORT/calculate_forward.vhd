library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instruction_buffer_type.all;


entity calculate_forward is
  generic (
    PORTS  : POSITIVE;
    NUM_OF_LAYERS : POSITIVE;
    BIT_WIDTH : POSITIVE;
    F : POSITIVE
  );
  port (
    sel  : in  integer range 0 to 31 := 0;
    clk : in std_logic;
    enable : in std_logic;
    X    : in  T_SLVV_8(NUM_OF_LAYERS downto 0);
    W    : in  signed((PORTS+1) * PORTS * BIT_WIDTH - 1 downto 0);
    Y    : out signed(PORTS * BIT_WIDTH - 1 downto 0) := (others => '0');
    st_nevronov_v_nivoju : in stevilo_nevronov_v_nivoju(7 downto 0) := (others=>0)
  );
end;

architecture rtl of calculate_forward is
function f_mult (
    r_a    : in signed;
    r_b    : in signed;
    r_f    : in integer range 0 to 31)
    
    return signed is
        variable v_prod : signed((r_a'length + r_b'length- 1) downto 0);
        variable v_temp2 : signed((r_a'length + r_b'length- 1) downto 0);
        variable v_temp3 : signed((r_a'length + r_b'length- 1) downto 0);
        variable v_temp4 : signed((r_a'length + r_b'length- 1) downto 0);
        variable v_temp5 : signed((r_a'length + r_b'length- 1) downto 0);
    begin
        v_prod := shift_right((r_a*r_b),r_f);
        v_temp2 := shift_right((r_a*r_b),(r_f-1));
        v_temp3 := r_a*r_b;
        v_temp4 :=shift_right((-r_a*r_b),r_f);
        v_temp5 :=shift_right((-r_a*r_b),r_f-1);
        if v_prod = 0 and v_temp2 = 1 then
             v_prod := to_signed(1,v_prod'length);
        end if;
        if v_prod = -1 and v_temp3 < 0 and v_temp4 = 0 and v_temp5 = 0 then
             v_prod := to_signed(0,v_prod'length);
        end if;
return resize(signed(v_prod),r_a'length);
end function f_mult;

component lut
    generic (BIT_WIDTH : integer range 0 to 31;
             F : integer range 0 to 31);
        port (
            clk : in std_logic;
            in_vec : in  signed(BIT_WIDTH-1 downto 0);
            is_valid : in std_logic;
            out_vec_rez : out  signed(BIT_WIDTH-1 downto 0));
end component;

type testiranje is array (0 to PORTS) of signed(BIT_WIDTH-1 downto 0);
type ar is array (0 to PORTS-1, 0 to PORTS) of signed(BIT_WIDTH-1 downto 0);
type testiranje3 is array (0 to PORTS - 1) of signed(BIT_WIDTH-1 downto 0);
signal x_s : testiranje := (others=>(others=>'0'));
--signal y_temps2 : ar := (others=>(others=>(others=>'0')));
type testiranje_w is array (0 to (PORTS+1)*PORTS -1) of signed(BIT_WIDTH-1 downto 0);
signal w_s : testiranje_w := (others=>(others=>'0'));
signal y_temps : testiranje3 := (others=>(others=>'0'));
--signal test_w: testiranje_w := (others=>(others=>'0'));

type tst_w is array (0 to((PORTS+1)*PORTS - 1)) of signed(BIT_WIDTH-1 downto 0);
signal part_sum : tst_w := (others =>(others => '0'));
type bool_array is array (0 to PORTS-1) of std_logic;
signal is_valid : bool_array := (others => '0');

begin
  luts: 
   for I in 0 to PORTS - 1 generate
      luts : lut
       generic map (BIT_WIDTH   => BIT_WIDTH,
                    F => F)
        port map
        (clk => clk,
         in_vec => y_temps(I),
         is_valid => is_valid(I),
         out_vec_rez => y((PORTS-I)*BIT_WIDTH-1 downto (PORTS-1-I) * BIT_WIDTH));
   end generate luts;
          
    process (enable,clk)
    variable sum_aux : testiranje3 := (others=>(others=>'0'));
    variable NUM_OF_NEURONS_VAR :integer range 0 to 31 := 0;
    variable NUM_OF_NEURONS_BEFORE_VAR : integer range 0 to 31 := 0;
    variable pos : signed(79 downto 0);
    variable save_ind : integer range 0 to 511 := 0;
        begin      
            if(rising_edge(clk)) then 
                if (enable = '1') then     
                    NUM_OF_NEURONS_VAR := st_nevronov_v_nivoju(sel + 1);         
                    NUM_OF_NEURONS_BEFORE_VAR := st_nevronov_v_nivoju(sel);
                    x_s <= (others=>(others=>'0'));
                    for I in 0 to PORTS-1 loop
                         x_s(I) <= X(sel)((PORTS - I)*BIT_WIDTH - 1 downto ((PORTS - I - 1)*BIT_WIDTH));
                    end loop;
                    x_s(NUM_OF_NEURONS_BEFORE_VAR) <= shift_left(to_signed(1,BIT_WIDTH),F);
                     
                end if;
            end if; 
            if(rising_edge(clk)) then 
                if (enable = '1') then     
                    --bias gre na zadnje mesto
                    for I in 0 to ((PORTS+1)*PORTS - 1) loop
                         w_s(((PORTS+1)*PORTS - 1) - I) <= W((I+1)*BIT_WIDTH - 1 downto I*BIT_WIDTH);  
                    end loop;
              end if;
            end if; 
            if(rising_edge(clk)) then 
                if (enable = '1') then    
                    save_ind:=0;
                    for I in 0 to ((PORTS+1)*PORTS - 1) loop
                        if(I mod (PORTS+1) <= NUM_OF_NEURONS_BEFORE_VAR) then
                            part_sum(I) <= f_mult(w_s(save_ind), x_s(I mod (PORTS + 1)),F);
                            save_ind := save_ind + 1;
                        else 
                            part_sum(I) <= (others => '0');
                        end if;
                    end loop;
                end if;
            end if; 
            if(rising_edge(clk)) then 
                if (enable = '1') then  
                    y_temps <= (others=>(others=>'0'));
                    sum_aux := (others=>(others=>'0'));
                    for I in 0 to ((PORTS+1)*PORTS - 1) loop
                            sum_aux(I / (PORTS + 1))  := sum_aux(I / (PORTS + 1 )) + part_sum(I);
                            y_temps(I / (PORTS + 1)) <= sum_aux(I / (PORTS + 1));
                    end loop;
                end if;
            end if; 
            if(rising_edge(clk)) then 
                if (enable = '1') then      
                --samo num_of_neurons nevronov gre v lut, ostali ne,  
                --tako da ostanejo na vrednosti 0
                for I in 0 to PORTS - 1 loop
                    if(I < NUM_OF_NEURONS_VAR) THEN
                        is_valid(I) <= '1';
                    else 
                        is_valid(I) <= '0';
                    end if;
                end loop;
            end if;   
      end if; 
end process;  
end rtl;
