library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity	BeMicroMax10 is
port(
	clk50MHz	:in std_logic;

	BUTTON		:in std_logic_vector(4 downto 1);
	LED			:out std_logic_vector(8 downto 1);

	sd_CLK		:out std_logic;
	sd_CKE		:out std_logic;
	sd_A		:out std_logic_vector(12 downto 0);
	sd_BA		:out std_logic_vector(1 downto 0);
	sd_DQ		:inout std_logic_vector(15 downto 0);
	sd_DQM		:out std_logic_vector(1 downto 0);
	sd_RASn		:out std_logic;
	sd_CASn		:out std_logic;
	sd_WEn		:out std_logic;
	sd_CSn		:out std_logic;

	sfl_ASDI	:out std_logic;
	sfl_CSn		:out std_logic;
	sfl_DATA	:in std_logic;
	sfl_DCLK	:out std_logic;
	
	analog_in	:in std_logic_vector(7 downto 0);

	--TEMPERATURE sensor
	ADT7420_SDA	:inout std_logic; 
	ADT7420_SCL	:out std_logic; 
	ADT7420_CT	:in std_logic; 
	ADT7420_INT	:in std_logic; 


	--D/A converter
	AD5681_RSTn		:out std_logic;
	AD5681_LDACn	:out std_logic;
	AD5681_SCL		:out std_logic;
	AD5681_SDA		:out std_logic;
	AD5681_SYNCn	:out std_logic;

	--Accelerometer
	ADXL362_CS		:out std_logic;
	ADXL362_INT1	:in std_logic;
	ADXL362_INT2	:in std_logic;
	ADXL362_MISO	:in std_logic;
	ADXL362_MOSI	:out std_logic;
	ADXL362_SCLK	:out std_logic;

	EG_CON		:inout std_logic_vector(60 downto 1);

	PMOD_A		:inout std_logic_vector(4 downto 1);
	PMOD_B		:inout std_logic_vector(4 downto 1);
	PMOD_C		:inout std_logic_vector(4 downto 1);
	PMOD_D		:inout std_logic_vector(4 downto 1);

	J4_I2C_SDA	:inout std_logic;
	J4_I2C_SCL	:inout std_logic;
	J4_GPIOA	:inout std_logic;
	J4_GPIOB	:inout std_logic;
	J4_LVDS_TXP	:inout std_logic_vector(11 downto 0);
	J4_LVDS_TXN	:inout std_logic_vector(11 downto 0);

--	J3_GPIO		:inout std_logic_vector(12 downto 1);
--	J3_LVDS_RXP	:inout std_logic_vector(11 downto 0);
--	J3_LVDS_RXN	:inout std_logic_vector(11 downto 0)

	gpio		:inout std_logic_vector(35 downto 0)


);
end	BeMicroMax10;

