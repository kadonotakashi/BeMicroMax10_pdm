/*
 * de10_coin_sub.c
 *
 *  Created on: 2018/02/26
 *      Author: 13539
 */




/*
 * mag_test_sub.c
 *
 *  Created on: 2017/03/31
 *      Author: 13539
 */

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "stdint.h"
#include "system.h"

#include "ft245_fifo.h"
#include "dma.h"
#include "lcd_que.h"
#include "ILI9341_nios.h"
#include "pdm_sub.h"

extern FT245_DATA	Ft245Data;
extern CmdRespBuf CmdBuf;
extern CmdRespBuf RspBuf;


extern xQueueHandle SnsorQue;
extern xQueueHandle SendReqQue;

extern uint8_t TrigDly;	//2019/01/25

extern xQueueHandle GLCD_QUE;
extern int SnsCtrlSTS;

char conv_4bit_7segdata(char data)
{
	switch( data&0x0f){
	case 0x00:	return 0xc0;
	case 0x01:	return 0xf9;
	case 0x02:	return 0xa4;
	case 0x03:	return 0x70;
	case 0x04:	return 0x99;
	case 0x05:	return 0x92;
	case 0x06:	return 0x82;
	case 0x07:	return 0xf8;
	case 0x08:	return 0x80;
	case 0x09:	return 0x90;
	case 0x0a:	return 0x88;
	case 0x0b:	return 0x83;
	case 0x0c:	return 0xc6;
	case 0x0d:	return 0xa1;
	case 0x0e:	return 0x86;
	case 0x0f:	return 0x8e;
	default:	return 0xff;
	}
}

void debug_print(uint16_t color,char *str){
	GRAP_LCD_QUE	QUE_GLCD_LOCAL;
	QUE_GLCD_LOCAL.DEBUG_LOG.CMD = GLCDCMD_DEBUGLOG;
	QUE_GLCD_LOCAL.DEBUG_LOG.COLOR=color;
	QUE_GLCD_LOCAL.DEBUG_LOG.pSTR=str;
	xQueueSendToBack(GLCD_QUE,&QUE_GLCD_LOCAL,10);

}

void InitCom(void)
{
	//FT245 �������Ɗ��荞�݋��B
	initFT245mod();
	FT245IRQregist();
	FT245_EnableRxIrq();

	Ft245Data.OverFlow=0;
	Ft245Data.RcvCnt=0;
	Ft245Data.RecvSeq=IDLE;
}

int AsciiHex2uint16( char *src,uint16_t *val)
{
	int i;
	uint16_t temp=0;

	for(i=0;i<4;i++,src++){
		temp = temp<<4;
		if((*src>='0')&&(*src<='9')){
			temp += (*src-'0');
		}else if((*src>='A')&&(*src<='F')){
			temp += (*src-55);
		}else{
			return -1;
		}
	}
	*val=temp;
	return 0;
}

void uint16toAsciiHex( uint16_t val,char *dst)
{
	uint16_t v;
	int i;
	char temp;

	v=val;
	for(i=3;i>=0;i--){
		temp = v & 0x0f;
		if (temp>9){
			*(dst+i)=(temp + 55);
		}else{
			*(dst+i)=(temp + '0');
		}
		v = v >>4;
	}
	*(dst+4)=0;

}



int AsciiHex2char( char *src,uint8_t *val)
{
	uint8_t temp=0;
	if((*src>='0')&&(*src<='9')){
		temp=(*src-'0')*0x10;
	}else if((*src>='A')&&(*src<='F')){
		temp=(*src-55)*0x10;
	}else{
		return -1;
	}

	if((*(src+1)>='0')&&(*(src+1)<='9')){
		temp+=(*(src+1)-'0');
	}else if((*(src+1)>='A')&&(*(src+1)<='F')){
		temp+=(*(src+1)-55);
	}else{
		return -1;
	}
	*val = temp;
	return 0;
}


void char2AsciiHex( char val,char *dst)
{
	char temp;

	temp=(val>>4)&0x0f;
	if (temp>9){
		*dst=(temp + 55);
	}else{
		*dst=(temp + '0');
	}

	temp=val&0x0f;
	if (temp>9){
		*(dst+1)=(temp + 55);
	}else{
		*(dst+1)=(temp + '0');
	}
	*(dst+2)=0;
}



