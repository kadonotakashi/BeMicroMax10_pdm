--
--	PDM MIC interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pdm_cpuif is
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
end pdm_cpuif;

architecture RTL of pdm_cpuif is
	signal	SEL_CTRLreg		:std_logic;
	signal	SEL_STSreg		:std_logic;
	signal	SEL_CHreg		:std_logic;
	signal	SEL_GAINreg		:std_logic;
	signal	SEL_MODEreg		:std_logic;
	signal	SEL_SMPLCNTreg	:std_logic;
	signal	SEL_OFFSETreg	:std_logic;
	signal	SEL_BUF			:std_logic;

	signal	CTRLreg			:std_logic_vector(0 downto 0);
	signal	STSreg			:std_logic_vector(0 downto 0);
	signal	CHreg			:std_logic_vector(2 downto 0);
	signal	GAINreg			:std_logic_vector(3 downto 0);
	signal	MODEreg			:std_logic_vector(3 downto 0);
--		mode_freq_out		:std_logic;	--	mode bit0 0:32kH	1:16kHz



	signal	OFFSETreg0		:std_logic_vector(13 downto 0);
	signal	OFFSETreg1		:std_logic_vector(13 downto 0);
	signal	OFFSETreg2		:std_logic_vector(13 downto 0);
	signal	OFFSETreg3		:std_logic_vector(13 downto 0);
	signal	OFFSETreg4		:std_logic_vector(13 downto 0);
	signal	OFFSETreg5		:std_logic_vector(13 downto 0);
	signal	OFFSETreg6		:std_logic_vector(13 downto 0);
	signal	OFFSETreg7		:std_logic_vector(13 downto 0);
	signal	OFFSETreg		:std_logic_vector(13 downto 0);

