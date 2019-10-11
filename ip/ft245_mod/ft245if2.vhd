--
--	FTDT社　FT245制御モジュール
--
--
--	0x00	Control /STSReg
--				write					read
--		bit0:	Clear					<-read
--		bit1:	-						RXRDY
--		bit2:	-						TXRDY
--		bit3:							TXBUSY
--		bit4:							FIFO_EMPTY
--		bit5:							FIFO_FULL

--	0x04	IRQ reg
--				write					read
--		bit0:	RxIRQ 		enable		<-read
--		bit2:	-						RxIRQ Status	Rxregを読めばリセット
--
--	0x08		Txreg					1バイト(8bit)送信データレジスタ
--	0x0c		Rxreg					1バイト(8bit)受信データレジスタ
--	0x10		TxFifo					fifo(32bit)送信用
--
--
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ft245if2 is
	Port (	clk			: in std_logic;
			reset_n		: in std_logic;		
			address		: in std_logic_vector(4 downto 2);
			ben			: in std_logic_vector(3 downto 0);
			sel			: in std_logic;		
			rd			: in std_logic;		
			wr			: in std_logic;		
			waitreq		: out std_logic;
			wrdata		: in std_logic_vector(31 downto 0);
			rddata		: out std_logic_vector(31 downto 0);
			irq			: out std_logic;

			ft_resetn	: out std_logic;
			ft_rxfn		: in std_logic;
			ft_rdn		: out std_logic;
			ft_rxdata	: in std_logic_vector(7 downto 0);
			ft_txen		: in std_logic;
			ft_wr		: out std_logic;
			ft_txdata	: out std_logic_vector(7 downto 0);
			ft_txdata_oe	: out std_logic
	);
end ft245if2;

architecture rtl of ft245if2 is
--CPUとインタフェースするための信号

	signal	SEL_CTRL,SEL_TX,SEL_RX,SEL_IRQ	:std_logic;
	signal	SEL_FIFO						:std_logic;
	signal	SEL_TxRATE						:std_logic;

	signal	CTRLreg	:std_logic_vector(7 downto 0);
		signal	CLRbit				:std_logic;		--bit0	WR

	signal	STSreg	:std_logic_vector(7 downto 0);
--		signal	CLRbit				:std_logic;		--bit0	WR
		signal	RX_RDYbit			:std_logic;		--bit1
		signal	TX_RDYbit			:std_logic;		--bit2
		signal	TXBUSY				:std_logic;		--bit3
--		signal	FIFO_EMPTY			:std_logic;		--bit4
--		signal	FIFO_FULL			:std_logic;		--bit5

	signal	IRQreg		:std_logic_vector(3 downto 0);	--送信レジスタ
		signal	RXIRQ_EN	:std_logic;	--bit0
		signal	RXIRQ_STS	:std_logic;	--bit2

	signal	TXreg		:std_logic_vector(7 downto 0);	--送信レジスタ
	signal	TRNS_STARTbit	:std_logic;

	signal	RXreg			:std_logic_vector(7 downto 0);	--受信レジスタ
	signal	TxRATEreg		:std_logic_vector(15 downto 0);	--送信レジスタ

	signal	CPURD_RXREG	:std_logic;
	signal	RXFDLY	:std_logic_vector(1 downto 0);
	signal	TXEDLY	:std_logic_vector(1 downto 0);

	-----------------------------------
	--Sequencer
	-----------------------------------
	--1byte単位でFT245への書き込み制御を行う
	type FT245STS_TYPE is(
		IDLE,

		RECV,
		WAIT_CPURD,
		RECV_END,

		TRNS,
		TRNS_END
	);
	signal	STS	:FT245STS_TYPE;