void CmndSeq(char recv_char){

	if (recv_char=='(') {	//�����I�ɃR�}���h��M�J�n
		Ft245Data.RcvCnt=0;
		Ft245Data.RecvSeq=CMND;
	}
	else if (recv_char==')') {
		if (Ft245Data.RcvCnt==8){
			Ft245Data.RecvSeq=COMPLETE;
			CmdBuf.command		=Ft245Data.RecvBuf[0];
			CmdBuf.sub_command	=Ft245Data.RecvBuf[1];
			CmdBuf.param[0]		=Ft245Data.RecvBuf[2];
			CmdBuf.param[1]		=Ft245Data.RecvBuf[3];
			CmdBuf.param[2]		=Ft245Data.RecvBuf[4];
			CmdBuf.param[3]		=Ft245Data.RecvBuf[5];
			CmdBuf.param[4]		=Ft245Data.RecvBuf[6];
			CmdBuf.param[5]		=Ft245Data.RecvBuf[7];
		}
		else{
			Ft245Data.RecvSeq=CMDERROR;
		}
	}else if (Ft245Data.RcvCnt>=8){
		Ft245Data.RecvSeq=CMDERROR;
	}else{
		Ft245Data.RecvBuf[Ft245Data.RcvCnt]=recv_char;
		Ft245Data.RcvCnt++;
	}

}


int HostStsChk(void)
{
	if( Ft245Data.RecvSeq==COMPLETE	){
		//�R�}���h����
		Ft245Data.OverFlow=0;
		Ft245Data.RcvCnt=0;
		Ft245Data.RecvSeq=IDLE;
		return 1;
	}
	else if( Ft245Data.RecvSeq==CMDERROR	){
		Ft245Data.OverFlow=0;
		Ft245Data.RcvCnt=0;
		Ft245Data.RecvSeq=IDLE;
		//�ʐM�G���[����
	}
	else if( Ft245Data.RecvSeq==CMND	){
		//�R�}���h��M��
	}
	else if( Ft245Data.RecvSeq==IDLE	){
	}
	return 0;
}


int CommandChk(int *STS)
{
#if 1
	volatile int CmfChkFlag,ParmChkFlag	;
	volatile int flag;
	uint8_t val;
	uint16_t	val16;

	CmfChkFlag =-1;
	ParmChkFlag=-2;
	//////////////
	//command check
	//////////////

	//STS=0 idle,STS!=0 Busy
	if (('I'==CmdBuf.command) &&('S'==CmdBuf.sub_command)){							//Initial sensor
		CmfChkFlag=1;
		*STS=0;
	}
	else if (('G'==CmdBuf.command) &&('W'==CmdBuf.sub_command) && (*STS==0)){		//get wave
		CmfChkFlag=1;
	}
	else if (('S'==CmdBuf.command) &&('G'==CmdBuf.sub_command) && (*STS==0)){		//set gain
		CmfChkFlag=1;
	}
	else if (('S'==CmdBuf.command) &&('F'==CmdBuf.sub_command) && (*STS==0)){		//set Sample Frequency
		CmfChkFlag=1;
	}

	if (1!=CmfChkFlag)	return CmfChkFlag;	//�R�}���h����`

	//////////////
	//parameter check
	//////////////
	if(('I'==CmdBuf.command)&&('S'==CmdBuf.sub_command))		//reset command
	{
		//not need parameter
		//ignore parameter
		ParmChkFlag=1;
		return 0;
	}
	else if(('G'==CmdBuf.command)&&('W'==CmdBuf.sub_command))		//GetWave command
	{
		//"ab0000"	ab�̓u���b�N���@1bock=4kbyte=2k sample = 64ms@32kHz,128ms@16kHz
		flag=AsciiHex2char( (char *)&CmdBuf.param[0],(char *)&val);
		if (flag!=0)				return ParmChkFlag;

		ParmChkFlag=1;
		return 0;
	}
	else if(('S'==CmdBuf.command)&&('G'==CmdBuf.sub_command))		//GetWave command
	{
		//"ab0000"	ab�̓Q�C���@1�L���Ȃ̂� 00,01,02, .. 07
		flag=AsciiHex2char( (char *)&CmdBuf.param[0],(char *)&val);
		if (flag!=0)				return ParmChkFlag;
		if((val<0) || (val>0x7))	return ParmChkFlag;

		ParmChkFlag=1;
		return 0;
	}
	else if(('S'==CmdBuf.command)&&('F'==CmdBuf.sub_command))		//GetWave command
	{
		//"ab0000"	ab�̓T���v�����g���̐ݒ�@00:32kHz�@01:16kHz
		flag=AsciiHex2char( (char *)&CmdBuf.param[0],(char *)&val);
		if (flag!=0)				return ParmChkFlag;
		if((val<0) || (val>1))	return ParmChkFlag;

		ParmChkFlag=1;
		return 0;
	}

	return 0;//�������甲���Ȃ��͂�
#endif
}

