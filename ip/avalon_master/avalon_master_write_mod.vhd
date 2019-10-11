--
--	Avalon MM master write module(32bit)
--	
--		書き込みは4kbounderyをまたがないこと（正常に書き込めない、チェックはしない）
--
--		アドレス指定はbyteアドレスで指定、 ただし下位2bitは無視
--
--		書き込み長はbyte数で指定、max4kbyte ただし下位2bitは無視
--
--		バースト長は2,4,8
--




library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity	avalon_master_write_mod is
Port (	
		reset_n			:in std_logic;
		clk				: in  STD_LOGIC;
		clr_in			: in std_logic;

	--parameter,Control sig.
		addr_in			: in std_logic_vector(31 downto 0);
		length_in		: in std_logic_vector(12 downto 0);
		burst_in		: in std_logic_vector(3 downto 0);
		start_in		: in std_logic;
		end_out			: out std_logic;
		busy_out		: out std_logic;
		
	--バッファの接続(Latency=1)
		buf_addr	: out std_logic_vector(9 downto 0);
		buf_data	: in std_logic_vector(31 downto 0);

	--avalon masterとしてデータ転送
		maddr			: out	std_logic_vector(31 downto 0);
		mben			: out	std_logic_vector(3 downto 0);
		mwr				: out	std_logic;
		mwrdata			: out	std_logic_vector(31 downto 0);
		mwaitrequest	: in	std_logic;
		mburstcount		: out	std_logic_vector(7 downto 0)
);
end avalon_master_write_mod;

architecture rtl of avalon_master_write_mod is

	signal	START_DLY		:std_logic_vector(3 downto 0);

	signal	START_ADDRESS		:STD_LOGIC_VECTOR(31 downto 0);
	signal	WR_LENGTH			:integer range 0 to 4096;
	signal	BURST_LNGTH			:integer range 0 to 8;
	signal	BURSTreg			:std_logic_vector(7 downto 0);


	--Latency 0 のリングバッファ
	component burst_buf4
	Port (	
		clk				: in std_logic;
		reset_n			: in std_logic;

		start_in		: in std_logic;				--1ライン分の転送処理開始要求
		stop_in			: in std_logic;				--1ライン分の転送処理開始要求

	--ラインバッファと接続 Latency=1で好きなときに読める。
		rd_address_out	: out std_logic_vector(9 downto 0);		--ラインバッファ読み出しアドレス
		rddata_in		: in std_logic_vector(31 downto 0);		--Latency=1でラインバッファデータ入力
		rdreq_out		: out std_logic;							--ラインバッファ読み出し要求
		full_out		: out std_logic;

	--avalon側
		next_data_in	: in std_logic;							--データ更新要求
		rddata_out		: out std_logic_vector(31 downto 0);	--データ出力
		ready_out		: out std_logic							--バースト転送可能通知
	);
	end component;

	signal	BUF_RDADDR	:std_logic_vector(9 downto 0);

	signal	BurstBufQ		:std_logic_vector(31 downto 0);
	signal	BurstBufQQ		:std_logic_vector(31 downto 0);
	signal	BurstBufReady	:std_logic;

	type	MasterWrite_STS_TYPE is(
		WR_IDLE,
		WR_REQ_WAIT,
		WR_REQ,
		WR_BURST,
		WR_BURST_END,
		WR_LINE_END
	);
	signal	WR_STS:MasterWrite_STS_TYPE;

	signal	WRITE_END	:std_logic;

	signal	BRSTCOUNT		:integer range 0 to 15;
	signal	WR_VALID		:std_logic;

	signal	WR_CNT			:integer range 0 to 4095;
	signal	WR_CNT_VECT		:std_logic_vector(11 downto 0);

	signal	WR_ADDRESS		:integer range 0 to 8191;

