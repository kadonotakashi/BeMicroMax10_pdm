--coef for 15 tap FIR for LOWPASS
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity lowpass_coef63_0R1 is	--	1 clock delay
port(
	clk					:in std_logic;
	addr				: in	std_logic_vector( 5 downto 0);
	data				: out	std_logic_vector( 9 downto 0)
);
end  lowpass_coef63_0R1;

architecture TABLE of  lowpass_coef63_0R1 is

	signal	value				: std_logic_vector( 11 downto 0);
	signal	address				: std_logic_vector( 7 downto 0);

begin

	address	<=	"00" & addr;

	--Latency = 1
	process (clk) begin
	if(clk' event and clk='1') then
		data	<= value(9 downto 0);
	end if;
	end process;

value	<=	 x"001"	when address=X"00"
else		 x"000"	when address=X"01"
else		 x"FFF"	when address=X"02"
else		 x"FFD"	when address=X"03"
else		 x"FFD"	when address=X"04"
else		 x"FFD"	when address=X"05"
else		 x"000"	when address=X"06"
else		 x"004"	when address=X"07"
else		 x"008"	when address=X"08"
else		 x"009"	when address=X"09"
else		 x"007"	when address=X"0A"
else		 x"000"	when address=X"0B"
else		 x"FF6"	when address=X"0C"
else		 x"FEE"	when address=X"0D"
else		 x"FEB"	when address=X"0E"
else		 x"FF1"	when address=X"0F"
else		 x"000"	when address=X"10"
else		 x"015"	when address=X"11"
else		 x"027"	when address=X"12"
else		 x"02D"	when address=X"13"
else		 x"020"	when address=X"14"
else		 x"000"	when address=X"15"
else		 x"FD4"	when address=X"16"
else		 x"FAD"	when address=X"17"
else		 x"F9E"	when address=X"18"
else		 x"FB7"	when address=X"19"
else		 x"000"	when address=X"1A"
else		 x"073"	when address=X"1B"
else		 x"0FC"	when address=X"1C"
else		 x"17F"	when address=X"1D"
else		 x"1DD"	when address=X"1E"
else		 x"1FF"	when address=X"1F"
else		 x"1DD"	when address=X"20"
else		 x"17F"	when address=X"21"
else		 x"0FC"	when address=X"22"
else		 x"073"	when address=X"23"
else		 x"000"	when address=X"24"
else		 x"FB7"	when address=X"25"
else		 x"F9E"	when address=X"26"
else		 x"FAD"	when address=X"27"
else		 x"FD4"	when address=X"28"
else		 x"000"	when address=X"29"
else		 x"020"	when address=X"2A"
else		 x"02D"	when address=X"2B"
else		 x"027"	when address=X"2C"
else		 x"015"	when address=X"2D"
else		 x"000"	when address=X"2E"
else		 x"FF1"	when address=X"2F"
else		 x"FEB"	when address=X"30"
else		 x"FEE"	when address=X"31"
else		 x"FF6"	when address=X"32"
else		 x"000"	when address=X"33"
else		 x"007"	when address=X"34"
else		 x"009"	when address=X"35"
else		 x"008"	when address=X"36"
else		 x"004"	when address=X"37"
else		 x"000"	when address=X"38"
else		 x"FFD"	when address=X"39"
else		 x"FFD"	when address=X"3A"
else		 x"FFD"	when address=X"3B"
else		 x"FFF"	when address=X"3C"
else		 x"000"	when address=X"3D"
else		 x"001"	when address=X"3E"
else		(others=>'0');

end table;                
