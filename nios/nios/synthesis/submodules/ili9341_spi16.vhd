--
--	16bit Data mode 追加
--	Gray mode 追加
--
--
--	reg map
--
--	0x0	Cmd reg
--	
--	0x4	8bit data reg
--	
--	0x8	CntrolReg
--		bit0:reset
--		bit1:Gray
--
--	0xc	16bitData reg
--
--
--
--
--
--
--
--
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ili9341_spi16 is
	Port (	clk			: in std_logic;
			reset_n		: in std_logic;		
			address		: in std_logic_vector(3 downto 2);
			ben			: in std_logic_vector(3 downto 0);
			sel			: in std_logic;		
			wr			: in std_logic;		
			wrdata		: in std_logic_vector(31 downto 0);
			waitreq		:out std_logic;

			rstn		: out std_logic;
			cs			: out std_logic;
			dc			: out std_logic;
			sdata		: out std_logic;
			sclk		: out std_logic
	);
end ili9341_spi16;

architecture rtl of ili9341_spi16 is

	constant	DivRate		:integer :=100000000/50000000; --=2
	signal	DIVCNT			:integer range 0 to DivRate;	--0.5bitの周期(半周期=20ns)を発生させる SCLK=25MHz
	signal	CLKEN_BITCNT	:std_logic;


	signal	HBIT_CNT		:integer range 0 to 63;
	signal	HBIT_VECT		:std_logic_vector(5 downto 0);


	signal	WR_CmdData		:std_logic;	--write to register
	signal	WR_CTRL			:std_logic;
	signal	WR_Data16		:std_logic;
	signal	CmdDataReg		:std_logic_vector(7 downto 0);	--8bit data & 8bit Command
	signal	Data16Reg		:std_logic_vector(15 downto 0);	--16bit data

	signal	CtrlReg			:std_logic_vector(1 downto 0);
		signal	RESETbit	:std_logic;			--CTRLreg bit0	
		signal	Graybit		:std_logic;			--CTRLreg bit1	0:16bit color,1:5bit Gray

	signal	DCbit			:std_logic;			--0:command ,1:data
	signal	DC_INT			:std_logic;

	signal	AVALON_RDY	:std_logic;	

	-----------------------------------
	--Sequencer
	-----------------------------------
	--1byte単位でFT245への書き込み制御を行う
	type SPI_SEQ_TYPE is(
		SPI_IDLE,
		SPI_START,
		SPI_SYNC,
		SPI_BUSY,
		SPI16_START,
		SPI16_SYNC,
		SPI16_BUSY,
		SPI_END
	);
	
	signal	SPISEQ	:SPI_SEQ_TYPE;
	signal	SER_DATA8	:std_logic;
	signal	SER_DATA16	:std_logic;

begin

	process(clk,reset_n) begin
	if reset_n='0' then		DIVCNT <= DivRate-1;
	elsif clk'event and clk='1' then
		if DIVCNT = 0 then	DIVCNT <= DivRate-1;
		else				DIVCNT <= DIVCNT-1;
		end if;
	end if;
	end process;
	
	CLKEN_BITCNT	<=	'1'	when DIVCNT=0	else	'0';


	process(clk,reset_n) begin
	if reset_n='0' then					HBIT_CNT <= 0;
	elsif clk'event and clk='1' then
		if ((SPISEQ = SPI_BUSY) or (SPISEQ = SPI16_BUSY)) then
			if CLKEN_BITCNT='1' then 
				if HBIT_CNT < 63  then 	HBIT_CNT <= HBIT_CNT+1;
				else					HBIT_CNT <= HBIT_CNT;
				end if;
			else						HBIT_CNT <= HBIT_CNT;
			end if;
		else
			HBIT_CNT <= 0;
		end if;
	end if;
	end process;

	HBIT_VECT	<=	CONV_STD_LOGIC_VECTOR(HBIT_CNT,6);


	------------------------------------------
	--	register write
	------------------------------------------
	WR_CmdData		<=	wr	when sel='1' and address(3)='0' 			and AVALON_RDY='1'	else	'0';	--0x0,0x4

	WR_Data16		<=	wr	when sel='1' and address(3 downto 2)="11" 	and AVALON_RDY='1'	else	'0';	--0xc

	WR_CTRL			<=	wr	when sel='1' and address(3 downto 2)="10"	and AVALON_RDY='1'	else	'0';	--0x8

	process(clk,reset_n) begin
	if reset_n='0' then

		CmdDataReg	<=(others=>'0');
		CtrlReg	<=(others=>'0');
		DCbit	<= '0';
		
	elsif clk'event and clk='1' then
		--------------制御レジスタ----------------
		if WR_CmdData='1' and ben(0)='1' then	CmdDataReg	<=	wrdata(7 downto 0);
		else									CmdDataReg	<=	CmdDataReg;
		end if;

		if WR_CTRL='1'  and ben(0)='1' 	then	CtrlReg	<=	wrdata(1 downto 0);
		else									CtrlReg	<=	CtrlReg;
		end if;

		if WR_Data16='1' then
			if Graybit='0' then		--RGB565
				if ben(0)='1' then	Data16Reg(7 downto 0)	<=	wrdata(7 downto 0);
				else				Data16Reg(7 downto 0)	<=	Data16Reg(7 downto 0);
				end if;
				
				if ben(1)='1' then	Data16Reg(15 downto 8)	<=	wrdata(15 downto 8);
				else				Data16Reg(15 downto 8)	<=	Data16Reg(15 downto 8);
				end if;
			else	--Gray
