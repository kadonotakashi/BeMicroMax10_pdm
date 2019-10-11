--
--	LED control Sequence Register
--
--	2018/11/12 TKDN
--	get sensor black level

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fir_1b128t is
Port (	clk			    : in std_logic;
		reset_n		    : in std_logic;		

		start_in		:in  std_logic;
		busy_out        :out std_logic;

		addr_inc		:out std_logic;
		bitdata_data_in         :in std_logic_vector(7 downto 0 );

		data_out		:out std_logic_vector(13 downto 0);	--unsigned 14bit
		valid_out       :out std_logic
	);
	end fir_1b128t;

architecture RTL of fir_1b128t is

	type SEQ_TYPE is(
		SEQ_IDLE,
		SEQ_START,
		SEQ_CALC,
		SEQ_END0,
		SEQ_END1,
		SEQ_END2
	);
	signal	STS :SEQ_TYPE;
	signal	CALC_CNT	:integer range 0 to 31;
	signal	ROM_ADDR	:std_logic_vector(5 downto 0);
	signal	SUMTIM		:std_logic_vector(1 downto 0);

	component coef_rom16_64 is	--	1 clock delay
	port(
		clk					:in std_logic;
		addr				: in	std_logic_vector( 3 downto 0);
		data				: out	std_logic_vector( 63 downto 0)
	);
	end component;
	signal	ROMQ	:std_logic_vector(63 downto 0);

	signal	COEF_DATA0	:std_logic_vector(7 downto 0);
	signal	COEF_DATA1	:std_logic_vector(7 downto 0);
	signal	COEF_DATA2	:std_logic_vector(7 downto 0);
	signal	COEF_DATA3	:std_logic_vector(7 downto 0);
	signal	COEF_DATA4	:std_logic_vector(7 downto 0);
	signal	COEF_DATA5	:std_logic_vector(7 downto 0);
	signal	COEF_DATA6	:std_logic_vector(7 downto 0);
	signal	COEF_DATA7	:std_logic_vector(7 downto 0);

	component add8bit_x_8
	PORT
	(
		clock		: IN STD_LOGIC  := '0';
		data0x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data1x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data2x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data3x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data4x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data5x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data6x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data7x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
	);
	end component;
	signal	ADD0_OUT	:std_logic_vector(13 downto 0);

	component add14_x_2
	PORT
	(
		data0x		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		data1x		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (13 DOWNTO 0)
	);
	end component;
	signal	SUM		:std_logic_vector(13 downto 0);
	signal	RESULT	:std_logic_vector(13 downto 0);
	signal	SIGNED_RESULT	:std_logic_vector(13 downto 0);



