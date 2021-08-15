library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instruction_buffer_type.all;

entity neural_network is
    GENERIC (         
        NUM_OF_INPUTS : integer range 0 to 31;               
        BIT_WIDTH : integer range 0 to 31;
        MAX_NEURONS : integer range 0 to 31;
        NUM_OF_LAYERS : integer range 0 to 31;
        F : integer range 0 to 31;
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
           data_out_test : out signed(MAX_NEURONS * (MAX_NEURONS + 1) * NUM_OF_LAYERS * BIT_WIDTH - 1 downto 0);
           learn : in std_logic;
           init_ram : in std_logic;
           init_ram_we : in std_logic;
           address_for_ram_init : in integer range 0 to 31 := 0;
           init_weights : in signed(MAX_NEURONS * (MAX_NEURONS + 1) * BIT_WIDTH - 1 downto 0);
           napaka : out signed(BIT_WIDTH - 1 downto 0) := (others => '0');
           --all_outputs : out signed(MAX_NEURONS * NUM_OF_LAYERS * BIT_WIDTH - 1 downto 0) := (others => '0');
           y_out : out signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others=>'0'));         
end neural_network;


architecture Behavioral of neural_network is
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

component calculate_forward is
  generic (
    PORTS  : POSITIVE;
    NUM_OF_LAYERS : POSITIVE;
    BIT_WIDTH : POSITIVE;
    F : POSITIVE
  );
  port (
    sel  : in  integer range 0 to 31 := 0 ;
    clk : in std_logic;
    enable : in std_logic;
    X    : in  T_SLVV_8(NUM_OF_LAYERS downto 0);
    W    : in  signed((PORTS+1) * PORTS * BIT_WIDTH - 1 downto 0);
    Y    : out T_SLV_8 := (others => '0');
    st_nevronov_v_nivoju : in stevilo_nevronov_v_nivoju(7 downto 0) := (others=>0)
  );
end component;


component weight_ram is
 GENERIC (                        
        BIT_WIDTH : integer range 0 to 31;
        MAX_NEURONS : integer range 0 to 31;
        NUM_OF_LAYERS : integer range 0 to 31
     );
    Port ( clk : in STD_LOGIC;
           we : in STD_LOGIC;
           addr : in natural;
           reset : in std_logic := '0';
           data_out_test : out signed(MAX_NEURONS * (MAX_NEURONS + 1) * NUM_OF_LAYERS * BIT_WIDTH - 1 downto 0);
           data_in : in signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0);
           data_out : out signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0));
end component;

component calculate_backward is
GENERIC (                      
	BIT_WIDTH : integer range 0 to 31;
	MAX_NEURONS : integer range 0 to 31;
	NUM_OF_LAYERS : integer range 0 to 31;
	F : integer range 0 to 31;
	NEURONS_IN_LAYER : signed (31 downto 0));

Port ( sel  : in  integer range 0 to 31 := 0;
	   clk : in STD_LOGIC;
	   enable : in std_logic;
	   goals : in signed (BIT_WIDTH * MAX_NEURONS  - 1 downto 0);
	   outputs : in signed (BIT_WIDTH * MAX_NEURONS  - 1 downto 0);
	   inputs_in :  in signed(BIT_WIDTH * MAX_NEURONS  - 1 downto 0);
	   weights : in signed ((MAX_NEURONS + 1) * BIT_WIDTH * MAX_NEURONS  - 1 downto 0);
	   delta_in : in signed (MAX_NEURONS * BIT_WIDTH - 1 downto 0):= (others => '0');
	   delta_out : out signed (MAX_NEURONS * BIT_WIDTH - 1  downto 0) := (others => '0');
	   if_end : in std_logic := '1';
	   weights_update : out signed((MAX_NEURONS + 1) * BIT_WIDTH * MAX_NEURONS  - 1  downto 0);
	   eta : in signed(BIT_WIDTH - 1 downto 0);
	   st_nevronov_v_nivoju : in stevilo_nevronov_v_nivoju(7 downto 0) := (others=>0));
end component;

signal outputs : signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others => '0');
signal inputs_in : signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others => '0');
signal if_end : std_logic := '1';
signal delta_out : signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others => '0');
signal delta_in : signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others => '0');
signal num_of_before : integer range 0 to 31 := 0;
signal x_t : T_SLVV_8(NUM_OF_LAYERS downto 0) := (others =>(others =>'0'));
signal write_enable : std_logic := '0';
signal addr : integer range 0 to 31 := 0;
signal weight_save : signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others=>'0');
signal current_weights : signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others=>'0');
signal nevron_array : stevilo_nevronov_v_nivoju(7 downto 0) := (others => 0); 
signal calc_enable : std_logic := '1';
signal y_t : signed(MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others =>'0');
signal ind_for_res : integer range 0 to 31 := 0;
signal ind_for_addr : integer range 0 to 31 := 0;
signal ind_back_addr : integer  range 0 to 31 := NUM_OF_LAYERS - 1;
signal count_lay : integer range 0 to 31 := 0;

