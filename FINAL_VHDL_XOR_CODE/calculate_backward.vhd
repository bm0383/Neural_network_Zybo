library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instruction_buffer_type.all;

entity calculate_backward is
   GENERIC (                      
        BIT_WIDTH : integer range 0 to 31;
        MAX_NEURONS : integer range 0 to 31;
        NUM_OF_LAYERS : integer range 0 to 31;
        F : integer range 0 to 31;
        NEURONS_IN_LAYER : signed (31 downto 0)
   );
    
    Port ( sel  : in  integer range 0 to 31 := 0;
           clk : in STD_LOGIC;
           enable : in std_logic;
           goals : in signed (BIT_WIDTH * MAX_NEURONS  - 1 downto 0) := (others => '0');
           outputs : in signed (BIT_WIDTH * MAX_NEURONS  - 1 downto 0);
           inputs_in :  in signed(BIT_WIDTH * MAX_NEURONS  - 1 downto 0);
           weights : in signed ((MAX_NEURONS + 1) * BIT_WIDTH * MAX_NEURONS  - 1 downto 0);
           delta_in : in signed (MAX_NEURONS * BIT_WIDTH - 1 downto 0);
           delta_out : out signed (MAX_NEURONS * BIT_WIDTH - 1  downto 0);
           if_end : in std_logic;
           weights_update : out signed((MAX_NEURONS + 1) * BIT_WIDTH * MAX_NEURONS  - 1  downto 0);
           eta : in signed(BIT_WIDTH - 1  downto 0);
           st_nevronov_v_nivoju : in stevilo_nevronov_v_nivoju(7 downto 0) := (others=>0));
           
end calculate_backward;

architecture Behavioral of calculate_backward is
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

type izracun is array (0 to MAX_NEURONS-1) of signed(BIT_WIDTH-1 downto 0);
type izracun_before is array (0 to  MAX_NEURONS) of signed(BIT_WIDTH-1 downto 0);
signal inputs_temp,deltas, goals_temp,mulb,delta,mu1 : izracun := (others=>(others=>'0'));
signal inputs_before,mula : izracun_before := (others =>(others =>'0'));
type izracun2 is array (0 to ((MAX_NEURONS + 1)*MAX_NEURONS)-1) of signed(BIT_WIDTH-1 downto 0);
signal w_vector : izracun2 := (others=>(others=>'0'));
signal w_vector1 : izracun2 := (others=>(others=>'0'));
signal w_vector2 : izracun2 := (others=>(others=>'0'));
signal weights_update_temp : signed((MAX_NEURONS + 1) * BIT_WIDTH * MAX_NEURONS  - 1  downto 0) := (others => '0');

begin
process(clk)

    variable NUM_OF_NEURONS_VAR :integer range 0 to 31 := 0;
    variable NUM_OF_NEURONS_BEFORE_VAR : integer range 0 to 31 := 0;
    variable sum_aux : izracun_before := (others=>(others=>'0'));
    variable save_ind : integer range 0 to 31 := 0;
    variable save_ind_2 : integer range 0 to 31 := 0;
    variable NUM_OF_NEURONS_NEXT_VAR :integer range 0 to 31 := 0;
    