--	constant	SEQCNT_MAX	:integer :=9;
--	constant	SEQCNT_MAX	:integer :=255;	--約400kbyte/s
--	signal	SEQ_CNT			:integer range 0 to SEQCNT_MAX;

	signal	SEQ_CNT			:integer range 0 to 65535;



	signal	SEQ_END			:std_logic;
	signal	BYTE_CNT		:integer range 0 to 65535;
	signal	BYTE_CNT_VCTR	:std_logic_vector(15 downto 0);

	signal	SEND_DATA		:std_logic_vector(31 downto 0);

	--FIFOの読み出し制御
	type FIFOSTS_TYPE is(
		FIFO_IDLE,

		FIFO_RD_WORD,					--READ 1word(32bit)from FIFO
		FIFO_SEND_START,			--Send 1byte to FT245
		WAIT_FIFO_SEND_END,			--wait 1byte send end
		CHK_WORD_END				--check word send end;
	);
	signal	FIFOSTS	:FIFOSTS_TYPE;
	signal	FIFO_BYTE_COUNT	:integer range 0 to 3;


	-----------------------------------
	--buffer
	-----------------------------------
	component TxFIFO
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	end component;

	signal	FIFO_RDREQ	:std_logic;
	signal	FIFO_WRREQ	:std_logic;
	signal	FIFO_FULL	:std_logic;
	signal	FIFO_EMPTY	:std_logic;
	signal	FIFO_Q		:std_logic_vector(31 downto 0);
	signal	FIFO_Qreg	:std_logic_vector(31 downto 0);

	signal	FIFO_SENDREQ	:std_logic;
	signal	FIFO_SEND_BUSY	:std_logic;

	


begin


