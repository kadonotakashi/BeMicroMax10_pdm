/*
 * ft245_fifo.c
 *
 *  Created on: 2016/01/06
 *      Author: 13539
 */


#include "alt_types.h"
#include <sys/alt_irq.h>
//#include "host.h"
#include "ft245_fifo.h"
#include "system.h"
#include "dma.h"
static void FT245_IRQ_SERVICE(void *sts,alt_u32 IntID);

DMAMOD	*pDMA = (DMAMOD *)DMA_BASE;
FT245FIFOmod *pFT245 = (FT245FIFOmod *)FT245_BASE;
FT245_DATA	Ft245Data;

CmdRespBuf CmdBuf;
CmdRespBuf RspBuf;

void initFT245mod(void){

//	pFT245->CtrlReg =_bCrlBit +_bFT245ResetBit;
	pFT245->CtrlReg =_bCrlBit;
	pFT245->IrqReg = 0x0;	//割り込み禁止

	pFT245->CtrlReg =	_bCrlBit;
	pFT245->CtrlReg =	0x00;

}

//割り込み処理
static void FT245_IRQ_SERVICE(void *sts,alt_u32 IntID)
{
	char	recv_char;

	//Recieve Interrupt?
	if ((pFT245->IrqReg & _bRxIrqStsBit)!=0){
		recv_char=pFT245->RxReg;
		CmndSeq	(recv_char);
	}
}

//割り込み処理の登録
void FT245IRQregist(void){

    alt_irq_register(FT245_IRQ,(long * )&Ft245Data, FT245_IRQ_SERVICE);

}
///////////////////////////////////
//受信割り込み許可/禁止
void FT245_EnableRxIrq(void){
	int dummy;

	while(1){
		dummy=pFT245->RxReg;
		pFT245->RxReg=dummy;
		if ((pFT245->IrqReg & _bRxIrqStsBit)==0)						break;
	}
	Ft245Data.RcvCnt=0;
	Ft245Data.OverFlow=0;
	pFT245->IrqReg |= _bRxIrqEnBit;
}

void FT245_DisableRxIrq(void){
	pFT245->IrqReg &= ~_bRxIrqEnBit;
}

int FT245_SendChar(char send_char){
	if (pFT245->CtrlReg & _bTxBusyBit){
		return -1;	//送信中
	}
	if((pFT245->CtrlReg&_bRxRdyBit)!=0){
		return -1;//未処理受信データ有
	}
	pFT245->TxReg=send_char;
	return 0;
}

int FT245_SendBlock(char *src,int count){

	char senddata;
	int i;
	int flag;
	int remain;
	for(i=0;i<count;i++,src++){

		while (pFT245->CtrlReg & _bTxBusyBit){
			flag=pFT245->CtrlReg;	//送信中
		}
		while((pFT245->CtrlReg&_bRxRdyBit)!=0){
			flag=pFT245->CtrlReg;	//未処理受信データ有
		}

		senddata=*src;
		FT245_SendChar(senddata);
	}


	return 0;
}

int FT245_Send_DMA_FIFO(int src,int count){


	char senddata;
	int i;
	int flag;
	int remain;
	int length=8192;	//0x2000 byte = 0x800word;
	int src_addr,dst_addr;
	int *sp,*dp;

#define DMA 1

#if DMA
	dst_addr = (int)&pFT245->Fifo;	//write address is fixed
//	dst_addr = 0x6200000;	//write address is fixed
	src_addr = src;			//read address is incremented in while loop
	remain=count;
	init_DMAMOD(pDMA);
	while(remain){
		flag=pFT245->CtrlReg;

		while (pFT245->CtrlReg & _bFIFO_FULL){
			flag=pFT245->CtrlReg;	//FIFO FULL
		}

		if (remain<length){
			length=remain;
		}
		startDMA(pDMA,src_addr,dst_addr,length);
		flag = getDMAsts(pDMA);

		while(flag!=0){
			flag = getDMAsts(pDMA);
		}
		remain-=length;
		src_addr+=length;
	}
#else

	sp=(int *)src;
	dp = (int *)&pFT245->Fifo;	//write address is fixed

	for(i=0;i<count/4;i++,sp++){
		*dp=*sp;
	}


#endif
	return 0;
}

