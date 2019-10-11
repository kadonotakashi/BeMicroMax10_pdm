--
--	avalon mm masterとしてデータを書き込む際の
--	バースト転送用バッファ(max. 8word x 32bit)
--	
--	Latency=1のラインバッファの出力データを直接avalon busに接続するのは困難

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity	burst_buf4 is
Port (	
		clk				: in std_logic;
		reset_n			: in std_logic;

		start_in		: in std_logic;				--1ライン分の転送処理開始要求
		stop_in			: in std_logic;				--1ライン分の転送処理開始要求

	--ラインバッファと接続 Latency=1で好きなときに読める。
		rd_address_out	: out std_logic_vector(9 downto 0);		--ラインバッファ読み出しアドレス
		rddata_in		: in std_logic_vector(31 downto 0);		--Latency=1でラインバッファデータ入力
		rdreq_out		: out std_logic;						--ラインバッファ読み出し要求
		full_out		: out std_logic;

	--avalon側
		next_data_in	: in std_logic;							--データ更新要求
		rddata_out		: out std_logic_vector(31 downto 0);	--データ出力
		ready_out		: out std_logic							--バースト転送可能通知
);
end burst_buf4;

architecture rtl of burst_buf4 is


	TYPE BSEQ_TYPE IS (	
		B_IDLE,
		B_START,
		B_START0,
		B_START1,
		B_WAIT_END,
		B_END
	);
	signal	BSTS:BSEQ_TYPE;

	signal		DATA_COUNT			:integer range 0 to 1023;				--転送済みデータ数
	signal		DATA_COUNT_VECT		:std_logic_vector(9 downto 0);		--転送済みデータ数
	signal		DATA_END			:std_logic;								--データ転送終了

	signal	RDREQ	:std_logic;
	signal	REG_WR		:std_logic;
	signal	REG_WR_ADDR	:std_logic_vector(1 downto 0);

	signal	FULL,READY	:std_logic;

	signal	REG_DATA_COUNT	:integer range 0 to 7;
	signal	REG_RD_COUNT	:integer range 0 to 3;


	signal	DATAREG0	:std_logic_vector(31 downto 0);
	signal	DATAREG1	:std_logic_vector(31 downto 0);
	signal	DATAREG2	:std_logic_vector(31 downto 0);
	signal	DATAREG3	:std_logic_vector(31 downto 0);

begin


	--シーケンサ
	process(clk,reset_n) begin
	if reset_n='0' then
		BSTS	<=	B_IDLE;
	elsif clk'event and clk='1' then
		case BSTS is
			when B_IDLE		=>
				if start_in ='1' then	BSTS	<=	B_START;
				else					BSTS	<=	BSTS;
				end if;
			when B_START	=>			BSTS	<=	B_START0;
			when B_START0	=>			BSTS	<=	B_START1;
			when B_START1	=>			BSTS	<=	B_WAIT_END;
			when B_WAIT_END	=>
				if start_in ='1' then	BSTS	<=	B_START;
				elsif stop_in='1' then	BSTS	<=	B_END;
				else					BSTS	<=	BSTS;
				end if;
--			when B_END		=>			BSTS	<=	B_IDLE;
			when others		=>			BSTS	<=	B_IDLE;
		end case;
	end if;
	end process;


	--	ラインバッファへの読み出し要求と
	--	読み出されたデータのモジュール内レジスタへの書き込みタイミング