begin

    if(rising_edge(clk)) then
        if(enable = '1') then
            NUM_OF_NEURONS_NEXT_VAR := st_nevronov_v_nivoju(sel + 2);  
            NUM_OF_NEURONS_VAR := st_nevronov_v_nivoju(sel + 1);         
            NUM_OF_NEURONS_BEFORE_VAR := st_nevronov_v_nivoju(sel);
            save_ind := 0;
            save_ind_2 := 0;
            
            --reset zadnjega mesta inputs before, ker se v naslednji zanki zadnje mesto ne resetira
            inputs_before(MAX_NEURONS) <= (others => '0');
            
            for I in 0 to MAX_NEURONS-1 loop
                inputs_temp(I) <= outputs((MAX_NEURONS - I) * BIT_WIDTH -1 downto (MAX_NEURONS - I - 1) * BIT_WIDTH);
                goals_temp(I) <= goals((MAX_NEURONS - I ) * BIT_WIDTH -1 downto (MAX_NEURONS - I - 1) * BIT_WIDTH);
                inputs_before(I) <= inputs_in((MAX_NEURONS - I) * BIT_WIDTH - 1 downto (MAX_NEURONS - I - 1) * BIT_WIDTH);
                deltas(I) <= delta_in((MAX_NEURONS-I) * BIT_WIDTH -1 downto (MAX_NEURONS - I - 1) * BIT_WIDTH);
            end loop;
            --na zdanje mesto postavim 256 BIAS
            inputs_before(NUM_OF_NEURONS_BEFORE_VAR) <= shift_left(to_signed(1,BIT_WIDTH),F);
       end if;
   end if;  
   
   if(rising_edge(clk)) then
        if(enable = '1') then
            --za oba dela isto
            for I in 0 to MAX_NEURONS - 1 loop
                mulb(I) <= f_mult((shift_left(to_signed(1,BIT_WIDTH),F) - inputs_temp(I)), inputs_temp(I), F);
            end loop;  
		end if;
   end if;
   
   if(rising_edge(clk)) then
        if(enable = '1') then
            if(if_end = '0') then
                --ce racunam za katerkol drug nivo
                for I in 0 to ((MAX_NEURONS + 1) * MAX_NEURONS) - 1 loop
                    if(I mod (MAX_NEURONS + 1) < NUM_OF_NEURONS_VAR) then
                        w_vector1(I) <= weights((((MAX_NEURONS + 1) * MAX_NEURONS)*BIT_WIDTH) - (save_ind_2 * BIT_WIDTH) - 1 downto (((MAX_NEURONS + 1) * MAX_NEURONS)*BIT_WIDTH) - (save_ind_2 * BIT_WIDTH) - BIT_WIDTH);
                        w_vector2(I) <= deltas(save_ind);
						save_ind_2 := save_ind_2 + 1; 
                    elsif(I mod (MAX_NEURONS + 1) = NUM_OF_NEURONS_VAR) then
                        w_vector1(I) <= (others=>'0'); 
                        w_vector2(I) <= (others=>'0'); 
                        save_ind := save_ind + 1;
                        save_ind_2 := save_ind_2 + 1; 
                    else
						w_vector1(I) <= (others=>'0'); 
                        w_vector2(I) <= (others=>'0'); 
                    end if;
                end loop;
			end if;
        end if;
	end if;
	
	
	if(rising_edge(clk)) then
		if(enable = '1') then
			if(if_end = '1') then
				for I in 0 to MAX_NEURONS-1 loop
						mula(I) <= f_mult(shift_left(to_signed(2,BIT_WIDTH),F),(goals_temp(I)-inputs_temp(I)),F);
				end loop; 
			else
				sum_aux := (others=>(others=>'0'));
				for I in 0 to ((MAX_NEURONS + 1) * MAX_NEURONS) - 1 loop
					w_vector(I) <= f_mult(w_vector1(I),w_vector2(I),F);
				end loop;
				
				mula <= (others=>(others=>'0'));
				for I in 0 to ((MAX_NEURONS + 1) * MAX_NEURONS) - 1  loop
						sum_aux(I mod (MAX_NEURONS + 1 ))  := sum_aux(I mod (MAX_NEURONS + 1)) + w_vector(I);
						mula(I mod (MAX_NEURONS + 1)) <= sum_aux(I mod (MAX_NEURONS + 1));
				end loop;              
			end if;
		end if;
	end if;
	
	if(rising_edge(clk)) then
		if(enable = '1') then
			---za oba dela je naprej isto
			for I in 0 to MAX_NEURONS - 1  loop
				delta(I) <= f_mult(mula(I),mulb(I),F);
				delta_out((MAX_NEURONS - I) * BIT_WIDTH - 1 downto (MAX_NEURONS - I - 1) * BIT_WIDTH) <= f_mult(mula(I),mulb(I),F);
			end loop; 
			
			for I in 0 to MAX_NEURONS - 1 loop
				mu1(I) <= f_mult(delta(I), ETA, F);
				for J in 0 to MAX_NEURONS loop
					 weights_update_temp(((MAX_NEURONS + 1) * MAX_NEURONS * BIT_WIDTH) -(J*BIT_WIDTH)-(I*BIT_WIDTH*(MAX_NEURONS + 1)) -1 downto ((MAX_NEURONS + 1) * MAX_NEURONS * BIT_WIDTH) -(J*BIT_WIDTH)-(I*BIT_WIDTH*(MAX_NEURONS+1)) - BIT_WIDTH) <= f_mult(mu1(I),inputs_before(J), F);
				end loop;  
			end loop;                        
		else 
			weights_update_temp <= weights_update_temp;
		end if;
    end if;
    weights_update <= weights_update_temp;
end process;

end Behavioral;
