--coef for 15 tap FIR for LOWPASS
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity lowpass_coef31 is	--	1 clock delay
port(
	clk					:in std_logic;
	addr				: in	std_logic_vector( 4 downto 0);
	data				: out	std_logic_vector( 7 downto 0)
);
end  lowpass_coef31;

architecture TABLE of  lowpass_coef31 is

	signal	value				: std_logic_vector( 7 downto 0);
	signal	address				: std_logic_vector( 7 downto 0);

begin

	address	<=	"000" & addr;

	--Latency = 1
	process (clk) begin
	if(clk' event and clk='1') then
		data	<= value;
	end if;
	end process;

value	<=	 x"00"	when address=X"00"
else		 x"FF"	when address=X"01"
else		 x"FF"	when address=X"02"
else		 x"01"	when address=X"03"
else		 x"02"	when address=X"04"
else		 x"00"	when address=X"05"
else		 x"FC"	when address=X"06"
else		 x"FC"	when address=X"07"
else		 x"05"	when address=X"08"
else		 x"0B"	when address=X"09"
else		 x"00"	when address=X"0A"
else		 x"EC"	when address=X"0B"
else		 x"EE"	when address=X"0C"
else		 x"1D"	when address=X"0D"
else		 x"5F"	when address=X"0E"
else		 x"7F"	when address=X"0F"
else		 x"5F"	when address=X"10"
else		 x"1D"	when address=X"11"
else		 x"EE"	when address=X"12"
else		 x"EC"	when address=X"13"
else		 x"00"	when address=X"14"
else		 x"0B"	when address=X"15"
else		 x"05"	when address=X"16"
else		 x"FC"	when address=X"17"
else		 x"FC"	when address=X"18"
else		 x"00"	when address=X"19"
else		 x"02"	when address=X"1A"
else		 x"01"	when address=X"1B"
else		 x"FF"	when address=X"1C"
else		 x"FF"	when address=X"1D"
else		 x"00"	when address=X"1E"
else		(others=>'0');

end table;                
