/*
 * ft245_fifo.h
 *
 *  Created on: 2016/01/06
 *      Author: 13539
 */

#ifndef FT245_FIFO_H_
#define FT245_FIFO_H_

typedef	volatile struct{
	unsigned int CtrlReg;	//0x00
	unsigned int IrqReg;	//0x04
	unsigned int TxReg;		//0x08
	unsigned int RxReg;		//0x0c
	unsigned int Fifo;		//0x10
}FT245FIFOmod;


//Control/status Register
#define	_bCrlBit			0x00000001
#define	_bRxRdyBit			0x00000002
#define	_bTxRdyBit			0x00000004
#define	_bTxBusyBit			0x00000008
#define	_bFIFO_EMPTY		0x00000010
#define	_bFIFO_FULL			0x00000020
#define	_bBlkTxBusyBit		0x00000010

//Irq Register
#define	_bRxIrqEnBit		0x00000001
//#define	_bTxIrqEnBit		0x00000002
#define	_bRxIrqStsBit		0x00000004
//#define	_bTxIrqStsBit		0x00000008



//コマンド受信ステータス
typedef enum _RCV_STS{
	IDLE,
	CMND,		//コマンド受信中
	COMPLETE,	//コマンド正常受信完了
	CMDERROR		//エラー状態
}RecievSeq;

typedef	volatile struct{
	//受信
	char			RecvBuf[16];
	int				RcvCnt;
	int				OverFlow;
	RecievSeq		RecvSeq;

}FT245_DATA;


typedef	volatile struct{
	//受信
	char			stx;
	char			command;
	char			sub_command;
	char			param[6];
	char			etx;

}CmdRespBuf;


void initFT245mod(void);
void FT245IRQregist(void);
void FT245_EnableRxIrq(void);
void FT245_DisableRxIrq(void);
int FT245_SendChar(char send_char);
int FT245_SendBlock(char *src,int count);
int FT245_Send_DMA_FIFO(int src,int count);


#endif /* FT245_FIFO_H_ */