architecture RTL of BeMicroMax10 is
	component nios
	port (
		reset_reset_n : in    std_logic                     := '0';             --  reset.reset_n

		clk_clk       : in    std_logic                     := '0';             --    clk.clk
		sys_clk       : out   std_logic;                                         --    sys.clk
		pdm_clk       : out   std_logic;                                        -- clk
		log_clk           : out   std_logic;                                        -- clk

		button_export : in    std_logic_vector(3 downto 0)  := (others => '0'); -- button.export
		led_export    : out   std_logic_vector(7 downto 0);                     --    led.export

		sd_clk        : out   std_logic;                                        --     sd.clk
		sdram_addr    : out   std_logic_vector(11 downto 0);                    --  sdram.addr
		sdram_ba      : out   std_logic_vector(1 downto 0);                     --       .ba
		sdram_cas_n   : out   std_logic;                                        --       .cas_n
		sdram_cke     : out   std_logic;                                        --       .cke
		sdram_cs_n    : out   std_logic;                                        --       .cs_n
		sdram_dq      : inout std_logic_vector(15 downto 0) := (others => '0'); --       .dq
		sdram_dqm     : out   std_logic_vector(1 downto 0);                     --       .dqm
		sdram_ras_n   : out   std_logic;                                        --       .ras_n
		sdram_we_n    : out   std_logic;                                        --       .we_n

		sflash_dclk   : out   std_logic;                                        -- sflash.dclk
		sflash_sce    : out   std_logic;                                        --       .sce
		sflash_sdo    : out   std_logic;                                        --       .sdo
		sflash_data0  : in    std_logic                     := '0';             --       .data0


		ftdi_rdn       : out   std_logic;                                        -- rdn
		ftdi_resetn    : out   std_logic;                                        -- resetn
		ftdi_rxdata    : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- rxdata
		ftdi_rxfn      : in    std_logic                     := 'X';             -- rxfn
		ftdi_txdata    : out   std_logic_vector(7 downto 0);                     -- txdata
		ftdi_txdata_oe : out   std_logic;                                        -- txdata_oe
		ftdi_txen      : in    std_logic                     := 'X';             -- txen
		ftdi_wr        : out   std_logic;                                        -- wr

		lcd_cs          : out   std_logic;                                        -- cs
		lcd_dc          : out   std_logic;                                        -- dc
		lcd_rstn        : out   std_logic;                                        -- rstn
		lcd_sclk        : out   std_logic;                                        -- sclk
		lcd_sdata       : out   std_logic;                                         -- sdata

		as_pdm_address     : out   std_logic_vector(9 downto 0);                     -- address
		as_pdm_read        : out   std_logic;                                        -- read
		as_pdm_readdata    : in    std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
		as_pdm_write       : out   std_logic;                                        -- write
		as_pdm_writedata   : out   std_logic_vector(31 downto 0);                    -- writedata
		as_pdm_byteenable  : out   std_logic_vector(3 downto 0);                     -- byteenable
		as_pdm_chipselect  : out   std_logic;                                        -- chipselect

		amwr_address      : in    std_logic_vector(31 downto 0) := (others => 'X'); -- address
		amwr_byteenable   : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
		amwr_write        : in    std_logic                     := 'X';             -- write
		amwr_writedata    : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
		amwr_waitrequest  : out   std_logic;                                        -- waitrequest
		amwr_burstcount   : in    std_logic_vector(7 downto 0)  := (others => 'X');  -- burstcount

		deb_export     : out   std_logic_vector(7 downto 0)                      -- export
		

	);
	end component;
	
	signal	SYS_RESETn		:std_logic;
	signal	SYS_CLK			:std_logic;
	signal	PDM_CLK		:std_logic;
	signal	CLK_LOG		:std_logic;
	signal	PDM2_CLK	:std_logic;

	signal	TMP_SDA_O,TMP_SDA_I,TMP_SCL		:std_logic;

	signal	ftdi_rdn       : std_logic;                                        -- rdn
	signal	ftdi_resetn    : std_logic;                                        -- resetn
	signal	ftdi_rxdata    : std_logic_vector(7 downto 0)  := (others => 'X'); -- rxdata
	signal	ftdi_rxfn      : std_logic                     := 'X';             -- rxfn
	signal	ftdi_txdata    : std_logic_vector(7 downto 0);                     -- txdata
	signal	ftdi_txdata_oe : std_logic;                                        -- txdata_oe
	signal	ftdi_txen      : std_logic                     := 'X';             -- txen
	signal	ftdi_wr        : std_logic;                                        -- wr

	signal	lcd_cs          : std_logic;                                        -- cs
	signal	lcd_dc          : std_logic;                                        -- dc
	signal	lcd_rstn        : std_logic;                                        -- rstn
	signal	lcd_sclk        : std_logic;                                        -- sclk
	signal	lcd_sdata       : std_logic;                                         -- sdata

	signal	pdm_address     : std_logic_vector(9 downto 0);                     -- address
	signal	pdm_read        : std_logic;                                        -- read
	signal	pdm_readdata    : std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
	signal	pdm_write       : std_logic;                                        -- write
	signal	pdm_writedata   : std_logic_vector(31 downto 0);                    -- writedata
	signal	pdm_byteenable  : std_logic_vector(3 downto 0);                     -- byteenable
	signal	pdm_chipselect  : std_logic;                                        -- chipselect

	signal	amwr_address      : std_logic_vector(31 downto 0) := (others => 'X'); -- address
	signal	amwr_byteenable   : std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
	signal	amwr_write        : std_logic                     := 'X';             -- write
	signal	amwr_writedata    : std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
	signal	amwr_waitrequest  : std_logic;                                        -- waitrequest
	signal	amwr_burstcount   : std_logic_vector(7 downto 0)  := (others => 'X');  -- burstcount

 	component pdm_mod is
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
	end component;
	
	signal	MONITOR_PDM	:std_logic;
	signal	PDMDATA		:std_logic_vector(3 downto 0);

	signal	NULL_VECT32	:std_logic_vector(31 downto 0);
