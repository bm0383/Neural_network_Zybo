library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neural_network_control is
        GENERIC (         
        NUM_OF_INPUTS : integer range 0 to 31 := 4;  
        NUM_OF_EXAMPLES : integer range 0 to 31:= 16;               
        BIT_WIDTH : integer range 0 to 31 := 16;
        MAX_NEURONS : integer range 0 to 31  := 4;
        NUM_OF_LAYERS : integer range 0 to 31  := 2;
        F : integer range 0 to 31  := 8;
        NEURONS_IN_LAYER : signed (31 downto 0) := x"44200000"
        --NEURONS_IN_LAYER : signed (31 downto 0) := x"24222100"
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
end neural_network_control;

architecture Behavioral of neural_network_control is
function f_mult (
    r_a    : in signed;
    r_b    : in signed;
    r_f    : in integer range 0 to 31 )
    
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

component neural_network is
    GENERIC (         
        NUM_OF_INPUTS : integer range 0 to 31 ;               
        BIT_WIDTH : integer range 0 to 31 ;
        MAX_NEURONS : integer range 0 to 31 ;
        NUM_OF_LAYERS : integer range 0 to 31 ;
        F : integer range 0 to 31 ;
        NEURONS_IN_LAYER : signed (31 downto 0)
     );
    
    Port (
           clk : in STD_LOGIC;
           ETA : IN signed(BIT_WIDTH - 1 downto 0);
           enable : in STD_LOGIC;
           reset : in std_logic := '0';
           inputs : in signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0);
           done_all : out std_logic := '0';
           goals : in signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0);
           --data_out_test : out signed(MAX_NEURONS * (MAX_NEURONS + 1) * NUM_OF_LAYERS * BIT_WIDTH - 1 downto 0);
           learn : in std_logic;
           init_ram : in std_logic;
           init_ram_we : in std_logic;
           address_for_ram_init : in integer range 0 to 31  := 0;
           init_weights : in signed(MAX_NEURONS * (MAX_NEURONS + 1) * BIT_WIDTH - 1 downto 0);
           napaka : out signed(BIT_WIDTH - 1 downto 0);
           --all_outputs : out signed(MAX_NEURONS * NUM_OF_LAYERS * BIT_WIDTH - 1 downto 0) := (others => '0');
           y_out : out signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others=>'0'));      
    end component;  
    
    signal current_input : signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := inputs(inputs'LENGTH - 1 downto inputs'LENGTH - (MAX_NEURONS * BIT_WIDTH));
    signal current_goals : signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := goals(goals'LENGTH - 1 downto  goals'LENGTH - (MAX_NEURONS * BIT_WIDTH));
    signal current_done : std_logic := '0';
    signal current_addr : integer range 0 to 31  := 0;
    signal current_weight : signed(MAX_NEURONS * (MAX_NEURONS + 1) *  BIT_WIDTH - 1 downto 0);
    signal current_error : signed(BIT_WIDTH - 1 downto 0) := (others => '0');
    signal current_example : integer range 0 to 31  := 0;
    signal enable_temp : std_logic := '0';
    signal total_error_temp : signed(BIT_WIDTH -1 downto 0) := (others => '0');
    signal sel_div : integer range 0 to 31  := 0;
    signal delay_init : integer range 0 to 31  := 4;
    signal done_init : std_logic := '0';
    signal done_epoch : std_logic := '0';
    signal all_weights_wector : std_logic_vector(127 downto 0) := (others => '0');
    signal init_ram_we : std_logic := '0';
    signal init_ram_in_progress : std_logic := '1';
    TYPE State_type IS (START_STATE, INIT_RAM_STATE, LEARN_STATE, TEST_STATE,FINAL_STATE); 
    SIGNAL State : State_Type;
    signal done_loading : std_logic := '1';
    signal total_error : signed(BIT_WIDTH - 1 downto 0) := (others => '0');
    --signal epoch_num : integer range 0 to 31  := 0;
    signal change_num : std_logic :='0';
    signal period : integer := 0;
    --samo za example s 4 primeri
    signal current_y : signed(BIT_WIDTH * MAX_NEURONS - 1  downto 0) := (others => '0');
    signal all_rez_temp : std_logic_vector(1 downto 0) := (others => '0');
    signal max_epoch_num : integer := 10000;
    signal epoch_num : integer := 0;
begin

current_y_out <= current_y;

--za prikaz binarnega rezultata, gledamo ce je rezulat vecji od x0080
-- poseben primer je rezultat x0100

process(clk)
begin
   if(rising_edge(clk)) then
        period <= period + 1;
   end if;
end process;

process(clk) 
begin
    if(rising_edge(clk)) then
        all_rez(1) <= (current_y(55) or current_y(56));
        all_rez(0) <= (current_y(39) or current_y(40));
    end if;
end process;

--process(done_epoch)
--begin
--    if(rising_edge(done_epoch)) then
--        if(learn = '1') then
--            all_rez <= all_rez_temp;
--        else
--            all_rez <= (others => '0');
--        end if;
--    end if;
--end process;