--				if ben(0)='1' then	Data16Reg	<=	wrdata(15 downto 11) & wrdata(15 downto 10) & wrdata(15 downto 11);
				if ben(0)='1' then	Data16Reg	<=	wrdata(7 downto 3) & wrdata(7 downto 2) & wrdata(7 downto 3);
				else				Data16Reg	<=	Data16Reg;
				end if;
			end if;
		else						Data16Reg	<=	Data16Reg;
		end if;


		if WR_CmdData='1'  	then	DCbit	<=	address(2);
		elsif WR_Data16='1'	then	DCbit	<=	'1';
		else						DCbit	<=	DCbit;
		end if;

	end if;
	end process;



	RESETbit	<=	CtrlReg(0);
	Graybit		<=	CtrlReg(1);

	AVALON_RDY	<=	'1'	when SPISEQ	= SPI_IDLE
	else			'0';

	waitreq	<=	'0'	when SPISEQ	= SPI_IDLE
	else		'1';

	-----------------------------------
	--Sequencer
	-----------------------------------
	--1byte単位でILI9341へのSPI書き込み制御を行う
	process(clk,reset_n) begin
	if reset_n='0' then						SPISEQ	<=	SPI_IDLE;
	elsif clk'event and clk='1' then
		if RESETbit='1' then 				SPISEQ	<=	SPI_IDLE;
		else
			case SPISEQ is
				when SPI_IDLE=>
					if WR_CmdData='1' then	SPISEQ	<=	SPI_START;
					elsif WR_Data16='1' then SPISEQ	<=	SPI16_START;
					else					SPISEQ	<=	SPISEQ;
					end if;

				when SPI_START=>			SPISEQ	<=	SPI_SYNC;

				when SPI_SYNC=>
					if CLKEN_BITCNT='1' then SPISEQ	<=	SPI_BUSY;
					else					SPISEQ	<=	SPISEQ;
					end if;

				when SPI_BUSY=>
					if HBIT_CNT >=16 then	SPISEQ	<=	SPI_END;
					else					SPISEQ	<=	SPISEQ;
					end if;

				when SPI16_START=>			SPISEQ	<=	SPI16_SYNC;

				when SPI16_SYNC=>
					if CLKEN_BITCNT='1' then SPISEQ	<=	SPI16_BUSY;
					else					SPISEQ	<=	SPISEQ;
					end if;

				when SPI16_BUSY=>
					if HBIT_CNT >=34  then	SPISEQ	<=	SPI_END;
					else					SPISEQ	<=	SPISEQ;
					end if;

				when SPI_END=>				
					if CLKEN_BITCNT='1' then SPISEQ	<=	SPI_IDLE;
					else					SPISEQ	<=	SPISEQ;
					end if;
				when others=>				SPISEQ	<=	SPI_IDLE;
			end case;
		end if;
	end if;
	end process;


	SER_DATA8	<=	CmdDataReg(7)	when HBIT_VECT(5 downto 1) = "00000"	--0
	else			CmdDataReg(6)	when HBIT_VECT(5 downto 1) = "00001"	--1
	else			CmdDataReg(5)	when HBIT_VECT(5 downto 1) = "00010"	--2
	else			CmdDataReg(4)	when HBIT_VECT(5 downto 1) = "00011"	--3
	else			CmdDataReg(3)	when HBIT_VECT(5 downto 1) = "00100"	--4
	else			CmdDataReg(2)	when HBIT_VECT(5 downto 1) = "00101"    --5
	else			CmdDataReg(1)	when HBIT_VECT(5 downto 1) = "00110"    --6
	else			CmdDataReg(0)	when HBIT_VECT(5 downto 1) = "00111"	--7
	else			'0';                                                    --

	SER_DATA16	<=	Data16Reg(15)	when HBIT_VECT(5 downto 1) = "00000"	--0
	else			Data16Reg(14)	when HBIT_VECT(5 downto 1) = "00001"	--1
	else			Data16Reg(13)	when HBIT_VECT(5 downto 1) = "00010"	--2
	else			Data16Reg(12)	when HBIT_VECT(5 downto 1) = "00011"	--3
	else			Data16Reg(11)	when HBIT_VECT(5 downto 1) = "00100"	--4
	else			Data16Reg(10)	when HBIT_VECT(5 downto 1) = "00101"    --5
	else			Data16Reg(9)	when HBIT_VECT(5 downto 1) = "00110"    --6
	else			Data16Reg(8)	when HBIT_VECT(5 downto 1) = "00111"	--7

	else			Data16Reg(7)	when HBIT_VECT(5 downto 1) = "01001"	--9
	else			Data16Reg(6)	when HBIT_VECT(5 downto 1) = "01010"    --10
	else			Data16Reg(5)	when HBIT_VECT(5 downto 1) = "01011"    --11
	else			Data16Reg(4)	when HBIT_VECT(5 downto 1) = "01100"    --12
	else			Data16Reg(3)	when HBIT_VECT(5 downto 1) = "01101"    --13
	else			Data16Reg(2)	when HBIT_VECT(5 downto 1) = "01110"    --14
	else			Data16Reg(1)	when HBIT_VECT(5 downto 1) = "01111"    --15
	else			Data16Reg(0)	when HBIT_VECT(5 downto 1) = "10000"    --16

	else			'0';                                              


	--signal output
	process(clk) begin
	if clk'event and clk='1' then

		if(SPISEQ =	SPI16_BUSY) then	sdata <= SER_DATA16;
		else							sdata <= SER_DATA8;
		end if;

		if (SPISEQ = SPI_BUSY) then
			if(HBIT_CNT >= 0) and (HBIT_CNT <16 ) then		cs<='0';
			else											cs<='1';
			end if;
		elsif (SPISEQ = SPI16_BUSY) then
			if(HBIT_CNT >= 0) and (HBIT_CNT <16 ) then		cs<='0';
			elsif(HBIT_CNT >= 18) and (HBIT_CNT <34 ) then	cs<='0';
			else											cs<='1';
			end if;
		else												cs<='1';
		end if;

		if (SPISEQ = SPI_BUSY) then
			if(HBIT_CNT >= 0) and (HBIT_CNT <16 ) then		sclk <=	HBIT_VECT(0);
			else											sclk <=	'0';
			end if;
		elsif (SPISEQ = SPI16_BUSY) then
			if(HBIT_CNT >= 0) and (HBIT_CNT <16 ) then		sclk <=	HBIT_VECT(0);
			elsif(HBIT_CNT >= 18) and (HBIT_CNT <34 ) then	sclk <=	HBIT_VECT(0);
			else											sclk <=	'0';
			end if;
		else												sclk <=	'0';
		end if;

		if ((SPISEQ = SPI_START) or(SPISEQ = SPI16_START)) 	then
											DC_INT		<=	DCbit;
		else								DC_INT		<=	DC_INT;
		end if;

	end if;
	end process;

	dc		<=	DC_INT;

	rstn	<=	not RESETbit;



end rtl;
