--
--	PDM MIC interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pdm_core2 is
Port (	clk		    : in std_logic;
        reset_n         : in std_logic;

        clr_in          :in std_logic;

		pdmclk_in     	:in  std_logic;		--2.048MHz   2.048MHz/128 = 16k
		pdmdata_in     	:in  std_logic_vector(3 downto 0);

		valid			:out std_logic;
        valid_ch      	:out std_logic_vector(2 downto 0);	
        valid_sample	:out std_logic_vector(23 downto 0);	
		valid_data		:out std_logic_vector(15 downto 0);	

        ch_in		   :in std_logic_vector(2 downto 0);
        addr_in        :in std_logic_vector(4 downto 0);
        data_out       :out std_logic_vector(31 downto 0);
        
        offset0			:in std_logic_vector(13 downto 0);
        offset1			:in std_logic_vector(13 downto 0);
        offset2			:in std_logic_vector(13 downto 0);
        offset3			:in std_logic_vector(13 downto 0);
        offset4			:in std_logic_vector(13 downto 0);
        offset5			:in std_logic_vector(13 downto 0);
        offset6			:in std_logic_vector(13 downto 0);
        offset7			:in std_logic_vector(13 downto 0);
        
        gain_in			:in std_logic_vector(3 downto 0);
        mode_freq		:in std_logic
      );
end pdm_core2;