--AVTOMAT
process(clk, enable)
begin
    if(enable = '0' or reset = '1') then
        State <= START_STATE;
    elsif(rising_edge(clk)) then
        case State is 
            when START_STATE =>
                epoch_num <= 0;  
                done_test <= '0';
                if(enable = '1') then
                    if(init_ram = '1') then
                        State <= INIT_RAM_STATE;  
                    else
                        if(learn = '1') then
                            State <= LEARN_STATE;
                        else
                            State <= TEST_STATE;
                        end if;  
                    end if;   
                end if;
                
            when INIT_RAM_STATE => 
                if(init_ram_in_progress = '0') then
                    if(learn = '1') then
                        State <= LEARN_STATE;
                    else
                        State <= TEST_STATE;
                    end if;   
                end if;
                
            when LEARN_STATE =>
                if(done_epoch = '1') then
                    State <= FINAL_STATE;
                    epoch_num <= epoch_num + 1;
                else
                    State <= LEARN_STATE;
                end if;
                
            when TEST_STATE =>
                if(current_done = '1') then
                    State <= FINAL_STATE;
                else
                    State <= TEST_STATE;
                end if;
                
            when FINAL_STATE => 
                if(learn = '1') then
                    if(total_error < min_error or epoch_num > (max_epoch_num * 2))then
                        State <= FINAL_STATE;
                        done_learning <= '1';
                    else
                        done_learning <= '0';
                        State <= LEARN_STATE;
                    end if;
                else
                    done_test <= '1';
                end if;
        end case;
    end if;
end process;

--nastavljanje zacetnih utezi... 
--predpostavljamo da se uporabi 4 registre po 32 bitov = 128 bitov
--predpostavljamo da se upoabi 4 bite za inicializacijo.. pomeni 32 utezi

all_weights_wector <= svl_10 & svl_11 & svl_12 & svl_13;
current_weight(current_weight'length - 1 downto current_weight'length - (((MAX_NEURONS * (MAX_NEURONS + 1)) * 4)))
<= signed(all_weights_wector(all_weights_wector'length - 1 - (current_addr * ((MAX_NEURONS * (MAX_NEURONS + 1)) * 4) ) 
downto (all_weights_wector'length - ((MAX_NEURONS * (MAX_NEURONS + 1)) * 4)) - (current_addr * ((MAX_NEURONS * (MAX_NEURONS + 1)) * 4) )));


process(clk)
begin
    if rising_edge(clk) and State = INIT_RAM_STATE then
        if(current_addr = NUM_OF_LAYERS - 1) then
             done_init <= '1';
        end if;
        if(sel_div = 1) then
            init_ram_we <= '1';
        else
            init_ram_we <= '0';
        end if;
        if(sel_div = delay_init and done_init = '0') then
            current_addr <= current_addr + 1;   
        end if;
        if(done_init = '1' and sel_div = delay_init) then
           init_ram_in_progress <= '0';
        end if;
    end if;
end process;


--divider za clock
process(clk)
begin
  if rising_edge(clk) and State = INIT_RAM_STATE then
   if sel_div = delay_init then
        sel_div <= 0;
    else
        sel_div <= sel_div + 1;
    end if;
 end if;
end process;

process(clk)
begin
    if(rising_edge(clk) ) then
        if(State /= FINAL_STATE) then
            if(current_example /= NUM_OF_EXAMPLES and enable_temp = '1') then
                total_error_temp <= total_error_temp + current_error;    
            end if;
         else
            total_error_temp <= (others => '0');
        end if; 
    end if;
end process;

process(clk)
begin
    if(rising_edge(clk)) then
        if(current_example = NUM_OF_EXAMPLES) then
            done_epoch <= '1';
            total_error <= f_mult(total_error_temp,to_signed(16,16),8);
            total_error_out <= f_mult(total_error_temp,to_signed(16,16),8);
            current_input <= (others => '0');
            current_goals <= (others => '0');
        else
            done_epoch <= '0';
            current_input <= inputs(MAX_NEURONS * NUM_OF_EXAMPLES * BIT_WIDTH - 1 - (current_example * BIT_WIDTH * MAX_NEURONS) downto MAX_NEURONS * NUM_OF_EXAMPLES * BIT_WIDTH - ((current_example + 1) * BIT_WIDTH * MAX_NEURONS));
            current_goals <= goals(MAX_NEURONS * NUM_OF_EXAMPLES * BIT_WIDTH - 1 - (current_example * BIT_WIDTH * MAX_NEURONS) downto MAX_NEURONS * NUM_OF_EXAMPLES * BIT_WIDTH - ((current_example + 1) * BIT_WIDTH * MAX_NEURONS));
        end if;
    end if;
end process;


--process, ki menja vhode v nevronsko mrezo
--takrat ko jo ucimo... vsi primeri gredo notr
process(clk)
begin
    if(rising_edge(clk)) then
        if(State = LEARN_STATE and current_done = '1') then
            if(enable_temp = '1') then
                enable_temp <= '0';
            else
                current_example <= current_example + 1;
            end if;
        elsif(State = LEARN_STATE and current_example /= NUM_OF_EXAMPLES) then
            enable_temp <= '1';
        elsif(State = FINAL_STATE or State = START_STATE)  then
            current_example <= 0;
            enable_temp <= '0';
        elsif(State = TEST_STATE) then
            current_example <= 0;
            enable_temp <= '1';
        else
            enable_temp <= '0';
        end if;
    end if;
end process;

nn : neural_network
generic map(
    NUM_OF_INPUTS => NUM_OF_INPUTS,   
    BIT_WIDTH =>  BIT_WIDTH,
    MAX_NEURONS => MAX_NEURONS,
    NUM_OF_LAYERS => NUM_OF_LAYERS,
    F => F,
    NEURONS_IN_LAYER => NEURONS_IN_LAYER)
    
port map(
    eta => eta,
    clk => clk,
    reset => reset,
    enable => enable_temp,
    inputs => current_input,
    done_all => current_done,
    goals => current_goals,
    --data_out_test => data_out_test,
    learn => learn,
    init_ram_we => init_ram_we,
    init_ram => init_ram_in_progress,
    address_for_ram_init => current_addr,
    init_weights => current_weight,
    napaka => current_error,
    --all_outputs => current_all_outputs,
    y_out => current_y  
);
end Behavioral;
