--
--	PDM MIC interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pdm_if is
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
	end pdm_if;

architecture RTL of pdm_if is

    signal  PDMCLK_DLY     :std_logic_vector(3 downto 0);
    signal  PDMDATA_DLY01     :std_logic_vector(3 downto 0);
    signal  PDMDATA_DLY23     :std_logic_vector(3 downto 0);
    signal  PDMDATA_DLY45     :std_logic_vector(3 downto 0);
    signal  PDMDATA_DLY67     :std_logic_vector(3 downto 0);

    signal  PDMDATA_SR0      :std_logic_vector(7 downto 0);
    signal  PDMDATA_SR1      :std_logic_vector(7 downto 0);
    signal  PDMDATA_SR2      :std_logic_vector(7 downto 0);
    signal  PDMDATA_SR3      :std_logic_vector(7 downto 0);
    signal  PDMDATA_SR4      :std_logic_vector(7 downto 0);
    signal  PDMDATA_SR5      :std_logic_vector(7 downto 0);
    signal  PDMDATA_SR6      :std_logic_vector(7 downto 0);
    signal  PDMDATA_SR7      :std_logic_vector(7 downto 0);

    signal  PDMCLK_RISE,PDMCLK_FALL	:std_logic;


	type PDMBITSTS_TYPE is(
		BS_WAIT,
		BS_0,
		BS_1,
		BS_2,
		BS_3,
		BS_4,
		BS_5,
		BS_6,
		BS_7
	);
	signal	PDMBIT_STS	:PDMBITSTS_TYPE;

	type PDMBYTESTS_TYPE is(
		B8S_IDLE,
		B8S_0,
		B8S_1,
		B8S_2,
		B8S_3,
		B8S_4,
		B8S_5,
		B8S_6,
		B8S_7,
		B8S_WAIT
	);
	signal	PDMBYTE_STS	:PDMBYTESTS_TYPE;
	signal	PDM_BYTE_CNT		 :integer range 0 to 31;
    constant    C_PDMBUF_DATA_CH  :integer :=32;

    component pdmdatabuf
	PORT
	(
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
    end component;

	signal	PDMBUF_DATA		: STD_LOGIC_VECTOR (7 DOWNTO 0);
	signal	PDMBUF_RDADDR	: STD_LOGIC_VECTOR (7 DOWNTO 0);
	signal	PDMBUF_WRADDR	: STD_LOGIC_VECTOR (7 DOWNTO 0);
	signal	PDMBUF_WR		: STD_LOGIC;
	signal	PDMBUF_Q		: STD_LOGIC_VECTOR (7 DOWNTO 0);

    signal  BUFFER_FILL       :std_logic;


begin

	--PDM CLK��system clock�̓���

    process(clk) begin
    if clk'event and clk='1' then
        PDMCLK_DLY  	<=  PDMCLK_DLY(2 downto 0) &   pdmclk_in;
        PDMDATA_DLY01	<=	PDMDATA_DLY01(2 downto 0)  & pdmdata_in(0);
        PDMDATA_DLY23   <=	PDMDATA_DLY23(2 downto 0)  & pdmdata_in(1);
        PDMDATA_DLY45   <=	PDMDATA_DLY45(2 downto 0)  & pdmdata_in(2);
        PDMDATA_DLY67	<=	PDMDATA_DLY67(2 downto 0)  & pdmdata_in(3);
    end if;
    end process;



    PDMCLK_RISE <=  '1' when PDMCLK_DLY(3 downto 2) = "01"  else '0';
    PDMCLK_FALL <=  '1' when PDMCLK_DLY(3 downto 2) = "10"  else '0';

    process(clk) begin
    if clk'event and clk='1' then
        if PDMCLK_RISE='1' then  --lutch rising edge of pdmclk
            PDMDATA_SR0 <=  PDMDATA_DLY01(3) & PDMDATA_SR0(7 downto 1);
            PDMDATA_SR2 <=  PDMDATA_DLY23(3) & PDMDATA_SR2(7 downto 1);
            PDMDATA_SR4 <=  PDMDATA_DLY45(3) & PDMDATA_SR4(7 downto 1);
            PDMDATA_SR6 <=  PDMDATA_DLY67(3) & PDMDATA_SR6(7 downto 1);
        else --lutch falling edge of pdmclk
            PDMDATA_SR0 <= PDMDATA_SR0;
            PDMDATA_SR2 <= PDMDATA_SR2;
            PDMDATA_SR4 <= PDMDATA_SR4;
            PDMDATA_SR6 <= PDMDATA_SR6;
        end if;

        if PDMCLK_FALL='1' then  --lutch rising edge of pdmclk
            PDMDATA_SR1 <= PDMDATA_DLY01(3) & PDMDATA_SR1(7 downto 1);
            PDMDATA_SR3 <= PDMDATA_DLY23(3) & PDMDATA_SR3(7 downto 1);
            PDMDATA_SR5 <= PDMDATA_DLY45(3) & PDMDATA_SR5(7 downto 1);
            PDMDATA_SR7 <= PDMDATA_DLY67(3) & PDMDATA_SR7(7 downto 1);
        else --lutch falling edge of pdmclk
            PDMDATA_SR1 <= PDMDATA_SR1;
            PDMDATA_SR3 <= PDMDATA_SR3;
            PDMDATA_SR5 <= PDMDATA_SR5;
            PDMDATA_SR7 <= PDMDATA_SR7;
        end if;
    end if;
    end process;


    process(clk,reset_n) begin
	if reset_n='0' then 			PDMBIT_STS	<=	BS_WAIT;
    elsif clk'event and clk='1' then
		if clr_in = '1' then		PDMBIT_STS	<=	BS_WAIT;
        elsif PDMCLK_RISE='1' then
			case PDMBIT_STS is
				when BS_WAIT	=>	PDMBIT_STS <= BS_0  ;
				when BS_0		=>	PDMBIT_STS <= BS_1	;
				when BS_1		=>	PDMBIT_STS <= BS_2	;
				when BS_2		=>	PDMBIT_STS <= BS_3	;
				when BS_3		=>	PDMBIT_STS <= BS_4	;
				when BS_4		=>	PDMBIT_STS <= BS_5	;
				when BS_5		=>	PDMBIT_STS <= BS_6	;
				when BS_6		=>	PDMBIT_STS <= BS_7	;
				when BS_7		=>	PDMBIT_STS <= BS_0	;
				when others		=>	PDMBIT_STS <= BS_0	;
			end case;
        else				        PDMBIT_STS	<=	PDMBIT_STS;
        end if;
    end if;
    end process;

    process(clk,reset_n) begin
	if reset_n='0' then 			PDMBYTE_STS	<=	B8S_IDLE;
    elsif clk'event and clk='1' then
		if clr_in = '1' then		PDMBYTE_STS	<=	B8S_IDLE;
        else
			case PDMBYTE_STS is
				when B8S_IDLE	=>	
                    if PDMBIT_STS = BS_7 then PDMBYTE_STS <= B8S_0	;
                    else                      PDMBYTE_STS <= PDMBYTE_STS;
                    end if;
				when B8S_0	    =>	PDMBYTE_STS <= B8S_1	;
				when B8S_1	    =>	PDMBYTE_STS <= B8S_2	;
				when B8S_2	    =>	PDMBYTE_STS <= B8S_3	;
				when B8S_3	    =>	PDMBYTE_STS <= B8S_4	;
				when B8S_4	    =>	PDMBYTE_STS <= B8S_5	;
				when B8S_5	    =>	PDMBYTE_STS <= B8S_6	;
				when B8S_6	    =>	PDMBYTE_STS <= B8S_7	;
				when B8S_7	    =>	PDMBYTE_STS <= B8S_WAIT	;
				when B8S_WAIT	=>
                    if PDMBIT_STS /= BS_7 then PDMBYTE_STS <= B8S_IDLE	;
                    else                      PDMBYTE_STS <= PDMBYTE_STS;
                    end if;
				when others		=>	PDMBYTE_STS <= B8S_IDLE	;
			end case;
        end if;
    end if;
    end process;

    process(clk,reset_n) begin
	if reset_n='0' then 			                    PDM_BYTE_CNT <=	0;
    elsif clk'event and clk='1' then
		if clr_in = '1' then		                    PDM_BYTE_CNT <=	0;
        elsif PDMBYTE_STS = B8S_7	then
            if PDM_BYTE_CNT = (C_PDMBUF_DATA_CH-1) then PDM_BYTE_CNT <=	0;
            else                                        PDM_BYTE_CNT <=	PDM_BYTE_CNT +1;
            end if;
        else                                            PDM_BYTE_CNT <=	PDM_BYTE_CNT ;
        end if;
    end if;
    end process;



    process(clk,reset_n) begin
	if reset_n='0' then 			                    BUFFER_FILL <=	'0';
    elsif clk'event and clk='1' then
		if clr_in = '1' then		                    BUFFER_FILL <=	'0';
        elsif PDM_BYTE_CNT = (C_PDMBUF_DATA_CH/2) then  BUFFER_FILL <=	'1';
        else                                            BUFFER_FILL <=	BUFFER_FILL;
        end if;
    end if;
    end process;

    buf_ready   <=  BUFFER_FILL;
    cnt_out <= CONV_STD_LOGIC_VECTOR(PDM_BYTE_CNT,5);

    PDMBUF_DATA <=  PDMDATA_SR0 when PDMBYTE_STS = B8S_0
    else            PDMDATA_SR1 when PDMBYTE_STS = B8S_1    
    else            PDMDATA_SR2 when PDMBYTE_STS = B8S_2    
    else            PDMDATA_SR3 when PDMBYTE_STS = B8S_3    
    else            PDMDATA_SR4 when PDMBYTE_STS = B8S_4    
    else            PDMDATA_SR5 when PDMBYTE_STS = B8S_5    
    else            PDMDATA_SR6 when PDMBYTE_STS = B8S_6    
    else            PDMDATA_SR7 when PDMBYTE_STS = B8S_7    
    else            (others=>'0');

    PDMBUF_WRADDR(7 downto 5) <=    "000" when PDMBYTE_STS = B8S_0
    else                            "001" when PDMBYTE_STS = B8S_1    
    else                            "010" when PDMBYTE_STS = B8S_2    
    else                            "011" when PDMBYTE_STS = B8S_3    
    else                            "100" when PDMBYTE_STS = B8S_4    
    else                            "101" when PDMBYTE_STS = B8S_5    
    else                            "110" when PDMBYTE_STS = B8S_6    
    else                            "111" when PDMBYTE_STS = B8S_7    
    else            (others=>'0');

    PDMBUF_WRADDR(4 downto 0) <=CONV_STD_LOGIC_VECTOR(PDM_BYTE_CNT,5);
    PDMBUF_WR   <=  '1' when ((PDMBYTE_STS /= B8S_IDLE) and (PDMBYTE_STS /= B8S_WAIT))  else    '0';

    PDMBUF:pdmdatabuf port map(
		clock       =>  clk,
		data		=>  PDMBUF_DATA,
		rdaddress   =>  PDMBUF_RDADDR,
		wraddress   =>  PDMBUF_WRADDR,
		wren        =>  PDMBUF_WR,
		q           =>  PDMBUF_Q		    
	);

    PDMBUF_RDADDR   <=  ch & position;
    data_out    <=  PDMBUF_Q;

end RTL;