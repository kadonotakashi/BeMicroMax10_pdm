--
--	PDM MIC interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pdm_mod is
Port (	clk		    : in std_logic;
        reset_n         : in std_logic;

		addr	        :in std_logic_vector(11 downto 2);
        ben	        	:in std_logic_vector(3 downto 0);
        sel		        :in std_logic;
        rd		        :in std_logic;
        wr		        :in std_logic;
        wrdata	        :in std_logic_vector(31 downto 0);
        rddata	        :out std_logic_vector(31 downto 0);

		maddr			: out	std_logic_vector(31 downto 0);
		mben			: out	std_logic_vector(3 downto 0);
		mwr				: out	std_logic;
		mwrdata			: out	std_logic_vector(31 downto 0);
		mwaitrequest	: in	std_logic;
		mburstcount		: out	std_logic_vector(7 downto 0);

		pdmclk_in     	:in  std_logic;
		pdmdata_in     	:in  std_logic_vector(3 downto 0);
		
		monitor_out		:out std_logic

	);
	end pdm_mod;

architecture RTL of pdm_mod is



	component pdm_cpuif is
	Port (	clk		    : in std_logic;
        reset_n         : in std_logic;

        addr	        :in std_logic_vector(11 downto 2);
        ben	        	:in std_logic_vector(3 downto 0);
        sel		        :in std_logic;
        rd		        :in std_logic;
        wr		        :in std_logic;
        wrdata	        :in std_logic_vector(31 downto 0);
        rddata	        :out std_logic_vector(31 downto 0);

		clr_out     	:out  std_logic;
		smpl_cnt		:in std_logic_vector(23 downto 0);

		offset0			:out std_logic_vector(13 downto 0);
		offset1			:out std_logic_vector(13 downto 0);
		offset2			:out std_logic_vector(13 downto 0);
		offset3			:out std_logic_vector(13 downto 0);
		offset4			:out std_logic_vector(13 downto 0);
		offset5			:out std_logic_vector(13 downto 0);
		offset6			:out std_logic_vector(13 downto 0);
		offset7			:out std_logic_vector(13 downto 0);
        ch_out		   :out std_logic_vector(2 downto 0);
        gain_out	   :out std_logic_vector(3 downto 0);
 
 		mode_freq_out	:out std_logic;

        bufaddr_out    :out std_logic_vector(4 downto 0);
        bufdata_in     :in std_logic_vector(31 downto 0)

	);
	end component;

	signal	CPU_CLR		:std_logic;
	signal	CPU_CH		:std_logic_vector(2 downto 0);
	signal	CPU_GAIN	:std_logic_vector(3 downto 0);
	signal	CPU_BUFADDR	:std_logic_vector(4 downto 0);

	signal	CPU_MODE_FREQ		:std_logic;

	signal	CPU_OFFSETreg0		:std_logic_vector(13 downto 0);
	signal	CPU_OFFSETreg1		:std_logic_vector(13 downto 0);
	signal	CPU_OFFSETreg2		:std_logic_vector(13 downto 0);
	signal	CPU_OFFSETreg3		:std_logic_vector(13 downto 0);
	signal	CPU_OFFSETreg4		:std_logic_vector(13 downto 0);
	signal	CPU_OFFSETreg5		:std_logic_vector(13 downto 0);
	signal	CPU_OFFSETreg6		:std_logic_vector(13 downto 0);
	signal	CPU_OFFSETreg7		:std_logic_vector(13 downto 0);


 	component pdm_core2 is
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
        offset7			:in std_logic_vector(13 downto 0);
        
        gain_in			:in std_logic_vector(3 downto 0);
        mode_freq		:in std_logic

	);
	end component;

	signal	CORE_DATAOUT	:std_logic_vector(31 downto 0);
	signal	SMPLCNT_32K	:std_logic_vector(23 downto 0);	
	signal	PDM32_RD_ADDR	:std_logic_vector(6 downto 0);
	signal	PDM32_RD_ADDR_DLY	:std_logic_vector(6 downto 0);
	signal	PDMCLK_DLY	:std_logic_vector(3 downto 0);
	signal	PDM_DIVCNT	:integer range 0 to 63;
	signal	PDM_32KCLK	:std_logic;

	signal	CORE_VALID		:std_logic;
    signal	CORE_VALID_CH	:std_logic_vector(2 downto 0);
    signal	CORE_VALID_SMPL	:std_logic_vector(23 downto 0);
    signal	CORE_VALID_DATA	:std_logic_vector(15 downto 0);

	signal	CORE_CH_IN		:std_logic_vector(2 downto 0);
	signal	CORE_ADDR_IN	:std_logic_vector(4 downto 0);

	signal	WAVE_32k		:std_logic_vector(15 downto 0);


	component sd1bitDA16
	Port (	clk			: in std_logic;
			reset_n		: in std_logic;		
			clr_in		: in std_logic;

			data_in		:in std_logic_vector(15 downto 0);
			pulse_out	:out std_logic
	);
	end component;


	component pdm_amseq
	Port (	
		reset_n			:in std_logic;
		clk				: in  STD_LOGIC;
		clr_in			: in std_logic;

		bufwr_in		:in std_logic;
		smplcnt_in		:in std_logic_vector(17 downto 0);
		ch_in			:in std_logic_vector(2 downto 0);

		amw_disable_out	: out std_logic;
		amw_start_out	: out std_logic;
		amw_end_in		: in std_logic;

		amw_addr		:out std_logic_vector(31 downto 0);
		amw_length		:out std_logic_vector(12 downto 0);
		

		buf_addr		:out std_logic_vector(7 downto 4)
	);
	end component;

	signal	AMSEQ_BUFADDR	: std_logic_vector(7 downto 4);
	signal	AMSEQ_START		: std_logic;
	signal	AMSEQ_END		: std_logic;
	signal	AMSEQ_ADDR		: std_logic_vector(31 downto 0);
	signal	AMSEQ_LENGTH	: std_logic_vector(12 downto 0);

	signal	AMSEQ_DISABLE		: std_logic;


	component avalon_master_write_mod
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
	end component;

	signal	AVM_BUF_ADDR	:std_logic_vector(9 downto 0);
	signal	AVM_BUSY		:std_logic;