------------------------------------------
------------------------------------------
--	CPUとのインタフェース
------------------------------------------
------------------------------------------
	SEL_CTRL	<=	sel	when address(4 downto 2)="000"		else	'0';
	SEL_IRQ		<=	sel	when address(4 downto 2)="001"		else	'0';
	SEL_TX		<=	sel	when address(4 downto 2)="010"		else	'0';
	SEL_RX		<=	sel	when address(4 downto 2)="011"		else	'0';
	SEL_TxRATE	<=	sel	when address(4 downto 2)="011"		else	'0';	--SEL_RXと同じアドレスただしbit31-16

	SEL_FIFO	<=	sel	when address(4 downto 2)="100"		else	'0';

	RDDATA	<=	X"0000_00" 			& STSreg	when SEL_CTRL ='1'
	else		X"0000_000" 		& IRQreg	when SEL_IRQ ='1'
	else		X"0000_00" 			& TxReg		when SEL_TX ='1'
	else		TxRATEreg & X"00" 	& RxReg		when SEL_RX ='1'
	else		(others=>'0');

	CPURD_RXREG	<=	rd	when SEL_RX='1'	else	'0';

	FIFO_WRREQ	<=	wr	when SEL_FIFO='1'	else	'0';

	waitreq		<=	'1'when (SEL_FIFO='1' and wr='1' and FIFO_FULL='1')	else '0';


	
	------------------------------------------
	--	register write
	------------------------------------------
	process(clk,reset_n) begin
	if reset_n='0' then
		CTRLreg				<=	X"09";
		IRQreg(1 downto 0)	<=	(others=>'0');
		TXreg				<=	(others=>'0');
		TxRATEreg			<=	X"0009";
	elsif CLK'event and CLK='1' then
		--------------制御レジスタ----------------
		if SEL_CTRL='1' and wr='1' and ben(0)='1' then	CTRLreg	<=	wrdata(7 downto 0);
		else											CTRLreg	<=	CTRLreg;
		end if;

		--------------割り込みレジスタ----------------
		if SEL_IRQ='1' and wr='1' and ben(0)='1' then	IRQreg(1 downto 0)	<=	wrdata(1 downto 0);
		else											IRQreg(1 downto 0)	<=	IRQreg(1 downto 0);
		end if;

		--------------送信データレジスタ----------------
		if SEL_TX='1' and wr='1' then
			if ben(0)='1' then							TxReg(7 downto 0) <=	wrdata(7 downto 0);
			else										TxReg(7 downto 0) <=	TxReg(7 downto 0);
			end if;
		else
			TxReg	<=	TxReg;
		end if;

		--------------送信データRATEレジスタ----------------
		if SEL_TxRATE='1' and wr='1' then
			if ben(2)='1' then							TxRATEreg(7 downto 0) <=	wrdata(23 downto 16);
			else										TxRATEreg(7 downto 0) <=	TxRATEreg(7 downto 0);
			end if;

			if ben(3)='1' then							TxRATEreg(15 downto 8) <=	wrdata(31 downto 24);
			else										TxRATEreg(15 downto 8) <=	TxRATEreg(15 downto 8);
			end if;
		else
			TxRATEreg	<=	TxRATEreg;
		end if;

	end if;
	end process;

	--------------制御レジスタ周辺----------------
	CLRbit			<=	CTRLreg(0);

	--1バイト転送要求
	TRNS_STARTbit		<=	'1'			when (SEL_TX='1' and wr='1' and ben(0)='1' )	else'0';

	process(reset_n,clk) begin
	if reset_n='0' then							TXBUSY<='0';
	elsif clk'event and clk='1' then
		if CLRbit='1' then						TXBUSY <= '0';
		elsif TRNS_STARTbit='1' then			TXBUSY <= '1';
		elsif STS=TRNS_END then					TXBUSY <= '0';
		else									TXBUSY <= TXBUSY;
		end if; 
	end if; 
	end process;

	process(reset_n,clk) begin
	if reset_n='0' then							FIFO_SEND_BUSY<='0';
	elsif clk'event and clk='1' then
		if CLRbit='1' then						FIFO_SEND_BUSY <= '0';
		elsif (FIFOSTS = FIFO_SEND_START) then	FIFO_SEND_BUSY <= '1';
		elsif STS=TRNS_END then					FIFO_SEND_BUSY <= '0';
		else									FIFO_SEND_BUSY <= FIFO_SEND_BUSY;
		end if; 
	end if; 
	end process;


	--------------状態レジスタ----------------
	--受信データ有
	RX_RDYbit	<=	RXFDLY(1);

	--送信可能
	TX_RDYbit	<=	'0'	when TXBUSY='1'				--1バイト送信中
	else			'0'	when FIFO_SEND_BUSY='1' or FIFO_EMPTY='0'		--FIFOからデータ送信中
	else			'0'	when TXEDLY(1)='0'			--送信バッファ・フル
	else			'1';

	STSreg(0)	<=	CLRbit;
	STSreg(1)	<=	RX_RDYbit;
	STSreg(2)	<=	TX_RDYbit;
	STSreg(3)	<=	TXBUSY;
	STSreg(4)	<=	FIFO_EMPTY;
	STSreg(5)	<=	FIFO_FULL;


	--FIFO接続
	FIFO: TxFIFO port map(
		clock	=>	clk,
		data	=>	wrdata,
		rdreq	=>	FIFO_RDREQ,
		sclr	=>	CLRbit,
		wrreq	=>	FIFO_WRREQ,
		empty	=>	FIFO_EMPTY,
		full	=>	FIFO_FULL,
		q		=>	FIFO_Q
	);

	process(clk) begin
	if clk'event and clk='1' then
		if FIFO_RDREQ='1' then	FIFO_Qreg<=FIFO_Q;
		else					FIFO_Qreg<=FIFO_Qreg;
		end if;
	end if;
	end process;