begin


	process(clk,reset_n) begin
	if reset_n='0' then
		START_DLY	<=	(others=>'0');
	elsif clk'event and clk='1' then
		START_DLY	<=	START_DLY(2 downto 0) & start_in;
	end if;
	end process;


	process(clk) begin
	if clk'event and clk='1' then
		if start_in='1' then

			START_ADDRESS	<=	addr_in;

			if length_in(12)='1' then 	WR_LENGTH	<=	4096;
			else						WR_LENGTH	<=	CONV_INTEGER(length_in);
			end if;

			if burst_in(3)='1' then 	BURST_LNGTH	<=	8;
										BURSTreg	<=X"08";
			elsif burst_in(2)='1' then 	BURST_LNGTH	<=	4;
										BURSTreg	<=X"04";
			elsif burst_in(1)='1' then 	BURST_LNGTH	<=	2;
										BURSTreg	<=X"02";
			elsif burst_in(0)='1' then 	BURST_LNGTH	<=	1;
										BURSTreg	<=X"01";
			else						BURST_LNGTH	<=	0;
										BURSTreg	<=X"00";
			end if;
		else
			START_ADDRESS	<=	START_ADDRESS;
			WR_LENGTH	<=	WR_LENGTH;
			BURSTreg	<=	BURSTreg;
		end if;
	end if;
	end process;

	------------------------------------------------
	--バッファとの接続 
	------------------------------------------------

	BBUF:burst_buf4 port map(
		clk				=>	clk,
		reset_n			=>	reset_n,
		start_in		=>	start_in,
		stop_in			=>	WRITE_END,
		rd_address_out	=>	BUF_RDADDR,
		rdreq_out		=>	open,
		rddata_in		=>	buf_data,
		full_out		=>	open,
		next_data_in	=>	WR_VALID,
		rddata_out		=>	BurstBufQ,
		ready_out		=>	BurstBufReady
	);

	buf_addr	<=	BUF_RDADDR(9 downto 0);

	-------------------------------------------------------
	--burst write用バッファがreadyとなれば、
	--規定回数のburst書き込みを行う
	-------------------------------------------------------
	process(clk,reset_n)	begin
	if reset_n='0' then
		WR_STS	<=	WR_IDLE;
	elsif clk'event and clk='1' then
		if clr_in='1' then
			WR_STS	<=	WR_IDLE;
		else
			case	WR_STS is
				when WR_IDLE=>
					if START_DLY(2)='1' then			WR_STS <= WR_REQ_WAIT;
					else									WR_STS <= WR_STS;
					end if;

				when WR_REQ_WAIT	=>	
					if BurstBufReady='1' then				WR_STS <= WR_REQ;
					else									WR_STS <= WR_STS;
					end if;

				when WR_REQ	=>								WR_STS	<=	WR_BURST;

				when WR_BURST	=>	
	--				if BRSTCOUNT >= BURST_LNGTH-1 	then	WR_STS	<=	WR_BURST_END;
					if (	(BRSTCOUNT >= BURST_LNGTH-1)
						 and (WR_VALID='1'))		 	then	WR_STS	<=	WR_BURST_END;
					else									WR_STS	<=	WR_STS;
					end if;

				when WR_BURST_END=>							WR_STS	<=	WR_IDLE;
					if WR_CNT*4 >= WR_LENGTH		 	then	WR_STS	<=	WR_LINE_END;		
					else									WR_STS	<=	WR_REQ_WAIT;
					end if;

				when WR_LINE_END=>							WR_STS	<=	WR_IDLE;

				when others=>								WR_STS	<=	WR_IDLE;
			end case;
		end if;
	end if;
	end process;
	busy_out	<=	'0'	when WR_STS = WR_IDLE	else	'1';
	WRITE_END	<=	'1'	when WR_STS = WR_LINE_END	else	'0';
	end_out		<=	WRITE_END;
	-----------------------------------------
	
	--------------
	--1回のBURST転送での転送カウント
	-------------------------------------------------------
	process(clk,reset_n)	begin
	if reset_n='0' then
		BRSTCOUNT	<=	0;
	elsif clk'event and clk='1' then
		if  WR_STS = WR_REQ then
			BRSTCOUNT	<=	0;
		elsif WR_VALID='1' then
			if BRSTCOUNT < BURST_LNGTH then
				BRSTCOUNT	<=	BRSTCOUNT+1;
			else
				BRSTCOUNT	<=	BRSTCOUNT;
			end if;
		else
			BRSTCOUNT	<=	BRSTCOUNT;
		end if;
	end if;
	end process;

	-------------------------------------------------------
	--1ライン中での転送カウント
	-------------------------------------------------------
	process(clk,reset_n)	begin
	if reset_n='0' then
		WR_CNT	<=	0;
	elsif clk'event and clk='1' then
		if start_in='1' then
			WR_CNT	<=	0;
		elsif WR_VALID='1' then
			if WR_CNT < WR_LENGTH then
				WR_CNT	<=	WR_CNT+1;
			else
				WR_CNT	<=	WR_CNT;
			end if;
		else
			WR_CNT	<=	WR_CNT;
		end if;
	end if;
	end process;
	

	WR_CNT_VECT	<=	CONV_STD_LOGIC_VECTOR(WR_CNT,12);

	-------------------------------------------------------
	--Avalon Bus Masterとしての接続
	-------------------------------------------------------

	WR_VALID	<=	'1'	when ((WR_STS = WR_BURST) and (mwaitrequest='0'))	else '0';

	mben	<=	"1111";

	mburstcount	<=	BurstReg;

	mwr		<=	'1'		when (	(WR_STS = WR_BURST)	and ( BurstBufReady='1') )
	else		'0';


--	BurstBufQQ	<=	"0000000" & LINE_SEND_COUNT_VECTOR & "00000000" & WR_CNT_VECT;
--	mwrdata	<=	BurstBufQQ;

	mwrdata	<=	BurstBufQ;

	maddr(31 downto 12)	<=	START_ADDRESS(31 downto 12);

	WR_ADDRESS	<=	CONV_INTEGER( START_ADDRESS(11 downto 2)) + WR_CNT;
	
	maddr(11 downto 2)	<=	CONV_STD_LOGIC_VECTOR( WR_ADDRESS,10);

	maddr(1 downto 0)		<=	"00";


end rtl;

