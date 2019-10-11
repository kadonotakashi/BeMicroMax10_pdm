
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity coef_rom16_64 is	--	1 clock delay
port(
	clk					:in std_logic;
	addr				: in	std_logic_vector( 3 downto 0);
	data				: out	std_logic_vector( 63 downto 0)
);
end  coef_rom16_64;

architecture TABLE of  coef_rom16_64 is

	signal	value				: std_logic_vector( 63 downto 0);
	signal	address				: std_logic_vector( 3 downto 0);

begin

	address	<=	addr;

	process (clk) begin
	if(clk' event and clk='1') then
		data	<= value;
	end if;
	end process;

value	<=	 x"0706060504040403"	when address=X"00"
else		 x"13110F0E0C0B0908"	when address=X"01"
else		 x"2B2824211E1B1816"	when address=X"02"
else		 x"4F4A45413C38332F"	when address=X"03"
else		 x"7A746F69645F5954"	when address=X"04"
else		 x"A39E99948F8A847F"	when address=X"05"
else		 x"C1BEBBB7B4B0ACA7"	when address=X"06"
else		 x"CDCDCCCBCAC8C6C4"	when address=X"07"
else		 x"C4C6C8CACBCCCDCD"	when address=X"08"
else		 x"A7ACB0B4B7BBBEC1"	when address=X"09"
else		 x"7F848A8F94999EA3"	when address=X"0A"
else		 x"54595F64696F747A"	when address=X"0B"
else		 x"2F33383C41454A4F"	when address=X"0C"
else		 x"16181B1E2124282B"	when address=X"0D"
else		 x"08090B0C0E0F1113"	when address=X"0E"
else		 x"0304040405060607"	when address=X"0F"
else		(others=>'0');

end table;                
                