architecture RTL of pdm_core2 is
    component pdm_if
    Port (	clk		    : in std_logic;
            reset_n         : in std_logic;

            clr_in          :in std_logic;

            pdmclk_in     	:in  std_logic;	
            pdmdata_in     	:in  std_logic_vector(3 downto 0);

            cnt_out         :out std_logic_vector(4 downto 0);
            buf_ready       :out std_logic;

            ch              :in std_logic_vector(2 downto 0);
            position        :in std_logic_vector(4 downto 0);
            data_out        :out std_logic_vector(7 downto 0)
        );
    end component;
    signal  IF_BUF_RDY  :std_logic;
    signal  IF_BYTE_CNT  :std_logic_vector(4 downto 0);

    signal  IF_BUF_CH       :std_logic_vector(2 downto 0);
    signal  IF_BUF_ADDR     :std_logic_vector(5 downto 0);
    signal  IF_BUF_ADDR_CNT :integer range 0 to 63;
    signal  IF_BUF_DATA     :std_logic_vector(7 downto 0);

	type FIRREQSTS_TYPE is(
		RQ_IDLE,
		RQ_START,
		RQ_CH_START,
		RQ_CH_BUSY,
		RQ_CH_END,
		RQ_WAIT,
		RQ_END
	);
    signal  FIR_REQ:FIRREQSTS_TYPE;
    signal  FIR_CH_CNT  :integer range 0 to 15;
    signal  FIR_CH_CNT_VECT  :std_logic_vector(2 downto 0);
    signal  FIR_START   :std_logic;

    component fir_1b128t
    Port (	
        clk			    : in std_logic;
		reset_n		    : in std_logic;		

		start_in		:in  std_logic;
		busy_out        :out std_logic;

		addr_inc		:out std_logic;
		bitdata_data_in :in std_logic_vector(7 downto 0 );

		data_out		:out std_logic_vector(13 downto 0);
		valid_out       :out std_logic
	);
    end component;
    signal  FIR_BUSY    :std_logic;
    signal  FIR_ADDRINC    :std_logic;

    signal  POSITION_CNT    :integer range 0 to 63;
    signal  POSITION_CNT_START    :integer range 0 to 63;
    signal  POSITION_CNT_VECT   :std_logic_vector(5 downto 0);

    signal  SMPLCNT_64k :integer range 0 to 65535;       
    signal  SMPLCNT_64k_VECT :std_logic_vector(15 downto 0);       


	constant	SMPLCNT_32K_MAX	:integer :=65536 * 256 - 1;	--24bit

    signal  SMPLCNT_32k :integer range 0 to SMPLCNT_32K_MAX;       
    signal  SMPLCNT_32k_VECT :std_logic_vector(23 downto 0);       

    signal  FIR0_VALID_OUT  :std_logic;
    signal  FIR0_DATA_OUT   :std_logic_vector(13 downto 0);

	signal	OFFSET		:integer range 0 to 16383;
	signal	OFFSET_SUM	:integer range 0 to 16383;


    component wave_buf
	PORT
	(
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
    end component;

    signal  BUF64k_WR       :std_logic;
    signal  BUF64k_FILLED       :std_logic;
    signal  BUF64k_WRADDR   :std_logic_vector(9 downto  0);
    signal  BUF64k_RDADDR   :std_logic_vector(9 downto  0);
    signal  BUF64k_WRDATA   :std_logic_vector(15 downto  0);
    signal  BUF64k_RDQ      :std_logic_vector(15 downto  0);

    signal  BUF32k_WR       :std_logic;
    signal  BUF32k_WRADDR   :std_logic_vector(9 downto  0);
    signal  BUF32k_RDADDR   :std_logic_vector(7 downto  0);
    signal  BUF32k_WRDATA   :std_logic_vector(15 downto  0);
    signal  BUF32k_RDQ      :std_logic_vector(31 downto  0);



	component wave_buf_16_32
	PORT
	(
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	end component;

    component fir_16b63t
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
    end component;

    signal  FIR2_DATAOUT	:std_logic_vector(27 downto 0);
    signal  FIR2_OUT	:std_logic_vector(15 downto 0);

    signal  BUF64_RDY   :std_logic_vector(1 downto 0);
    signal  FIR2_REQ	:FIRREQSTS_TYPE;
    signal  FIR2_CH_CNT :integer range 0 to 15;
    signal  FIR2_CH_CNT_VECT  :std_logic_vector(3 downto 0);
    signal  FIR2_START   :std_logic;
    signal  FIR2_BUSY   :std_logic;
	signal	SRC_POS		:std_logic_vector(6 downto 0);


    signal  DATA64_0,DATA32_0   :std_logic_vector(15 downto 0);
    signal  DATA64_1,DATA32_1   :std_logic_vector(15 downto 0);
    signal  DATA64_2,DATA32_2   :std_logic_vector(15 downto 0);
    signal  DATA64_3,DATA32_3   :std_logic_vector(15 downto 0);
    signal  DATA64_4,DATA32_4   :std_logic_vector(15 downto 0);
    signal  DATA64_5,DATA32_5   :std_logic_vector(15 downto 0);
    signal  DATA64_6,DATA32_6   :std_logic_vector(15 downto 0);
    signal  DATA64_7,DATA32_7   :std_logic_vector(15 downto 0);


    begin
    --1bit pdmdata store 8bit x 32 word x 8ch 
    PDMIF:pdm_if port map(
    	clk	=>  clk,
        reset_n =>  reset_n,

        clr_in  =>  clr_in,

        pdmclk_in  => pdmclk_in ,  
        pdmdata_in => pdmdata_in ,  

        cnt_out     =>  IF_BYTE_CNT,
        buf_ready   =>  IF_BUF_RDY,

        ch          => IF_BUF_CH(2 downto 0),
        position    => IF_BUF_ADDR(4 downto 0),
        data_out    => IF_BUF_DATA
    );

    --start "fir_1b128t" each 32pdmclk;
    process(clk,reset_n) begin
    if reset_n='0' then                 FIR_REQ <=  RQ_IDLE;
    elsif clk'event and clk='1' then
        if clr_in = '1' then            FIR_REQ <=  RQ_IDLE;
        else
            case FIR_REQ is
                when RQ_IDLE=>
                    if IF_BUF_RDY='1' and IF_BYTE_CNT(1 downto 0)="00" then 
                                        FIR_REQ <=  RQ_START;
                    else                FIR_REQ <=  FIR_REQ;
                    end if;

                when RQ_START=>         FIR_REQ <=  RQ_CH_START;

                when RQ_CH_START=>      FIR_REQ <=  RQ_CH_BUSY;

                when RQ_CH_BUSY=>
                    if FIR_BUSY = '0' then      
                                        FIR_REQ <=  RQ_CH_END;
                    else                FIR_REQ <=  FIR_REQ;
                    end if;
                when RQ_CH_END => 
                        if FIR_CH_CNT=7 then    
                                        FIR_REQ <=  RQ_WAIT;
                        else            FIR_REQ <=  RQ_CH_START;
                        end if;
                when RQ_WAIT => 
                    if IF_BYTE_CNT(1 downto 0)/="00" then 
                                        FIR_REQ <=  RQ_END;
                    else                FIR_REQ <=  FIR_REQ;
                    end if;
                when RQ_END =>          FIR_REQ <=  RQ_IDLE;
                when others =>          FIR_REQ <=  RQ_IDLE;
            end case;
        end if;
    end if;
    end process;

    FIR_START   <=  '1' when FIR_REQ = RQ_CH_START else '0';


    --
    process(clk,reset_n) begin
    if reset_n='0' then                 SMPLCNT_64k <=  0;
    elsif clk'event and clk='1' then
        if clr_in = '1' then            SMPLCNT_64k <=  0;
        elsif FIR_REQ = RQ_END then
            if SMPLCNT_64k=65535 then    SMPLCNT_64k <=  0;
            else                        SMPLCNT_64k <=  SMPLCNT_64k+1;
            end if;
        else                            SMPLCNT_64k <=  SMPLCNT_64k;
        end if;
    end if;
    end process;



    process(clk) begin
    if clk'event and clk='1' then
        if FIR_REQ = RQ_IDLE then       FIR_CH_CNT<=0;
        elsif FIR_REQ = RQ_CH_END then
            if FIR_CH_CNT<7 then        FIR_CH_CNT<=FIR_CH_CNT+1;
            else                        FIR_CH_CNT<=FIR_CH_CNT;
            end if;
        else                            FIR_CH_CNT<=FIR_CH_CNT;
        end if;
    end if;
    end process;
    IF_BUF_CH  <=  CONV_STD_LOGIC_VECTOR(FIR_CH_CNT,3);

    -- FIR input  POSITION_CNT_START = 0: 0-15
    --                                 4: 4-19;
    --                                 : ;
    --                                 16: 16-31;
    --                                 20: 20-31,0-3;
    --                                 :
    POSITION_CNT_START <=   0  when  IF_BYTE_CNT= b"1_0000"
    else                    4  when  IF_BYTE_CNT= b"1_0100"
    else                    8  when  IF_BYTE_CNT= b"1_1000"
    else                    12  when  IF_BYTE_CNT= b"1_1100"
    else                    16  when  IF_BYTE_CNT= b"0_0000"
    else                    20  when  IF_BYTE_CNT= b"0_0100"
    else                    24  when  IF_BYTE_CNT= b"0_1000"
    else                    28  when  IF_BYTE_CNT= b"0_1100"
    else                    0;

    process(clk) begin
    if clk'event and clk='1' then 
        if FIR_REQ =  RQ_CH_START then
            IF_BUF_ADDR_CNT <=  POSITION_CNT_START;
        elsif FIR_ADDRINC='1' then
            IF_BUF_ADDR_CNT <=  IF_BUF_ADDR_CNT +1;
        else
            IF_BUF_ADDR_CNT <=  IF_BUF_ADDR_CNT;
        end if;
    end if;
    end process;

    IF_BUF_ADDR <=  CONV_STD_LOGIC_VECTOR(IF_BUF_ADDR_CNT,6);


    FIR: fir_1b128t port map(
    	clk	=>  clk,
        reset_n =>  reset_n,


		start_in    =>  FIR_START,
		busy_out    =>  FIR_BUSY,

		addr_inc	=>  FIR_ADDRINC,
		bitdata_data_in =>  IF_BUF_DATA,

		data_out	=>  FIR0_DATA_OUT,
		valid_out   => FIR0_VALID_OUT
	);


-- ここでオフセット調整

	OFFSET	<=	CONV_INTEGER(offset0)	when FIR_CH_CNT=0
	else		CONV_INTEGER(offset1)	when FIR_CH_CNT=1
	else		CONV_INTEGER(offset2)	when FIR_CH_CNT=2
	else		CONV_INTEGER(offset3)	when FIR_CH_CNT=3
	else		CONV_INTEGER(offset4)	when FIR_CH_CNT=4
	else		CONV_INTEGER(offset5)	when FIR_CH_CNT=5
	else		CONV_INTEGER(offset6)	when FIR_CH_CNT=6
	else		CONV_INTEGER(offset7)	when FIR_CH_CNT=7
	else		0;


    process(clk) begin
    if clk'event and clk='1' then 
        OFFSET_SUM <= OFFSET + CONV_INTEGER( FIR0_DATA_OUT );
        BUF64k_WR	<=	FIR0_VALID_OUT;
    end if;
    end process;
	
	BUF64k_WRDATA(15 downto 14)<="00";
	BUF64k_WRDATA(13 downto 0) <= CONV_STD_LOGIC_VECTOR(OFFSET_SUM,14);
 

    SMPLCNT_64k_VECT <=  CONV_STD_LOGIC_VECTOR(SMPLCNT_64k,16);
    FIR_CH_CNT_VECT <=  CONV_STD_LOGIC_VECTOR( FIR_CH_CNT,3);

    BUF64k_WRADDR   <=  FIR_CH_CNT_VECT &  SMPLCNT_64k_VECT(6 DOWNTO 0);


	--シミュレーション　デバッグ用　たぶん回路に落ちない
    process(clk) begin
    if clk'event and clk='1' then

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0000" then
            DATA64_0  <=  "00" & FIR0_DATA_OUT;
        else
            DATA64_0  <=  DATA64_0;
        end if;

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0001" then
            DATA64_1  <=  "00" & FIR0_DATA_OUT;
        else
            DATA64_1  <=  DATA64_1;
        end if;

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0010" then
            DATA64_2  <=  "00" & FIR0_DATA_OUT;
        else
            DATA64_2  <=  DATA64_2;
        end if;

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0011" then
            DATA64_3  <=  "00" & FIR0_DATA_OUT;
        else
            DATA64_3  <=  DATA64_3;
        end if;
    end if;
    end process;



    BUF64k: wave_buf port map(
		clock		=>  clk,
		data		=>  BUF64k_WRDATA,
		rdaddress	=>  BUF64k_RDADDR,
		wraddress	=>  BUF64k_WRADDR,
		wren		=>  BUF64k_WR,
		q		    =>  BUF64k_RDQ
	);


    process(clk,reset_n) begin
    if reset_n='0' then                 BUF64k_FILLED <=  '0';
    elsif clk'event and clk='1' then
        if clr_in = '1' then            BUF64k_FILLED <=  '0';
        elsif SMPLCNT_64k > 63 then     BUF64k_FILLED <=  '1';
        else                            BUF64k_FILLED <=  BUF64k_FILLED;
        end if;
    end if;
    end process;



    process(clk,reset_n) begin
    if reset_n='0' then                 BUF64_RDY <=  "00";
    elsif clk'event and clk='1' then
        if clr_in = '1' then            BUF64_RDY <=  "00";
        else
        	if mode_freq = '0' then
	            if BUF64k_FILLED='1' and  SMPLCNT_64k_VECT(0)='0' then				--for 32k sample 2019/06/17
					BUF64_RDY(0)<='1';
				else
                	 BUF64_RDY(0)<='0';
                end if;
			else
				if  BUF64k_FILLED='1'  and  SMPLCNT_64k_VECT(1 downto 0)="00" then	--for 16k sample 2019/06/17
					BUF64_RDY(0)<='1';
				else
					BUF64_RDY(0)<='0';
            	end if;
			end if;

            BUF64_RDY(1) <= BUF64_RDY(0);

        end if;
    end if;
    end process;

    --start "fir_16b31t"
    process(clk,reset_n) begin
    if reset_n='0' then                 FIR2_REQ <=  RQ_IDLE;
    elsif clk'event and clk='1' then
        if clr_in = '1' then            FIR2_REQ <=  RQ_IDLE;
        else
            case FIR2_REQ is
                when RQ_IDLE=>
                    if BUF64_RDY = "01" then
                                        FIR2_REQ <=  RQ_START;
                    else                FIR2_REQ <=  FIR2_REQ;
                    end if;
                when RQ_START=>         FIR2_REQ <=  RQ_CH_START;
                when RQ_CH_START=>      FIR2_REQ <=  RQ_CH_BUSY;
                when RQ_CH_BUSY=>
                    if FIR2_BUSY = '0' then      
                                        FIR2_REQ <=  RQ_CH_END;
                    else                FIR2_REQ <=  FIR2_REQ;
                    end if;
                when RQ_CH_END => 
                        if FIR2_CH_CNT=7 then    
                                        FIR2_REQ <=  RQ_END;
                        else            FIR2_REQ <=  RQ_CH_START;
                        end if;
                when RQ_END =>          FIR2_REQ <=  RQ_IDLE;
                when others =>          FIR2_REQ <=  RQ_IDLE;
            end case;
        end if;
    end if;
    end process;

    FIR2_START   <=  '1' when FIR2_REQ = RQ_CH_START else '0';

    --
    process(clk,reset_n) begin
    if reset_n='0' then                 SMPLCNT_32k <=  0;
    elsif clk'event and clk='1' then
        if clr_in = '1' then            SMPLCNT_32k <=  0;
        elsif FIR2_REQ = RQ_END then
            if SMPLCNT_32k=SMPLCNT_32k_MAX then
            						    SMPLCNT_32k <=  0;
            else                        SMPLCNT_32k <=  SMPLCNT_32k+1;
            end if;
        else                            SMPLCNT_32k <=  SMPLCNT_32k;
        end if;
    end if;
    end process;

    SMPLCNT_32k_VECT    <=  CONV_STD_LOGIC_VECTOR(SMPLCNT_32k,24);

    valid_sample	<=  SMPLCNT_32k_VECT;
	valid			<=	BUF32k_WR;
    valid_ch		<=	BUF32k_WRADDR(8 downto 6);
	valid_data		<=	BUF32k_WRDATA;

    process(clk) begin
    if clk'event and clk='1' then
        if FIR2_REQ = RQ_IDLE then       FIR2_CH_CNT <= 0;
        elsif FIR2_REQ = RQ_CH_END then
            if FIR2_CH_CNT<7 then        FIR2_CH_CNT <= FIR2_CH_CNT+1;
            else                         FIR2_CH_CNT <= FIR2_CH_CNT;
            end if;
        else                             FIR2_CH_CNT <= FIR2_CH_CNT;
        end if;
    end if;
    end process;
    FIR2_CH_CNT_VECT  <=  CONV_STD_LOGIC_VECTOR(FIR2_CH_CNT,4);


	SRC_POS	<=	SMPLCNT_32k_VECT(5 downto 0) & '0'	when mode_freq = '0'	--for 32k sample 2019/06/17
	else		SMPLCNT_32k_VECT(4 downto 0) & "00";						--for 16k sample 2019/06/17



    FIR2: fir_16b63t port map(
        	clk         =>	clk,
            reset_n     =>  reset_n,

            start_in    =>  FIR2_START,
            busy_out    =>  FIR2_BUSY,
            ch_in       =>  FIR2_CH_CNT_VECT(2 downto 0),
 --           pos_in      =>  SMPLCNT_32k_VECT(6 downto 0),
           	pos_in      =>  SRC_POS,

            buf_ch      =>  BUF64k_RDADDR(9 downto 7),
            buf_pos     =>  BUF64k_RDADDR(6 downto 0),
            buf_datain  =>  BUF64k_RDQ(13 downto 0),

            ch_out      =>  BUF32k_WRADDR(8 downto 6),
            pos_out     =>  open,--BUF32k_WRADDR(6 downto 0),
            data_out    =>  FIR2_DATAOUT,
            write_out   =>  BUF32k_WR
        );

	FIR2_OUT	<=	FIR2_DATAOUT(27 downto 12)	when gain_in= "0000"
	else			FIR2_DATAOUT(26 downto 11)	when gain_in= "0001"
	else			FIR2_DATAOUT(25 downto 10)	when gain_in= "0010"
	else			FIR2_DATAOUT(24 downto 9)	when gain_in= "0011"
	else			FIR2_DATAOUT(23 downto 8)	when gain_in= "0100"
	else			FIR2_DATAOUT(22 downto 7)	when gain_in= "0101"
	else			FIR2_DATAOUT(21 downto 6)	when gain_in= "0110"
	else			FIR2_DATAOUT(20 downto 5)	when gain_in= "0111"
	else			(others=>'0');


	BUF32k_WRDATA	<=	X"8001"	when FIR2_OUT = X"8000"		--X"8000",X"7FFF"は
	else				X"7FFE"	when FIR2_OUT = X"7FFF"		--通信時のdelimitterに予約
	else				FIR2_OUT;

	BUF32k_WRADDR(5 downto 0)	<=	SMPLCNT_32k_VECT(5 downto 0);

	--シミュレーション　デバッグ用　たぶん回路に落ちない
    process(clk) begin
    if clk'event and clk='1' then

        if BUF32k_WR='1' and BUF32k_WRADDR(8 downto 6)="000" then
            DATA32_0  <=  BUF32k_WRDATA;
        else
            DATA32_0  <=  DATA32_0;
        end if;

        if BUF32k_WR='1' and BUF32k_WRADDR(8 downto 6)="001" then
            DATA32_1  <=  BUF32k_WRDATA;
        else
            DATA32_1  <=  DATA32_1;
        end if;

        if BUF32k_WR='1' and BUF32k_WRADDR(8 downto 6)="010" then
            DATA32_2  <=  BUF32k_WRDATA;
        else
            DATA32_2  <=  DATA32_2;
        end if;

        if BUF32k_WR='1' and BUF32k_WRADDR(8 downto 6)="011" then
            DATA32_3  <=  BUF32k_WRDATA;
        else
            DATA32_3  <=  DATA32_3;
        end if;

    end if;
    end process;



    BUF32k: wave_buf_16_32 port map(
		clock		=>  clk,
		data		=>  BUF32k_WRDATA,
		rdaddress	=>  BUF32k_RDADDR,
		wraddress	=>  BUF32k_WRADDR(8 downto 0),
		wren		=>  BUF32k_WR,
		q		    =>  BUF32k_RDQ
	);

	data_out		<=	BUF32k_RDQ;
    BUF32k_RDADDR	<=	ch_in & addr_in;



end RTL;