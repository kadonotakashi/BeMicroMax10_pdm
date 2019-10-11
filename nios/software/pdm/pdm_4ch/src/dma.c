/*
 * dma.c
 *
 *  Created on: 2017/04/03
 *      Author: 13539
 */


#include "dma.h"


//
//	SDRAMからFT245インタフェースモジュールの（FIFOアドレス固定）への転送のみサポートする
//


void init_DMAMOD(DMAMOD *p){
	p->CTRLreg = 	_b_DMA_SWRESET;	//soft reset
	p->CTRLreg = 	0;	//soft reset

	p->CTRLreg = 	_b_DMA_WORD		//32bit only
				|	_b_DMA_WCON		//destination is fixed address;
				|	_b_DMA_LEEN	;				//source address increment
									//disable interrupt
}

void startDMA(DMAMOD *p,int src_addr,int dst_addr,int length){
	p->RD_ADDRreg	= src_addr;
	p->WR_ADDRreg	= dst_addr;
	p->LENGTHreg	= length;

	p->CTRLreg |= 	_b_DMA_GO;	//destination is fixed address;
}

int getDMAsts(DMAMOD *p){
	return p->STATUSreg &_b_DMA_BUSY;
}