begin

	CPUIF: pdm_cpuif port map(
		clk		    =>	clk		  ,
        reset_n     =>	reset_n   ,
	
			addr	=>	addr,
			ben		=>	ben	,
			sel		=>	sel	,
			rd		=>	rd	,
			wr		=>	wr	,
			wrdata	=>	wrdata,
			rddata	=>	rddata,
	                    
			clr_out	=>	CPU_CLR,
			smpl_cnt	=>	CORE_VALID_SMPL,

			offset0	=>	CPU_OFFSETreg0,
			offset1	=>	CPU_OFFSETreg1,
			offset2	=>	CPU_OFFSETreg2,
			offset3	=>	CPU_OFFSETreg3,
			offset4	=>	CPU_OFFSETreg4,
			offset5	=>	CPU_OFFSETreg5,
			offset6	=>	CPU_OFFSETreg6,
			offset7	=>	CPU_OFFSETreg7,
			ch_out		=>	CPU_CH,

	        gain_out	=>	CPU_GAIN,

	 		mode_freq_out	=>	CPU_MODE_FREQ,

			bufaddr_out	=>	CPU_BUFADDR,
			bufdata_in  =>	CORE_DATAOUT
	
		);


 	core: pdm_core2 port map(
		clk		    =>	clk		  ,
        reset_n     =>	reset_n   ,
        clr_in      =>	CPU_CLR    ,
		pdmclk_in   =>	pdmclk_in ,
		pdmdata_in  =>	pdmdata_in,

		valid			=>	CORE_VALID,
        valid_ch    	=>	CORE_VALID_CH,
        valid_sample	=>	CORE_VALID_SMPL,
		valid_data		=>	CORE_VALID_DATA,

        ch_in		=>	CORE_CH_IN	,
        addr_in     =>	CORE_ADDR_IN,
        data_out    =>	CORE_DATAOUT  ,

        offset0		=>	CPU_OFFSETreg0,
        offset1		=>	CPU_OFFSETreg1,
        offset2		=>	CPU_OFFSETreg2,
        offset3		=>	CPU_OFFSETreg3,
        offset4		=>	CPU_OFFSETreg4,
        offset5		=>	CPU_OFFSETreg5,
        offset6		=>	CPU_OFFSETreg6,
        offset7		=>	CPU_OFFSETreg7,
        
        gain_in		=>	CPU_GAIN,
        mode_freq	=>	CPU_MODE_FREQ

	);                  

	CORE_CH_IN		<=	AMSEQ_BUFADDR(7 downto 5)	when AVM_BUSY='1'
	else				CPU_CH;
	CORE_ADDR_IN	<=	AMSEQ_BUFADDR(4) & AVM_BUF_ADDR(3 downto 0)	when AVM_BUSY='1'
	else				CPU_BUFADDR;

	process(clk) begin
	if clk'event and clk='1' then
		if CORE_VALID = '1' and CPU_CH = CORE_VALID_CH	then
			WAVE_32k	<=	CORE_VALID_DATA;
		else
			WAVE_32k	<=	WAVE_32k;
		end if;
	end if;
	end process;


	MONITOR_DA: sd1bitDA16 port map(
		clk		=>	clk,
		reset_n	=>	reset_n,
		clr_in	=>	CPU_CLR ,

		data_in	=>	not WAVE_32k(15) & WAVE_32k(14 downto 0),
		pulse_out	=>	monitor_out
	);




	AMSEQ: pdm_amseq port map(
        reset_n     =>	reset_n   ,
		clk		    =>	clk		  ,
        clr_in      =>	CPU_CLR    ,

		bufwr_in	=>	CORE_VALID,
		smplcnt_in	=>	CORE_VALID_SMPL(17 downto 0),
		ch_in		=>	CORE_VALID_CH,

		amw_disable_out	=>	AMSEQ_DISABLE,
		amw_start_out	=>	AMSEQ_START,
		amw_end_in		=>	AMSEQ_END,
		amw_addr		=>	AMSEQ_ADDR,
		amw_length		=>	AMSEQ_LENGTH,

		buf_addr		=>	AMSEQ_BUFADDR
	);



	AVM: avalon_master_write_mod port map(
        reset_n     =>	reset_n   ,
		clk		    =>	clk		  ,
        clr_in      =>	AMSEQ_DISABLE   ,

	--parameter,Control sig.
		addr_in		=>	AMSEQ_ADDR,
		length_in	=>	AMSEQ_LENGTH,
		burst_in	=>	"1000",
		start_in	=>	AMSEQ_START,
		end_out		=>	AMSEQ_END,
		busy_out	=>	AVM_BUSY,
		
	--バッファの接続(Latency=1)
		buf_addr	=>	AVM_BUF_ADDR,
		buf_data	=>	CORE_DATAOUT,

	--avalon masterとしてデータ転送
		maddr			=>	maddr			,
		mben			=>	mben			,
		mwr				=>	mwr				,
		mwrdata			=>	mwrdata			,
		mwaitrequest	=>	mwaitrequest	,
		mburstcount		=>	mburstcount		
	);


end RTL;