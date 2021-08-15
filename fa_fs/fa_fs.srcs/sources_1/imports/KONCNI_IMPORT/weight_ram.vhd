library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity weight_ram is
 GENERIC (                        
        BIT_WIDTH : integer range 0 to 31;
        MAX_NEURONS : integer range 0 to 31;
        NUM_OF_LAYERS : integer range 0 to 31
     );
    Port ( clk : in STD_LOGIC;
           we : in STD_LOGIC;
           addr : in natural;
           reset : in std_logic := '0';
           data_in : in signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0);
		   --data_out_test : out signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH * NUM_OF_LAYERS - 1 downto 0);
           data_out : out signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1 downto 0));
end weight_ram;

architecture Behavioral of weight_ram is

	subtype word_t is signed((MAX_NEURONS + 1)* MAX_NEURONS * BIT_WIDTH - 1  downto 0);
	type memory_t is array(NUM_OF_LAYERS - 1 downto 0) of word_t;
	--signal ram : memory_t := (others => (others => '0'));
    signal ram : memory_t := (x"000000800040ffc0ffc00040ff80ffc0004000000000000000000000000000000000000000000000",
                              x"ff8000800080ffc0000000800080ff80ffc0ffc000800040ff80ff800080ff800000ffc000800000");
    begin
	
	--process(clk)
    --begin
        --for I in 0 to NUM_OF_LAYERS - 1 loop
            --data_out_test(data_out_test'length - 1 - I * (word_t'length) downto data_out_test'length - (I + 1) * (word_t'length)) <= ram(I);
        --end loop;
   -- end process;

	process(we, reset)
    begin
	    if(reset = '1') then
	       --resetiranje celega ram
	       ram <= (others => (others => '0'));
	    else
            if(rising_edge(we)) then    
                ram(addr) <= data_in;
            end if;
         end if;
	end process;
	data_out <= ram(addr);
	
end Behavioral;