signal w_inputs : signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others=>'0');
signal w_inputs_pop : signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others=>'0');


signal sel_div : integer range 0 to 31 := 0;
signal done : std_logic := '0';
--signal y : signed(MAX_NEURONS * BIT_WIDTH * (NUM_OF_LAYERS) - 1 downto 0) := (others=>'0');
signal ram_address :integer := 0;

signal delay_for : integer range 0 to 31 := 4;
signal delay_prepare_for : integer range 0 to 31 := 1;
signal delay_back : integer range 0 to 31 := 6;
signal delay_prepare_back : integer range 0 to 31 := 5;
signal delay_prepare_back_prepare : integer range 0 to 31 := 1;

TYPE State_type IS (RESET_STATE, PREPARE_FORWARD_STATE, FORWARD_STATE, SAVE_FOR_STATE, FINAL_FORWARD_STATE, PREPARE_BACK_STATE,BACK_STATE, SAVE_BACK_STATE, FINAL_STATE); 
SIGNAL State : State_Type;   
signal done_for : std_logic := '0';
signal enable_for_calc : std_logic := '0';
signal enable_back_calc : std_logic := '0';
signal done_back : std_logic:= '0';
signal ind_back_calc : integer range 0 to 31 := NUM_OF_LAYERS - 1;

signal addr_temp : integer range 0 to 31:= 0;
signal w_inputs_temp :signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0) := (others=>'0');

begin

process(clk)
begin
    for I in 1 to NUM_OF_LAYERS loop
        --all_outputs(I * BIT_WIDTH * MAX_NEURONS - 1 downto (I - 1)* BIT_WIDTH * MAX_NEURONS) <= x_t(I);
    end loop;
end process;
  
--AVTOMAT
    process(clk, enable)
    begin
        if(enable = '0' or reset = '1') then
            State <= RESET_STATE;
        elsif(rising_edge(clk)) then
            case State is 
            
                when RESET_STATE =>
                    if(enable = '1') then
                        State <= PREPARE_FORWARD_STATE;
                    end if;
                    
                when  PREPARE_FORWARD_STATE =>
                    if(enable = '1') then
                        if(sel_div = delay_prepare_for) then
                            State <= FORWARD_STATE;
                        end if;
                   end if;
                   
               when  FORWARD_STATE => 
                    if(sel_div = delay_for) then
                            State <=  SAVE_FOR_STATE;
                    else
                           State <= FORWARD_STATE;
                    end if;
                    
               when SAVE_FOR_STATE =>
                    if(sel_div = delay_prepare_for) then
                        if(ind_for_res = NUM_OF_LAYERS) then
                            State <= FINAL_FORWARD_STATE;
                        else
                            State <= PREPARE_FORWARD_STATE;
                        end if;
                    end if;
                    
               when FINAL_FORWARD_STATE =>
                    if(learn = '1') then
                        State <= PREPARE_BACK_STATE;
                    else
                        State <= FINAL_STATE;
                    end if;
                    
               when PREPARE_BACK_STATE =>
                   if(sel_div = delay_prepare_back_prepare) then
                        State <= BACK_STATE;
                   else
                        State <= PREPARE_BACK_STATE;
                   end if;
               when BACK_STATE =>
                    if(sel_div = delay_back) then
                        State <= SAVE_BACK_STATE;
                    else
                        State <= BACK_STATE;
                    end if;
                    
              when SAVE_BACK_STATE =>
                    if(sel_div = delay_prepare_back) then
                        if(ind_back_calc = 0) then
                            State <= FINAL_STATE;
                        else
                            State <= PREPARE_BACK_STATE;
                        end if;
                    else
                        State <= SAVE_BACK_STATE;
                    end if;
                    
              when FINAL_STATE =>
                State <= FINAL_STATE;
                
            end case;
        end if;
end process;

process(clk)
begin
    if(rising_edge(clk)) then
        if(State = FINAL_STATE) then
            done_all <= '1';
        else
            done_all <= '0';
        end if;
    end if;
end process;

--done_all natiman + izhodi
process(clk)
begin
    if(rising_edge(clk)) then
        if(State = FINAL_FORWARD_STATE) then
            y_out <= x_t(NUM_OF_LAYERS);
        end if;
    end if;
end process;