--	process(clk,reset_n) begin
--	if reset_n='0' then
--		RDREQ	<=	'0';
--	elsif clk'event and clk='1' then
--		if BSTS = B_WAIT_END then
--			if FULL='0' then			RDREQ	<=	'1';
--			else						RDREQ	<=	'0';
--			end if;
--		else
--			RDREQ	<=	'0';
--		end if;
--	end if;
--	end process;

	RDREQ	<=	'1'	when (( FULL='0') and (BSTS = B_WAIT_END))
	else		'0';



	--	ラインバッファへの読み出しカウント
	process(clk,reset_n) begin
	if reset_n='0' then
		DATA_COUNT	<=	0;
	elsif clk'event and clk='1' then
		if BSTS = B_START	then
			DATA_COUNT	<=	0;
		elsif RDREQ = '1'	then
			if DATA_COUNT<1023 then
				DATA_COUNT	<=	DATA_COUNT+1;
			else
				DATA_COUNT	<=	DATA_COUNT;
			end if;
		else
			DATA_COUNT	<=	DATA_COUNT;
		end if;

	end if;
	end process;


	DATA_COUNT_VECT	<=	CONV_STD_LOGIC_VECTOR(DATA_COUNT,10);

	----------------------------------------------
	--ラインバッファの接続
	rdreq_out		<=	RDREQ;
	rd_address_out	<=	DATA_COUNT_VECT;

	--ラインバッファの読み出しLatency='1'
	process(clk,reset_n) begin
	if clk'event and clk='1' then
		REG_WR_ADDR		<=	DATA_COUNT_VECT(1 downto 0);
		REG_WR			<=	RDREQ;
	end if;
	end process;


	--内部レジスタへの書き込み
	process(clk) begin
	if clk'event and clk='1' then

		if REG_WR='1' and REG_WR_ADDR="00" then	DATAREG0 <=	rddata_in;
		else										DATAREG0 <=	DATAREG0;
		end if;

		if REG_WR='1' and REG_WR_ADDR="01" then	DATAREG1 <=	rddata_in;
		else										DATAREG1 <=	DATAREG1;
		end if;

		if REG_WR='1' and REG_WR_ADDR="10" then	DATAREG2 <=	rddata_in;
		else										DATAREG2 <=	DATAREG2;
		end if;

		if REG_WR='1' and REG_WR_ADDR="11" then	DATAREG3 <=	rddata_in;
		else										DATAREG3 <=	DATAREG3;
		end if;


	end if;
	end process;



	--レジスタに蓄えたデータのワード数
	process(clk,reset_n) begin
	if reset_n='0' then
		REG_DATA_COUNT	<=	0;
	elsif clk'event and clk='1' then
		if BSTS = B_START then
			REG_DATA_COUNT	<=	0;
		elsif REG_WR='1' and next_data_in='0' then	--書きこみ発生
			REG_DATA_COUNT	<=	REG_DATA_COUNT+1;
		elsif REG_WR='0' and next_data_in='1' then	--読み出し発生
			REG_DATA_COUNT	<=	REG_DATA_COUNT-1;
--		elsif REG_WR='1' and next_data_in='1' then	--読み書き同時発生
--			REG_DATA_COUNT	<=	REG_DATA_COUNT;
		else
			REG_DATA_COUNT	<=	REG_DATA_COUNT;
		end if;
	end if;
	end process;

	FULL	<=	'1'	when REG_DATA_COUNT >= 3	else	'0';
	READY	<=	'1'	when ((REG_DATA_COUNT > 0) and (BSTS = B_WAIT_END))
	else		'0';	--ラインバッファからの読み込みは確実に1word/1clk

	full_out	<=	FULL;
	ready_out	<=	READY;

	process(clk,reset_n) begin
	if reset_n='0' then
		REG_RD_COUNT	<=	0;
	elsif clk'event and clk='1' then
		if BSTS = B_START then
			REG_RD_COUNT	<=	0;
		elsif next_data_in='1' then	--データ更新
			if REG_RD_COUNT=3 then
				REG_RD_COUNT	<=	0;
			else
				REG_RD_COUNT	<=	REG_RD_COUNT+1;
			end if;
		else
			REG_RD_COUNT	<=	REG_RD_COUNT;
		end if;
	end if;
	end process;

	rddata_out	<=	DATAREG0	when REG_RD_COUNT=0
	else			DATAREG1	when REG_RD_COUNT=1
	else			DATAREG2	when REG_RD_COUNT=2
	else			DATAREG3	;	--	when REG_RD_COUNT=3

end rtl;