begin
	--main sequencer
	process(clk,reset_n) begin
	if (reset_n='0')	then	STS	<=	SEQ_IDLE;
	elsif clk'event and clk='1' then
		case STS is
		when SEQ_IDLE=>
			if start_in='1' then STS	<=	SEQ_START;
			else STS <= STS;
			end if;
		when SEQ_START=>
			if start_in='0' then STS	<=	SEQ_CALC;
			else STS <= STS;
			end if;
		when SEQ_CALC=>
			if CALC_CNT=15 then STS	<=	SEQ_END0;
			else STS <= STS;
			end if;
		when SEQ_END0=>		STS	<=	SEQ_END1;
		when SEQ_END1=>		STS	<=	SEQ_IDLE;
		when SEQ_END2=>		STS	<=	SEQ_IDLE;
		when others=>		STS	<=	SEQ_IDLE;
		end case;
	end if;
	end process;

	process(clk)	begin
	if clk'event and clk='1' then
		if STS = SEQ_CALC then
			SUMTIM(0)	<=	'1'	;
		else
			SUMTIM(0)	<=	'0'	;
		end if;
			SUMTIM(1)	<=	SUMTIM(0);
	end if;
	end process;

	busy_out  <=	'0' when   STS = SEQ_IDLE	else '1';

	process(clk) begin
	if clk'event and clk='1' then
		if STS = SEQ_END1	then	valid_out	<=	'1';
		else						valid_out	<=	'0';
		end if;
	end if;
	end process;

	process(clk,reset_n) begin
	if (reset_n='0')	then		CALC_CNT	<=	0;
	elsif clk'event and clk='1' then
		if STS = SEQ_START	then	CALC_CNT	<=	0;
		elsif STS = SEQ_CALC then	CALC_CNT	<=	CALC_CNT+1;
		else						CALC_CNT	<=	CALC_CNT;
		end if;
	end if;
	end process;

	addr_inc	<=	'1' when STS = SEQ_CALC else	'0';

	--read coeff
	ROM_ADDR	<=	CONV_STD_LOGIC_VECTOR(CALC_CNT,6);
	ROM: coef_rom16_64 port map(
		clk		=>	clk,
		addr	=>	ROM_ADDR(3 downto 0),
		data	=>	ROMQ
	);

    COEF_DATA0	<=	ROMQ(7 downto 0) when bitdata_data_in(0) = '1' 		else	X"00";
    COEF_DATA1	<=	ROMQ(15 downto 8) when bitdata_data_in(1) = '1' 	else	X"00";
    COEF_DATA2	<=	ROMQ(23 downto 16) when bitdata_data_in(2) = '1'	else	X"00";
    COEF_DATA3	<=	ROMQ(31 downto 24) when bitdata_data_in(3) = '1' 	else	X"00";
    COEF_DATA4	<=	ROMQ(39 downto 32) when bitdata_data_in(4) = '1' 	else	X"00";
    COEF_DATA5	<=	ROMQ(47 downto 40) when bitdata_data_in(5) = '1' 	else	X"00";
    COEF_DATA6	<=	ROMQ(55 downto 48) when bitdata_data_in(6) = '1' 	else	X"00";
    COEF_DATA7	<=	ROMQ(63 downto 56) when bitdata_data_in(7) = '1' 	else	X"00";
	
	ADD0: add8bit_x_8 port map(
		clock	=>	clk,
		data0x	=>	COEF_DATA0,
		data1x	=>	COEF_DATA1,
		data2x	=>	COEF_DATA2,
		data3x	=>	COEF_DATA3,
		data4x	=>	COEF_DATA4,
		data5x	=>	COEF_DATA5,
		data6x	=>	COEF_DATA6,
		data7x	=>	COEF_DATA7,
		result	=>	ADD0_OUT(10 downto 0)
	);
	
	ADD0_OUT(13 downto 11)	<=	"000";

	ADD1: add14_x_2 port map(
		data0x		=>	RESULT,
		data1x		=>	ADD0_OUT,
		result		=>	SUM
	);

	process(clk,reset_n) begin
	if (reset_n='0')	then		RESULT	<=	(others=>'0');
	elsif clk'event and clk='1' then
		if STS = SEQ_START	then	RESULT	<=	(others=>'0');
		elsif SUMTIM(1)='1'	then	RESULT	<=	SUM;
		else						RESULT	<=	RESULT;
		end if;
	end if;
	end process;

	data_out	<=	RESULT;


	--この段階でRESULTは、範囲 0－11890の符号なし整数
	--中心値 11890/2を0とする符号あり整数に変換


--	2247 = 8192 - 11890/2;	中心値か8192になるようにオフセットを補正
--	SIGNED_RESULT	<=	CONV_STD_LOGIC_VECTOR( (CONV_INTEGER(RESULT) + 2247),14);	--14bit unsigned 
	SIGNED_RESULT	<=	CONV_STD_LOGIC_VECTOR( (CONV_INTEGER(RESULT) + 2247 ),14);	--14bit unsigned 



--	process(clk) begin
--	if clk'event and clk='1' then
--		data_out	<=	SIGNED_RESULT;
--	end if;
--	end process;

end RTL;