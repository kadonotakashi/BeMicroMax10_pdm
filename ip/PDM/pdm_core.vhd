--
--	PDM MIC interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pdm_core is
Port (	clk		    : in std_logic;
        reset_n         : in std_logic;

        clr_in          :in std_logic;

		pdmclk_in     	:in  std_logic;
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
        offset7			:in std_logic_vector(13 downto 0)
	);
end pdm_core;

architecture RTL of pdm_core is
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

    signal  SMPLCNT_88k :integer range 0 to 65535;       
    signal  SMPLCNT_88k_VECT :std_logic_vector(15 downto 0);       


	constant	SMPLCNT_44K_MAX	:integer :=65536 * 256 - 1;	--24bit

    signal  SMPLCNT_44k :integer range 0 to SMPLCNT_44K_MAX;       
    signal  SMPLCNT_44k_VECT :std_logic_vector(23 downto 0);       

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

    signal  BUF88k_WR       :std_logic;
    signal  BUF88k_WRADDR   :std_logic_vector(9 downto  0);
    signal  BUF88k_RDADDR   :std_logic_vector(9 downto  0);
    signal  BUF88k_WRDATA   :std_logic_vector(15 downto  0);
    signal  BUF88k_RDQ      :std_logic_vector(15 downto  0);

    signal  BUF44k_WR       :std_logic;
    signal  BUF44k_WRADDR   :std_logic_vector(9 downto  0);
    signal  BUF44k_RDADDR   :std_logic_vector(7 downto  0);
    signal  BUF44k_WRDATA   :std_logic_vector(15 downto  0);
    signal  BUF44k_RDQ      :std_logic_vector(31 downto  0);

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

    component fir_16b31t
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
            data_out        :out std_logic_vector(15 downto 0);
            write_out       :out std_logic
        );
    end component;

    signal  FIR2_DATAOUT	:std_logic_vector(15 downto 0);
    signal  BUF88_RDY   :std_logic_vector(1 downto 0);
    signal  FIR2_REQ	:FIRREQSTS_TYPE;
    signal  FIR2_CH_CNT :integer range 0 to 15;
    signal  FIR2_CH_CNT_VECT  :std_logic_vector(3 downto 0);
    signal  FIR2_START   :std_logic;
    signal  FIR2_BUSY   :std_logic;
	signal	SRC_POS		:std_logic_vector(6 downto 0);


    signal  DATA88_0,DATA44_0   :std_logic_vector(15 downto 0);
    signal  DATA88_1,DATA44_1   :std_logic_vector(15 downto 0);
    signal  DATA88_2,DATA44_2   :std_logic_vector(15 downto 0);
    signal  DATA88_3,DATA44_3   :std_logic_vector(15 downto 0);
    signal  DATA88_4,DATA44_4   :std_logic_vector(15 downto 0);
    signal  DATA88_5,DATA44_5   :std_logic_vector(15 downto 0);
    signal  DATA88_6,DATA44_6   :std_logic_vector(15 downto 0);
    signal  DATA88_7,DATA44_7   :std_logic_vector(15 downto 0);


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
    if reset_n='0' then                 SMPLCNT_88k <=  0;
    elsif clk'event and clk='1' then
        if clr_in = '1' then            SMPLCNT_88k <=  0;
        elsif FIR_REQ = RQ_END then
            if SMPLCNT_88k=65535 then    SMPLCNT_88k <=  0;
            else                        SMPLCNT_88k <=  SMPLCNT_88k+1;
            end if;
        else                            SMPLCNT_88k <=  SMPLCNT_88k;
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
        BUF88k_WR	<=	FIR0_VALID_OUT;
    end if;
    end process;
	
	BUF88k_WRDATA(15 downto 14)<="00";
	BUF88k_WRDATA(13 downto 0) <= CONV_STD_LOGIC_VECTOR(OFFSET_SUM,14);
 

    SMPLCNT_88k_VECT <=  CONV_STD_LOGIC_VECTOR(SMPLCNT_88k,16);
    FIR_CH_CNT_VECT <=  CONV_STD_LOGIC_VECTOR( FIR_CH_CNT,3);

    BUF88k_WRADDR   <=  FIR_CH_CNT_VECT &  SMPLCNT_88k_VECT(6 DOWNTO 0);


	--シミュレーション　デバッグ用　たぶん回路に落ちない
    process(clk) begin
    if clk'event and clk='1' then

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0000" then
            DATA88_0  <=  "00" & FIR0_DATA_OUT;
        else
            DATA88_0  <=  DATA88_0;
        end if;

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0001" then
            DATA88_1  <=  "00" & FIR0_DATA_OUT;
        else
            DATA88_1  <=  DATA88_1;
        end if;

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0010" then
            DATA88_2  <=  "00" & FIR0_DATA_OUT;
        else
            DATA88_2  <=  DATA88_2;
        end if;

        if FIR0_VALID_OUT='1' and FIR_CH_CNT_VECT="0011" then
            DATA88_3  <=  "00" & FIR0_DATA_OUT;
        else
            DATA88_3  <=  DATA88_3;
        end if;
    end if;
    end process;



    BUF88k: wave_buf port map(
		clock		=>  clk,
		data		=>  BUF88k_WRDATA,
		rdaddress	=>  BUF88k_RDADDR,
		wraddress	=>  BUF88k_WRADDR,
		wren		=>  BUF88k_WR,
		q		    =>  BUF88k_RDQ
	);


    process(clk,reset_n) begin
    if reset_n='0' then                 BUF88_RDY <=  "00";
    elsif clk'event and clk='1' then
        if clr_in = '1' then            BUF88_RDY <=  "00";
        else
            if SMPLCNT_88k >= 31 and  SMPLCNT_88k_VECT(0)='0' then
                 BUF88_RDY(0)<='1';
            else
                 BUF88_RDY(0)<='0';
            end if;
            BUF88_RDY(1) <= BUF88_RDY(0);
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
                    if BUF88_RDY = "01" then
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
    if reset_n='0' then                 SMPLCNT_44k <=  0;
    elsif clk'event and clk='1' then
        if clr_in = '1' then            SMPLCNT_44k <=  0;
        elsif FIR2_REQ = RQ_END then
            if SMPLCNT_44k=SMPLCNT_44K_MAX then
            						    SMPLCNT_44k <=  0;
            else                        SMPLCNT_44k <=  SMPLCNT_44k+1;
            end if;
        else                            SMPLCNT_44k <=  SMPLCNT_44k;
        end if;
    end if;
    end process;

    SMPLCNT_44k_VECT    <=  CONV_STD_LOGIC_VECTOR(SMPLCNT_44k,24);

    valid_sample	<=  SMPLCNT_44k_VECT;
	valid			<=	BUF44k_WR;
    valid_ch		<=	BUF44k_WRADDR(8 downto 6);
	valid_data		<=	BUF44k_WRDATA;

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


	SRC_POS	<=	SMPLCNT_44k_VECT(5 downto 0) & '0';


    FIR2: fir_16b31t port map(
        	clk         =>	clk,
            reset_n     =>  reset_n,

            start_in    =>  FIR2_START,
            busy_out    =>  FIR2_BUSY,
            ch_in       =>  FIR2_CH_CNT_VECT(2 downto 0),
 --           pos_in      =>  SMPLCNT_44k_VECT(6 downto 0),
           	pos_in      =>  SRC_POS,

            buf_ch      =>  BUF88k_RDADDR(9 downto 7),
            buf_pos     =>  BUF88k_RDADDR(6 downto 0),
            buf_datain  =>  BUF88k_RDQ(13 downto 0),

            ch_out      =>  BUF44k_WRADDR(8 downto 6),
            pos_out     =>  open,--BUF44k_WRADDR(6 downto 0),
            data_out    =>  FIR2_DATAOUT,
            write_out   =>  BUF44k_WR
        );


	BUF44k_WRDATA	<=	X"8001"	when FIR2_DATAOUT = X"8000"
	else				X"7FFE"	when FIR2_DATAOUT = X"7FFF"
	else				FIR2_DATAOUT;

	BUF44k_WRADDR(5 downto 0)	<=	SMPLCNT_44k_VECT(5 downto 0);

	--シミュレーション　デバッグ用　たぶん回路に落ちない
    process(clk) begin
    if clk'event and clk='1' then

        if BUF44k_WR='1' and BUF44k_WRADDR(8 downto 6)="000" then
            DATA44_0  <=  BUF44k_WRDATA;
        else
            DATA44_0  <=  DATA44_0;
        end if;

        if BUF44k_WR='1' and BUF44k_WRADDR(8 downto 6)="001" then
            DATA44_1  <=  BUF44k_WRDATA;
        else
            DATA44_1  <=  DATA44_1;
        end if;

        if BUF44k_WR='1' and BUF44k_WRADDR(8 downto 6)="010" then
            DATA44_2  <=  BUF44k_WRDATA;
        else
            DATA44_2  <=  DATA44_2;
        end if;

        if BUF44k_WR='1' and BUF44k_WRADDR(8 downto 6)="011" then
            DATA44_3  <=  BUF44k_WRDATA;
        else
            DATA44_3  <=  DATA44_3;
        end if;

    end if;
    end process;



    BUF44k: wave_buf_16_32 port map(
		clock		=>  clk,
		data		=>  BUF44k_WRDATA,
		rdaddress	=>  BUF44k_RDADDR,
		wraddress	=>  BUF44k_WRADDR(8 downto 0),
		wren		=>  BUF44k_WR,
		q		    =>  BUF44k_RDQ
	);

	data_out		<=	BUF44k_RDQ;
    BUF44k_RDADDR	<=	ch_in & addr_in;



end RTL;