process(clk)
begin
    if(rising_edge(clk)) then
        if(State = FORWARD_STATE) then
            enable_for_calc <= '1';
        else
            enable_for_calc <= '0';
        end if;
    end if;
end process;

process(clk)
  begin
  if rising_edge(clk) then
    if(enable = '1' and State = FORWARD_STATE) then
            if sel_div = delay_for then
                sel_div <= 0;
            else
                sel_div <= sel_div + 1;
            end if;
     elsif(enable = '1' and (State = PREPARE_FORWARD_STATE or State = SAVE_FOR_STATE)) then
            if sel_div = delay_prepare_for then
                sel_div <= 0;
            else
                sel_div <= sel_div + 1;
            end if;
      elsif(enable = '1' and (State = BACK_STATE)) then
            if sel_div = delay_back then
                sel_div <= 0;
            else
                sel_div <= sel_div + 1;
            end if;      
      elsif(enable = '1' and ( State = SAVE_BACK_STATE)) then
            if sel_div = delay_prepare_back then
                sel_div <= 0;
            else
                sel_div <= sel_div + 1;
            end if;
      elsif(enable = '1' and State = PREPARE_BACK_STATE ) then
            if sel_div = delay_prepare_back_prepare then
                sel_div <= 0;
            else
                sel_div <= sel_div + 1;
        end if;
     
     elsif(State = RESET_STATE) then
        sel_div <= 0;
     end if;
 end if;
 end process;
           
--spreminjanje nivoja za racunanje    
process(clk)
begin
    if(rising_edge(clk)) then 
        if(sel_div = 1 and State = PREPARE_FORWARD_STATE) then
            ind_for_res <= ind_for_res + 1;
        elsif(State = RESET_STATE) then
            ind_for_res <= 0;
        else
            ind_for_res <= ind_for_res;
        end if;
    else
        ind_for_res <= ind_for_res;
    end if;
end process;

process(clk)
begin
    if(rising_edge(clk)) then
        if(State = SAVE_FOR_STATE and sel_div = 0) then
            x_t(ind_for_res) <= y_t;
        elsif(sel_div = 0 and ind_for_res = 0 and State <= PREPARE_FORWARD_STATE) then
             x_t(0) <= inputs;
        elsif(State = RESET_STATE) then
            x_t <= (others=>(others=>'0'));
        else
            x_t <= x_t;  
        end if; 
    end if;
    
    if(rising_edge(clk)) then
        if(sel_div = 0 and State = SAVE_FOR_STATE) then
            ind_for_addr <= ind_for_addr + 1;
        elsif(State = RESET_STATE) then
            ind_for_addr <= 0;
        end if;
    end if;
end process;

process(clk)
begin
    if(rising_edge(clk)) then
        if(State = PREPARE_FORWARD_STATE or State = FORWARD_STATE)then
            addr <= ind_for_addr;
        elsif(State = PREPARE_BACK_STATE or State = BACK_STATE or State = SAVE_BACK_STATE) then
            addr <= ind_back_addr;
        end if;
    end if;
end process;
      
process(clk)
  begin
  for I in 0 to 7 loop
     nevron_array(I) <= to_integer(unsigned(NEURONS_IN_LAYER(31 - I*4 downto 32 - (I+1) * 4)));
  end loop; 
end process;

process(clk)
begin
    if(rising_edge(clk)) then
        if(State = PREPARE_BACK_STATE) then
            outputs <= x_t(ind_back_calc + 1);
            inputs_in <= x_t(ind_back_calc);
            delta_in <= delta_out;         
            num_of_before <= nevron_array(ind_back_calc); 
            if(ind_back_calc = NUM_OF_LAYERS - 1) then
                if_end <= '1';
            else
                if_end <= '0';
            end if;
        end if;
        
        if(State = BACK_STATE) then
            enable_back_calc <= '1';
        else
            enable_back_calc <= '0';
        end if;
    end if;
end process;

process(clk)
	variable save_ind : integer range 0 to 80 := (MAX_NEURONS + 1) * MAX_NEURONS - 1;
begin
    if(State = SAVE_BACK_STATE and sel_div = 3) then
        save_ind :=  (MAX_NEURONS + 1) * MAX_NEURONS - 1;  
        for I in (MAX_NEURONS + 1) * MAX_NEURONS - 1 DOWNTO 0 loop
            if(I mod (MAX_NEURONS + 1) >= (MAX_NEURONS - num_of_before )) then
                    w_inputs_pop((save_ind + 1) * BIT_WIDTH - 1 downto save_ind * BIT_WIDTH) <= current_weights((save_ind + 1) * BIT_WIDTH - 1 downto save_ind * BIT_WIDTH) + signed(w_inputs((I + 1) * BIT_WIDTH - 1 downto I * BIT_WIDTH));			    
                save_ind := save_ind - 1;
            end if;
        end loop;
    end if;