void Execute(void)
{
	int flag;
	int QueSns;
	int QueCOM;
	uint16_t val;
	uint8_t val8;
	//////////////
	//execute command
	//////////////
	if(('I'==CmdBuf.command)&&('S'==CmdBuf.sub_command))		//reset command
	{
		RspBuf.command='I';
		RspBuf.sub_command='S';
		RspBuf.param[0]='0';
		RspBuf.param[1]='0';
		RspBuf.param[2]='0';
		RspBuf.param[3]='0';
		RspBuf.param[4]='0';
		RspBuf.param[5]='0';

		QueSns=SnsQue_INIT;

		xQueueSendToBack(SnsorQue,&QueSns,portMAX_DELAY);
		vTaskDelay( 100/ portTICK_PERIOD_MS);
		while(SnsCtrlSTS == SnsSTS_BUSY){
			vTaskDelay( 1/ portTICK_PERIOD_MS);
		}
		if(SnsCtrlSTS == SnsSTS_ERROR){
			RspBuf.param[0]='E';
			RspBuf.param[1]='R';
			RspBuf.param[2]='R';
		}

		FT245_SendBlock((char *)&RspBuf,10);
	}
	else if(('G'==CmdBuf.command)&&('W'==CmdBuf.sub_command))		//read register command
	{

		RspBuf.command='G';
		RspBuf.sub_command='W';
		RspBuf.param[0]='0';
		RspBuf.param[1]='0';
		RspBuf.param[2]='0';
		RspBuf.param[3]='0';
		RspBuf.param[4]='0';
		RspBuf.param[5]='0';

		flag	= 	AsciiHex2uint16(&CmdBuf.param[0],&val);	//�̎�u���b�N��
		if (flag != 0){
			RspBuf.command='G';
			RspBuf.sub_command='W';
			RspBuf.param[0]='p';
			RspBuf.param[1]='e';
			FT245_SendBlock((char *)&RspBuf,10);
			return;
		}
		else{
			QueCOM = val;
			xQueueSendToBack(SendReqQue,&QueCOM,portMAX_DELAY);

//			QueSns=SnsQue_START;
//			xQueueSendToBack(SnsorQue,&QueSns,portMAX_DELAY);
		}

		vTaskDelay( 100/ portTICK_PERIOD_MS);
		while(SnsCtrlSTS == SnsSTS_BUSY){
			vTaskDelay( 1/ portTICK_PERIOD_MS);
		}
		if(SnsCtrlSTS == SnsSTS_ERROR){
			RspBuf.param[0]='E';
			RspBuf.param[1]='R';
			RspBuf.param[2]='R';
		}

		FT245_SendBlock((char *)&RspBuf,10);

	}
	else if(('S'==CmdBuf.command)&&('G'==CmdBuf.sub_command))		//read register command
	{

		RspBuf.command='S';
		RspBuf.sub_command='G';
		RspBuf.param[0]='0';
		RspBuf.param[1]='0';
		RspBuf.param[2]='0';
		RspBuf.param[3]='0';
		RspBuf.param[4]='0';
		RspBuf.param[5]='0';

		flag	= 	AsciiHex2char(&CmdBuf.param[0],&val8);	//gain
		if ((flag != 0) || val8>7){
			RspBuf.command='G';
			RspBuf.sub_command='W';
			RspBuf.param[0]='p';
			RspBuf.param[1]='e';
			FT245_SendBlock((char *)&RspBuf,10);
			return;
		}
		else{
			setMicGain(val8);	//default
			flag = MicCarivration();
			if(0!=flag){
				RspBuf.param[0]='E';
				RspBuf.param[1]='R';
				RspBuf.param[2]='R';
debug_print(RGB565_RED,"Gain Set Error");
			}
			else{
debug_print(RGB565_GREEN,"Gain Set Successfully");

			}

		}
		FT245_SendBlock((char *)&RspBuf,10);

	}
	else if(('S'==CmdBuf.command)&&('F'==CmdBuf.sub_command))		//read register command
	{

		RspBuf.command='S';
		RspBuf.sub_command='F';
		RspBuf.param[0]='0';
		RspBuf.param[1]='0';
		RspBuf.param[2]='0';
		RspBuf.param[3]='0';
		RspBuf.param[4]='0';
		RspBuf.param[5]='0';

		flag	= 	AsciiHex2char(&CmdBuf.param[0],&val8);	//gain
		if ((flag != 0) || (val8<0) || (val8>1)){
			RspBuf.command='S';
			RspBuf.sub_command='F';
			RspBuf.param[0]='p';
			RspBuf.param[1]='e';
			FT245_SendBlock((char *)&RspBuf,10);
			return;
		}
		else{
			setSampleFreq(val8);	//default
			debug_print(RGB565_GREEN,"Sample Frequency Set Successfully");
		}
		FT245_SendBlock((char *)&RspBuf,10);
	}
}
