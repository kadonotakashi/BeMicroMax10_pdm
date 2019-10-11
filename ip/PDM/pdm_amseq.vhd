

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity	pdm_amseq is
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
end pdm_amseq;

architecture rtl of pdm_amseq is

	type	MasterWrite_STS_TYPE is(
		MW_IDLE,

		MW_FH_WAIT,	
		MW_FH_START,
		MW_FH_WAIT_END,	
		MW_FH_END,	

		MW_SH_WAIT,	
		MW_SH_START,
		MW_SH_WAIT_END,	
		MW_SH_END
	);
	signal	MWSTS:MasterWrite_STS_TYPE;

	signal	START_FH	:std_logic;
	signal	START_SH	:std_logic;

	signal	CH_CNT		:integer range 0 to 7;
	signal	SMPLCNT_REG	:std_logic_vector(17 downto 0);
	signal	SMPLCNTDLY_REG	:std_logic_vector(17 downto 0);


begin

	START_FH	<=	bufwr_in	when ((smplcnt_in(5 downto 0) = "100000") and (ch_in="111"))	else '0';	-- timing of first harf filled
	START_SH	<=	bufwr_in	when ((smplcnt_in(5 downto 0) = "000000") and (ch_in="111"))	else '0';	-- timing of second harf filled



	process(clk,reset_n) begin
	if reset_n='0' then					SMPLCNT_REG	<=	(others=>'0');
	elsif clk'event and clk='1' then
		if clr_in='1' then				SMPLCNT_REG	<=	(others=>'0');
		elsif START_FH='1' then			SMPLCNT_REG	<=	smplcnt_in;		--start timing of second harf rite
										SMPLCNTDLY_REG <= SMPLCNT_REG;	
		elsif START_SH='1' then			SMPLCNT_REG	<=	smplcnt_in;		--start timing of first harf write
										SMPLCNTDLY_REG <= SMPLCNT_REG;	
		else							SMPLCNT_REG	<=	SMPLCNT_REG;
		end if;
	end if;
	end process;

	process(clk,reset_n) begin
	if reset_n='0' then					MWSTS	<=	MW_IDLE;
	elsif clk'event and clk='1' then
		case	MWSTS is
			when MW_IDLE=>	
				if clr_in='0' then		MWSTS	<=	MW_FH_WAIT;
				else					MWSTS	<=	MWSTS;
				end if;

			-----------------------------------
			when MW_FH_WAIT=>											--wait buffer first half filled
				if START_FH='1' then  	MWSTS	<=	MW_FH_START;
				elsif clr_in='1' then	MWSTS	<=	MW_IDLE;
				else					MWSTS	<=	MWSTS;
				end if;

			when MW_FH_START=>			MWSTS	<=	MW_FH_WAIT_END;		--start first half transfer

			when MW_FH_WAIT_END=>
				if amw_end_in='1' then  MWSTS	<=	MW_FH_END;			--wait transfer end by ch
				else					MWSTS	<=	MWSTS;
				end if;

			when MW_FH_END=>
				if CH_CNT=7 then  		MWSTS	<=	MW_SH_WAIT;			--all channel end?
				else					MWSTS	<=	MW_FH_START;
				end if;

			-----------------------------------
			when MW_SH_WAIT=>
				if START_SH='1' then  	MWSTS	<=	MW_SH_START;
				elsif clr_in='1' then	MWSTS	<=	MW_IDLE;
				else					MWSTS	<=	MWSTS;
				end if;

			when MW_SH_START=>			MWSTS	<=	MW_SH_WAIT_END;

			when MW_SH_WAIT_END=>
				if amw_end_in='1' then  MWSTS	<=	MW_SH_END;
				else					MWSTS	<=	MWSTS;
				end if;

			when MW_SH_END=>
				if CH_CNT=7 then  		MWSTS	<=	MW_FH_WAIT;
				else					MWSTS	<=	MW_SH_START;
				end if;

			when others=>				MWSTS	<=	MW_IDLE;
		end case;
	end if;
	end process;

	amw_start_out	<=	'1'	when ((MWSTS = MW_FH_START) or (MWSTS = MW_SH_START))	else	'0';
	amw_disable_out	<=	'1' when MWSTS = MW_IDLE	else	'0';

	process(clk,reset_n) begin
	if reset_n='0' then					CH_CNT	<=	0;
	elsif clk'event and clk='1' then
		if clr_in='1' then				CH_CNT	<=	0;
		elsif MWSTS	= MW_FH_WAIT then	CH_CNT	<=	0;
		elsif MWSTS	= MW_SH_WAIT then	CH_CNT	<=	0;
		elsif ((MWSTS = MW_FH_END) or (MWSTS = MW_SH_END)) then	
			if 	CH_CNT < 7 then 		CH_CNT <= CH_CNT+1;
			else				 		CH_CNT <= CH_CNT;
			end if;
		else							CH_CNT <= CH_CNT;
		end if;
	end if;
	end process;

	process(clk,reset_n) begin
	if reset_n='0' then					buf_addr(4)	<=	'0';
	elsif clk'event and clk='1' then
		if MWSTS	= MW_FH_WAIT then	buf_addr(4)	<=	'0';
		elsif MWSTS	= MW_SH_WAIT then	buf_addr(4)	<=	'1';
		end if;
	end if;
	end process;

	buf_addr(7 downto 5)	<=	CONV_STD_LOGIC_VECTOR(CH_CNT,3);

	amw_addr(31 downto 24)	<=	(others=>'0');		--0x0c0_00000 - 0x00ff_ffff 4Mbyte
	amw_addr(23 downto 22)	<=	"11";				--
	amw_addr(21 downto 19)	<=	CONV_STD_LOGIC_VECTOR(CH_CNT,3);	--4Mbyte/8ch  512kbyte/ch, 256ksample/16bit 5.9s@44.2kHz
	amw_addr(18 downto 2)	<=	SMPLCNTDLY_REG(17 downto 1);	----SMPLCNT_REG(4 downto 1) = "0000"
	amw_addr(1 downto 0)	<=	"00";

	amw_length	<=	b"0_0000_0100_0000";	--64byte

	buf_addr(7 downto 5)	<=	CONV_STD_LOGIC_VECTOR(CH_CNT,3);

end rtl;