------------------------------------------
--	シーケンサ
------------------------------------------
	process(clk) begin
		if clk'event and clk='1' then
			RXFDLY	<=	RXFDLY(0) & not ft_rxfn;
			TXEDLY	<=	TXEDLY(0) & not ft_txen;
	end if;
	end process;

	------------------------------------
	--メインシーケンサ FT245read/write
	------------------------------------
	process(CLK,RESET_n) begin
	if RESET_n='0' then
		STS	<=	IDLE;
	elsif CLK'event and CLK='1' then
		if CLRbit =	'1' then
			STS	<=	IDLE;
		else
		  case STS is
			when IDLE=>
				if RXFDLY(1) = '1' then							STS	<=	RECV;
				elsif TXEDLY(1)='1' and TXBUSY='1' 	then		STS	<=	TRNS;
				elsif TXEDLY(1)='1' and FIFO_SEND_BUSY='1' then	STS	<=	TRNS;
				else											STS	<=	STS;
				end if;

			--受信処理-------------------
			when RECV=>			--FT245から読み出し
				if SEQ_END = '1' then							STS	<=	WAIT_CPURD;
				else											STS	<=	STS;
				end if;

			when WAIT_CPURD=>
				if CPURD_RXREG = '1' then						STS	<=	RECV_END;
				else											STS	<=	STS;
				end if;

			when RECV_END=>										STS	<=	IDLE;

			--送信処理------------------
			when TRNS=>	
				if SEQ_END = '1' then							STS	<=	TRNS_END;
				else											STS	<=	STS;
				end if;

			when TRNS_END =>									STS	<=	IDLE;

			when others =>										STS	<=	IDLE;
		  end case;
		end if;
	end if;
	end process;

	--FT245 1byte処理タイミング（12クロックで1バイト）
	process(reset_n,clk) begin
	if reset_n='0' then							SEQ_CNT<=0;
	elsif clk'event and clk='1' then
		if (STS = TRNS) then
			if 	SEQ_CNT < CONV_INTEGER(TxRATEreg) then			SEQ_CNT<=SEQ_CNT+1;
			elsif 	SEQ_END='1' then			SEQ_CNT<=0;
			else								SEQ_CNT<=SEQ_CNT;
			end if;
		elsif (STS = RECV) then
			if 	SEQ_CNT<15 then					SEQ_CNT<=SEQ_CNT+1;
			elsif 	SEQ_END='1' then			SEQ_CNT<=0;
			else								SEQ_CNT<=SEQ_CNT;
			end if;
		else									SEQ_CNT<=0;
		end if; 
	end if; 
	end process;

--	SEQ_END	<=	'1'	when SEQ_CNT=11	else	'0';
--2018/07/10
	SEQ_END	<=	'1'	when ((SEQ_CNT = 15) and (STS = RECV))
	else		'1'	when ((SEQ_CNT = CONV_INTEGER(TxRATEreg)-1) and (STS = TRNS))
	else		'0';

	------------------------------------
	--FIFO readシーケンサ
	--FIFO経由でのデータ書き込み制御
	------------------------------------
	process(CLK,RESET_n) begin
	if RESET_n='0' then								FIFOSTS	<=	FIFO_IDLE;
	elsif CLK'event and CLK='1' then
		if CLRbit =	'1' then						FIFOSTS	<=	FIFO_IDLE;
		else
		  case FIFOSTS is
			when FIFO_IDLE=>
				if FIFO_EMPTY = '0' then			FIFOSTS	<=	FIFO_RD_WORD;
				else								FIFOSTS	<=	FIFOSTS;
				end if;

			when FIFO_RD_WORD=>						FIFOSTS	<=	FIFO_SEND_START;

			when FIFO_SEND_START=>					FIFOSTS	<=	WAIT_FIFO_SEND_END;

			when WAIT_FIFO_SEND_END=>
				if SEQ_END = '1' then				FIFOSTS	<=	CHK_WORD_END;
				else								FIFOSTS	<=	FIFOSTS;
				end if;

			when CHK_WORD_END=>	
				if FIFO_BYTE_COUNT >= 3 then		FIFOSTS	<=	FIFO_IDLE;
				else								FIFOSTS	<=	FIFO_SEND_START;
				end if;

			when others =>							FIFOSTS	<=	FIFO_IDLE;
		  end case;
		end if;
	end if;
	end process;


	FIFO_RDREQ	<=	'1'	when 	FIFOSTS = FIFO_RD_WORD	else	'0';

	process(CLK,RESET_n) begin
	if RESET_n='0' then						FIFO_BYTE_COUNT	<=	0;
	elsif CLK'event and CLK='1' then
		if CLRbit =	'1' then				FIFO_BYTE_COUNT	<=	0;
		elsif FIFOSTS = FIFO_RD_WORD then	FIFO_BYTE_COUNT	<=	0;
		elsif FIFOSTS = CHK_WORD_END then	FIFO_BYTE_COUNT	<=	FIFO_BYTE_COUNT+1;
		else								FIFO_BYTE_COUNT	<=	FIFO_BYTE_COUNT;
		end if;
	end if;
	end process;

	-------------------------------------
	--割り込み制御
	-------------------------------------
	RXIRQ_EN	<=	IRQreg(0);

	--受信データ有割り込み
	process(clk,reset_n) begin
	if reset_n='0' then					RXIRQ_STS <= '0';
	elsif clk'event and clk='1' then
		if CLRbit='1' then				RXIRQ_STS <= '0';