end process;

process(clk)
begin
    if(rising_edge(clk)) then
        if(State = SAVE_BACK_STATE) then
            if(sel_div > 3 and sel_div /= delay_prepare_back) then
                write_enable <= '1';
                ind_back_addr <= ind_back_addr;
            elsif(sel_div = 0) then
                if(if_end = '0') then
                    ind_back_addr <= ind_back_addr - 1;
                else
                    ind_back_addr <= ind_back_addr;
                end if;
                write_enable <= '0';   
            elsif(sel_div = delay_prepare_back) then
                ind_back_calc <= ind_back_addr - 1;
                write_enable <= '0';
            end if;
        elsif(State = RESET_STATE) then
            ind_back_calc <=  NUM_OF_LAYERS - 1;
            ind_back_addr <= NUM_OF_LAYERS - 1;
            if(init_ram = '1') then
                write_enable <= init_ram_we;
            else
                write_enable <= '0';
            end if;
        end if;
    end if;
end process;

--racunanje napake
process(clk)
    variable sum_aux : signed(BIT_WIDTH - 1 downto 0);
    begin
    if(rising_edge(clk)) then
            if(State = FINAL_STATE) then
                sum_aux := (others => '0');
                for I in 0 to MAX_NEURONS - 1  loop 
                    sum_aux := sum_aux + f_mult((x_t(NUM_OF_LAYERS)(MAX_NEURONS * BIT_WIDTH  - 1 - (I * BIT_WIDTH) downto MAX_NEURONS * BIT_WIDTH  - ((I + 1) * BIT_WIDTH))
                              - goals(MAX_NEURONS * BIT_WIDTH  - 1 - (I * BIT_WIDTH) downto MAX_NEURONS * BIT_WIDTH  - ((I + 1) * BIT_WIDTH))) , 
                              (x_t(NUM_OF_LAYERS)(MAX_NEURONS * BIT_WIDTH  - 1 - (I * BIT_WIDTH) downto MAX_NEURONS * BIT_WIDTH  - ((I + 1) * BIT_WIDTH))
                              - goals(MAX_NEURONS * BIT_WIDTH  - 1 - (I * BIT_WIDTH) downto MAX_NEURONS * BIT_WIDTH  - ((I + 1) * BIT_WIDTH))) , F);
                end loop;
                napaka <= sum_aux;
            else
                napaka <= (others => '0');
            end if;
    end if;
end process;

--za inicializacijo zazectnih utezi v ram
process(clk)
begin
    if(rising_edge(clk)) then
        if(State = RESET_STATE) then
            addr_temp <= address_for_ram_init;
            --w_inputs_temp <= init_weights;
            w_inputs_temp <= (others => '0');
        else
            addr_temp <= addr;
            w_inputs_temp <= w_inputs_pop;
        end if;
    end if;
end process;
    

forward : calculate_forward
generic map(
    PORTS => MAX_NEURONS,
    NUM_OF_LAYERS => NUM_OF_LAYERS,
    BIT_WIDTH => BIT_WIDTH,
    F => F
)
port map(
    sel => ind_for_addr,
    clk => clk,
    enable => enable_for_calc,
    X  => x_t,
    W  => current_weights,
    Y  => y_t,
    st_nevronov_v_nivoju => nevron_array
  );

ram: weight_ram
generic map(
    BIT_WIDTH => BIT_WIDTH,
    MAX_NEURONS => MAX_NEURONS,
    NUM_OF_LAYERS => NUM_OF_LAYERS
)
port map(
    clk => clk,
    reset => reset,
    we => write_enable,
    addr => addr_temp,
    data_in => w_inputs_temp,
    data_out_test => data_out_test,
    data_out => current_weights
);

backward : calculate_backward
generic map(
    BIT_WIDTH => BIT_WIDTH,
    MAX_NEURONS => MAX_NEURONS,
    NUM_OF_LAYERS => NUM_OF_LAYERS,
    F => F,
    NEURONS_IN_LAYER => NEURONS_IN_LAYER
)
port map(
    clk => clk,
    sel => ind_back_calc,
    enable => enable_back_calc,
    goals => goals,
    outputs => outputs,
    inputs_in => inputs_in, 
    weights => current_weights,
    delta_in => delta_in,
    delta_out => delta_out,
    if_end => if_end,
    weights_update => w_inputs,
    eta => ETA,
    st_nevronov_v_nivoju => nevron_array
);

end Behavioral;