begin

	SEL_CTRLreg		<=	sel	when addr=B"1000_0000_00" else'0';
	SEL_STSreg		<=	sel	when addr=B"1000_0000_00" else'0';
	SEL_CHreg		<=	sel	when addr=B"1000_0000_01" else'0';
	SEL_SMPLCNTreg	<=	sel	when addr=B"1000_0000_10" else'0';
	SEL_GAINreg		<=	sel	when addr=B"1000_0000_11" else'0';
	SEL_MODEreg		<=	sel	when addr=B"1000_0001_00" else'0';

	SEL_OFFSETreg	<=	sel	when addr(11 downto 5)=B"1000_001" else'0';

	SEL_BUF			<=	sel	when addr(11)='0' else'0';


	process(clk,reset_n) begin
	if reset_n='0' then
		CTRLreg(0)	<=	'0';
		CHreg		<=	"000";
		GAINreg		<=	"0100";
		MODEreg		<=	"0100";

	elsif CLK'event and CLK='1' then
		if SEL_CTRLreg='1' and ben(0)='1' and wr='1' then
			CTRLreg(0)	<=	wrdata(0);
		else
			CTRLreg(0)	<=	CTRLreg(0);
		end if;

		if SEL_CHreg='1' and ben(0)='1' and wr='1' then
			CHreg	<=	wrdata(2 downto 0);
		else
			CHreg	<=	CHreg;
		end if;

		if SEL_GAINreg='1' and ben(0)='1' and wr='1' then
			GAINreg	<=	wrdata(3 downto 0);
		else
			GAINreg	<=	GAINreg;
		end if;

		if SEL_MODEreg='1' and ben(0)='1' and wr='1' then
			MODEreg	<=	wrdata(3 downto 0);
		else
			MODEreg	<=	MODEreg;
		end if;

	end if;
	end process;


	process(clk,reset_n) begin
	if reset_n='0' then
		OFFSETreg0	<=	B"00_1000_1100_0111";
		OFFSETreg1	<=	B"00_1000_1100_0111";
		OFFSETreg2	<=	B"00_1000_1100_0111";
		OFFSETreg3	<=	B"00_1000_1100_0111";
		OFFSETreg4	<=	B"00_1000_1100_0111";
		OFFSETreg5	<=	B"00_1000_1100_0111";
		OFFSETreg6	<=	B"00_1000_1100_0111";
		OFFSETreg7	<=	B"00_1000_1100_0111";

	elsif CLK'event and CLK='1' then
		if SEL_OFFSETreg='1' and wr='1' then
			if ben(0)='1'  then
				if addr(4 downto 2)= B"000" then
					OFFSETreg0(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg0(7 downto 0)	<=	OFFSETreg0(7 downto 0);
				end if;

				if addr(4 downto 2)= B"001" then
					OFFSETreg1(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg1(7 downto 0)	<=	OFFSETreg1(7 downto 0);
				end if;

				if addr(4 downto 2)= B"010" then
					OFFSETreg2(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg2(7 downto 0)	<=	OFFSETreg2(7 downto 0);
				end if;

				if addr(4 downto 2)= B"011" then
					OFFSETreg3(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg3(7 downto 0)	<=	OFFSETreg3(7 downto 0);
				end if;

				if addr(4 downto 2)= B"100" then
					OFFSETreg4(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg4(7 downto 0)	<=	OFFSETreg4(7 downto 0);
				end if;

				if addr(4 downto 2)= B"101" then
					OFFSETreg5(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg5(7 downto 0)	<=	OFFSETreg5(7 downto 0);
				end if;

				if addr(4 downto 2)= B"110" then
					OFFSETreg6(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg6(7 downto 0)	<=	OFFSETreg6(7 downto 0);
				end if;

				if addr(4 downto 2)= B"111" then
					OFFSETreg7(7 downto 0)	<=	wrdata(7 downto 0);
				else
					OFFSETreg7(7 downto 0)	<=	OFFSETreg7(7 downto 0);
				end if;
			end if;
			
			if ben(1)='1'  then
				if addr(4 downto 2)= B"000" then
					OFFSETreg0(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg0(13 downto 8)	<=	OFFSETreg0(13 downto 8);
				end if;

				if addr(4 downto 2)= B"001" then
					OFFSETreg1(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg1(13 downto 8)	<=	OFFSETreg1(13 downto 8);
				end if;

				if addr(4 downto 2)= B"010" then
					OFFSETreg2(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg2(13 downto 8)	<=	OFFSETreg2(13 downto 8);
				end if;

				if addr(4 downto 2)= B"011" then
					OFFSETreg3(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg3(13 downto 8)	<=	OFFSETreg3(13 downto 8);
				end if;

				if addr(4 downto 2)= B"100" then
					OFFSETreg4(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg4(13 downto 8)	<=	OFFSETreg4(13 downto 8);
				end if;

				if addr(4 downto 2)= B"101" then
					OFFSETreg5(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg5(13 downto 8)	<=	OFFSETreg5(13 downto 8);
				end if;

				if addr(4 downto 2)= B"110" then
					OFFSETreg6(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg6(13 downto 8)	<=	OFFSETreg6(13 downto 8);
				end if;

				if addr(4 downto 2)= B"111" then
					OFFSETreg7(13 downto 8)	<=	wrdata(13 downto 8);
				else
					OFFSETreg7(13 downto 8)	<=	OFFSETreg7(13 downto 8);
				end if;
			end if;
		else
			OFFSETreg0	<=	OFFSETreg0;
			OFFSETreg1	<=	OFFSETreg1;
			OFFSETreg2	<=	OFFSETreg2;
			OFFSETreg3	<=	OFFSETreg3;
			OFFSETreg4	<=	OFFSETreg4;
			OFFSETreg5	<=	OFFSETreg5;
			OFFSETreg6	<=	OFFSETreg6;
			OFFSETreg7	<=	OFFSETreg7;
		end if;
		
	end if;
	end process;

	clr_out		<=	CTRLreg(0);
	STSreg(0)	<=	CTRLreg(0);

	ch_out		<=	CHreg;
	gain_out	<=	GAINreg;

	mode_freq_out	<=	MODEreg(0);

    bufaddr_out	<=	addr(6 downto 2);

	rddata	<=	X"0000000" & "000" 	&	STSreg		when SEL_STSreg='1'
	else		X"0000000" & '0' 	&	CHreg		when SEL_CHreg='1'
	else		X"00" 				&	smpl_cnt	when SEL_SMPLCNTreg='1'
	else		X"0000000" 			& GAINreg		when SEL_GAINreg='1'
	else		X"0000000" 			& MODEreg		when SEL_MODEreg='1'
	else								bufdata_in	when SEL_BUF='1'
	else		X"0000" & "00" 		&	OFFSETreg	when SEL_OFFSETreg='1'
	else		(others=>'0');

	OFFSETreg	<=	OFFSETreg0	when addr(4 downto 2)= B"000"
	else			OFFSETreg1	when addr(4 downto 2)= B"001"
	else			OFFSETreg2	when addr(4 downto 2)= B"010"
	else			OFFSETreg3	when addr(4 downto 2)= B"011"
	else			OFFSETreg4	when addr(4 downto 2)= B"100"
	else			OFFSETreg5	when addr(4 downto 2)= B"101"
	else			OFFSETreg6	when addr(4 downto 2)= B"110"
	else			OFFSETreg7	when addr(4 downto 2)= B"111"
	else			(others=>'0');

	offset0	<=	OFFSETreg0;
	offset1	<=	OFFSETreg1;
	offset2	<=	OFFSETreg2;
	offset3	<=	OFFSETreg3;
	offset4	<=	OFFSETreg4;
	offset5	<=	OFFSETreg5;
	offset6	<=	OFFSETreg6;
	offset7	<=	OFFSETreg7;

end RTL;