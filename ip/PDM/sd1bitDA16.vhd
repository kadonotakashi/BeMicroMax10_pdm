
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sd1bitDA16 is
	Port (	clk			: in std_logic;
			reset_n		: in std_logic;		
			clr_in		: in std_logic;

			data_in		:in std_logic_vector(15 downto 0);
			pulse_out	:out std_logic
	);
end sd1bitDA16;

architecture rtl of sd1bitDA16 is

	signal	SUM			:integer range 0 to 131071;
	signal	SUM_VECT	:std_logic_vector(16 downto 0);


begin

	process(clk) begin
	if clk'event and clk='1' then
		SUM <=	CONV_INTEGER(SUM_VECT(15 downto 0))+CONV_INTEGER(data_in);
	end if;
	end process;

	SUM_VECT	<=	CONV_STD_LOGIC_VECTOR(SUM,17);
	pulse_out	<=	SUM_VECT(16);

end rtl;
