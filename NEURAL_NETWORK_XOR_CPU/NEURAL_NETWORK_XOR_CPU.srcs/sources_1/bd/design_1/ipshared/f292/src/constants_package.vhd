library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package instruction_buffer_type is

--POTREBNO SPREMENITI NA MAX_NEURONS * BIT_WIDTH
subtype T_SLV_8  is signed(31 downto 0); 

type    stevilo_nevronov_v_nivoju is array(NATURAL range <>) of integer range 0 to 31;
type    T_SLVV_8 is array(NATURAL range <>) of T_SLV_8;

end package instruction_buffer_type;