begin
	NULL_VECT32	<=	(others=>'0');

	SYS_RESETn	<=	'1';


	U0:nios port map(
		button_export	=>	BUTTON,
		clk_clk			=>	clk50MHz,
		pdm_clk         =>	PDM_CLK,
		log_clk			=>	CLK_LOG,
		led_export		=>	LED,
		reset_reset_n	=>	SYS_RESETn,
		sd_clk			=>	sd_CLK,
		sdram_addr		=>	sd_A(11 downto 0),
		sdram_ba		=>	sd_BA,
		sdram_cas_n		=>	sd_CASn,
		sdram_cke		=>	sd_CKE,
		sdram_cs_n		=>	sd_CSn,
		sdram_dq		=>	sd_DQ,
		sdram_dqm		=>	sd_DQM,
		sdram_ras_n		=>	sd_RASn,
		sdram_we_n		=>	sd_WEn,
		sflash_dclk		=>	sfl_DCLK,
		sflash_sce		=>	sfl_CSn,
		sflash_sdo		=>	sfl_ASDI,
		sflash_data0	=>	sfl_DATA,
		sys_clk			=>	SYS_CLK,

		ftdi_rdn		=>	ftdi_rdn		,
		ftdi_resetn		=>	ftdi_resetn		,
		ftdi_rxdata		=>	ftdi_rxdata		,
		ftdi_rxfn		=>	ftdi_rxfn		,
		ftdi_txdata		=>	ftdi_txdata		,
		ftdi_txdata_oe	=>	ftdi_txdata_oe	,
		ftdi_txen		=>	ftdi_txen		,
		ftdi_wr			=>	ftdi_wr		,

		lcd_cs   	=>	lcd_cs   ,
		lcd_dc   	=>	lcd_dc   ,
		lcd_rstn 	=>	lcd_rstn ,
		lcd_sclk 	=>	lcd_sclk ,
		lcd_sdata	=>	lcd_sdata,

		as_pdm_address     =>	pdm_address     ,
		as_pdm_read        =>	pdm_read        ,
		as_pdm_readdata    =>	pdm_readdata    ,
		as_pdm_write       =>	pdm_write       ,
		as_pdm_writedata   =>	pdm_writedata   ,
		as_pdm_byteenable  =>	pdm_byteenable  ,
		as_pdm_chipselect  =>	pdm_chipselect  ,

		amwr_address      	=>	amwr_address    ,
		amwr_byteenable   	=>	amwr_byteenable ,
		amwr_write        	=>	amwr_write      ,
		amwr_writedata    	=>	amwr_writedata  ,
		amwr_waitrequest  	=>	amwr_waitrequest,
		amwr_burstcount   	=>	amwr_burstcount ,
		
		deb_export		=>	open
	);

	--FTDI USB<->PARALLEL
	ftdi_rxdata			<=	gpio(11 downto 4);
	gpio(11 downto 4)	<=	ftdi_txdata	when ftdi_txdata_oe='1'	else	(others=>'Z');
	gpio(2)				<=	ftdi_rdn	;
	gpio(3)				<=	ftdi_wr		;


J4_GPIOA	<=	ftdi_wr;
J4_GPIOB	<=	ftdi_txen;


	ftdi_rxfn	<=	gpio(0);
	ftdi_txen	<=	gpio(1);


	--LCD
	gpio(12)	<=	lcd_cs   ;
	gpio(13)	<=	lcd_rstn ;
	gpio(14)	<=	lcd_dc   ;
	gpio(15)	<=	lcd_sdata;
	gpio(16)	<=	lcd_sclk ;


	process(PDM_CLK) begin
	if PDM_CLK'event and PDM_CLK='1' then
		PDM2_CLK	<=	not PDM2_CLK;
	end if;
	end process;

	PMOD_C(2)	<=	CLK_LOG	;



	--PDM
	gpio(35) 	<= PDM_CLK;
	PDMDATA		<=	PDM_CLK & PDM2_CLK & gpio(34 downto 33);


 	PDM: pdm_mod port map(
		clk			=>	SYS_CLK,
        reset_n		=>	SYS_RESETn,

        addr		=>	pdm_address,
        ben	    	=>	pdm_byteenable,
        sel			=>	pdm_chipselect,
        rd			=>	pdm_read,
        wr			=>	pdm_write,
        wrdata		=>	pdm_writedata,
        rddata		=>	pdm_readdata,

		maddr			=>	amwr_address,
		mben			=>	amwr_byteenable,
		mwr				=>	amwr_write,
		mwrdata			=>	amwr_writedata,
		mwaitrequest	=>	amwr_waitrequest,
		mburstcount		=>	amwr_burstcount,

		pdmclk_in	=>	PDM_CLK,
		pdmdata_in	=>	PDMDATA,

		monitor_out	=>	PMOD_C(1)

	);


end RTL;

