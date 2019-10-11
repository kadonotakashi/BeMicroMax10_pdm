--
--	PDM MIC interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fir_16b63t is
Port (	clk			    : in std_logic;
        reset_n         : in std_logic;

        start_in        :in std_logic;
        busy_out        :out std_logic;
        ch_in           :in std_logic_vector(2 downto 0);
        pos_in          :in std_logic_vector(6 downto 0);

        buf_ch          :out std_logic_vector(2 downto 0);
        buf_pos         :out std_logic_vector(6 downto 0);
        buf_datain      :in std_logic_vector(13 downto 0);

        ch_out          :out std_logic_vector(2 downto 0);
        pos_out         :out std_logic_vector(6 downto 0);
        data_out        :out std_logic_vector(27 downto 0);
        write_out       :out std_logic
	);
end fir_16b63t;

architecture RTL of fir_16b63t is
	type SEQ_TYPE is(
		SEQ_IDLE,
		SEQ_START,
		SEQ_CALC,
		SEQ_END0,
		SEQ_END1
	);
	signal	STS :SEQ_TYPE;
    CONSTANT	TAP_NUM	:integer := 63;
    signal  CALC_CNT    :integer range 0 to 127;
	CONSTANT	POS_MAX	:integer := 128;
	signal	POS_CNT		:integer range 0 to 127;
	signal	POS_REG		:std_logic_vector(6 downto 0);
	signal	CH_REG		:std_logic_vector(2 downto 0);
	
	signal	CALC_DELAY	:std_logic_vector(3 downto 0);

	component lowpass_coef63_0R1
	port(
		clk					:in std_logic;
		addr				: in	std_logic_vector( 5 downto 0);
		data				: out	std_logic_vector( 9 downto 0)
	);
	end component;
	signal	COEF_DATA	:std_logic_vector(9 downto 0);		
	signal	COEF_ADDR	:std_logic_vector(7 downto 0);

 	component SMUL_10_14 IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
	);
	end component;

	signal	MA_DATAA	:STD_LOGIC_VECTOR (13 DOWNTO 0);
	signal	MA_CLR		:STD_LOGIC;


	signal	MULL_RESULT	:std_logic_vector(23 downto 0);

 	component sadd_28
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		clock		: IN STD_LOGIC  := '0';
		data0x		: IN STD_LOGIC_VECTOR (27 DOWNTO 0);
		data1x		: IN STD_LOGIC_VECTOR (27 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (28 DOWNTO 0)
	);
	end component;
	signal	ADD_IN		:std_logic_vector(27 downto 0);
	signal	ADD_RESULT	:std_logic_vector(28 downto 0);
	signal	ADD_CLR		:STD_LOGIC;

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
			if CALC_CNT = TAP_NUM-1 then STS	<=	SEQ_END0;
			else STS <= STS;
			end if;
		when SEQ_END0=>		STS	<=	SEQ_END1;
		when SEQ_END1=>		STS	<=	SEQ_IDLE;
		when others=>		STS	<=	SEQ_IDLE;
		end case;
	end if;
	end process;

	busy_out	<=	'0' when STS = SEQ_IDLE	else	'1';
	MA_CLR		<=	'1' when STS = SEQ_START else '0';

	process(clk) begin
	if clk'event and clk='1' then
		if start_in='1' then	POS_REG	<=	pos_in;
								CH_REG	<=	ch_in;
		end if;
	end if;
	end process;

	process(clk) begin
	if clk'event and clk='1' then
		if  STS	=	SEQ_CALC then
			CALC_DELAY(0)	<=	'1';
		else
			CALC_DELAY(0)	<=	'0';
		end if;

		CALC_DELAY(3 downto 1)<=CALC_DELAY(2 downto 0);

	end if;
	end process;

	process(clk) begin 
	if clk'event and clk='1' then
		if start_in='1' then			CALC_CNT<=0;
		elsif STS = SEQ_CALC then
			if CALC_CNT = TAP_NUM-1 then	CALC_CNT	<=	CALC_CNT;		
			else						CALC_CNT	<=	CALC_CNT+1;		
			end if;
		else							CALC_CNT	<=	CALC_CNT;
		end if;
	end if;
	end process;

	process(clk) begin 
	if clk'event and clk='1' then
		if start_in='1' then			POS_CNT	<=	conv_integer(pos_in);
		elsif STS = SEQ_CALC then
			if POS_CNT = POS_MAX-1 then	POS_CNT	<=	0;		
			else						POS_CNT	<=	POS_CNT+1;		
			end if;
		else							POS_CNT	<=	POS_CNT;
		end if;
	end if;
	end process;

	buf_pos	<=	CONV_STD_LOGIC_VECTOR(POS_CNT,7);
	buf_ch	<=	CH_REG;

	ch_out	<=	CH_REG;
	pos_out	<=	POS_REG;

	COEF_ADDR	<=	CONV_STD_LOGIC_VECTOR(CALC_CNT,8);

	COEFROM: lowpass_coef63_0R1 port map(
		clk		=>	clk,
		addr	=>	COEF_ADDR(5 downto 0),
		data	=>	COEF_DATA
	);


	MA_DATAA <= not buf_datain(13) & buf_datain(12 downto 0);	--unsigned 14 bit => signed 14 bit
--	MA_DATAA <= buf_datain(13 downto 0);



 	MUL: SMUL_10_14 port map(
		clock	=>	clk,
		dataa	=>	MA_DATAA,
		datab	=>	COEF_DATA,
		result	=>	MULL_RESULT
	);

	ADD_IN(23 downto 0)	<=	MULL_RESULT;

	ADD_IN(27 downto 24) <=	"0000"	when ADD_IN(23)='0'
	else					"1111";

 	ADD: sadd_28 port map(
		aclr	=>	ADD_CLR,
		clock	=>	clk,
		data0x	=>	ADD_RESULT(27 downto 0),
		data1x	=>	ADD_IN,
		result	=>	ADD_RESULT
	);
	ADD_CLR		<=	'1' when CALC_DELAY(1 downto 0)="01"	else	'0';


	process(clk) begin
	if clk'event and clk='1' then
		if  CALC_DELAY(1 downto 0)="10" then
			write_out <= '1';
		else
			write_out <= '0';
		end if;
	end if;
	end process;

	process(clk) begin
	if clk'event and clk='1' then
		if  CALC_DELAY(1 downto 0)="10" then
			data_out	<=	ADD_RESULT(27 downto 0);
		else
			null;
		end if;
	end if;
	end process;

end RTL;