--		elsif STS = WAIT_CPURD then		RXIRQ_STS <= '1';
		elsif CPURD_RXREG='1'	then	RXIRQ_STS <= '0';		--受信レジスタ読み出しで割り込み解除
		elsif STS = WAIT_CPURD then		RXIRQ_STS <= '1';
		else							RXIRQ_STS <= RXIRQ_STS;
		end if;
	end if;
	end process;

	IRQreg(2)<=	RXIRQ_STS;

	irq	<=	'1'	when ((RXIRQ_STS='1') and (RXIRQ_EN='1'))
	--else	'1'	when ((TXIRQ_STS='1') and (TXIRQ_EN='1'))
	else	'0';

-------------------------------------
--　FT245 signal 
-------------------------------------

	ft_resetn	<=	'1';	--not used

	-------------------------------------
	--recieve 
	-------------------------------------
	process(clk,reset_n) begin
	if reset_n='0' then								ft_rdn <= '1';
	elsif clk'event and clk='1' then
		if ((STS = RECV) and (SEQ_CNT<6 )) then		ft_rdn <= '0';
		else										ft_rdn <= '1';
		end if;
	end if;
	end process;

	process(clk,reset_n) begin
	if reset_n='0' then								RXreg <= (others=>'0');
	elsif clk'event and clk='1' then
		if ((STS = RECV) and (SEQ_CNT=6 )) then		RXreg	<= ft_rxdata;
		else										RXreg	<= RXreg;
		end if;
	end if;
	end process;

	-------------------------------------
	--send 
	-------------------------------------

	process(clk,reset_n) begin
	if reset_n='0' then								ft_wr <= '0';
	elsif clk'event and clk='1' then
		if ((STS = TRNS) and (SEQ_CNT<6 )) then		ft_wr <= '1';
		else										ft_wr <= '0';
		end if;
	end if;
	end process;

	process(clk,reset_n) begin
	if reset_n='0' then								ft_txdata_oe <= '0';
	elsif clk'event and clk='1' then
		if STS = TRNS then							ft_txdata_oe <= '1';
		else										ft_txdata_oe <= '0';
		end if;
	end if;
	end process;

	ft_txdata	<=	FIFO_Qreg(31 downto 24)	when ((FIFOSTS = WAIT_FIFO_SEND_END) and FIFO_BYTE_COUNT=3)
	else			FIFO_Qreg(23 downto 16)	when ((FIFOSTS = WAIT_FIFO_SEND_END) and FIFO_BYTE_COUNT=2)
	else			FIFO_Qreg(15 downto 8)	when ((FIFOSTS = WAIT_FIFO_SEND_END) and FIFO_BYTE_COUNT=1)
	else			FIFO_Qreg(7 downto 0)	when ((FIFOSTS = WAIT_FIFO_SEND_END) and FIFO_BYTE_COUNT=0)
	else			TXreg;	--CPUから1バイト送出


end rtl;
