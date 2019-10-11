/*
 * dma.h
 *
 *  Created on: 2017/04/03
 *      Author: 13539
 */

#ifndef DMA_H_
#define DMA_H_


//altera embeded peripheral
typedef struct{
	volatile int	STATUSreg;		//0x00
	volatile int	RD_ADDRreg;		//0x04
	volatile int	WR_ADDRreg;		//0x08
	volatile int	LENGTHreg;		//0x0C
	volatile int	rsrved[2];		//0x10,14
	volatile int	CTRLreg;		//0x18
}DMAMOD;

//status register
#define	_b_DMA_DONE		0x00000001	//
#define	_b_DMA_BUSY		0x00000002	//
#define	_b_DMA_ROP		0x00000004	//
#define	_b_DMA_WOP		0x00000008	//
#define	_b_DMA_LEN		0x00000010	//



//control register
#define	_b_DMA_BYTE		0x00000001	//
#define	_b_DMA_HW		0x00000002	//
#define	_b_DMA_WORD		0x00000004	//
#define	_b_DMA_GO		0x00000008	//
#define	_b_DMA_IRQ_EN	0x00000010	//
#define	_b_DMA_REEN		0x00000020	//
#define	_b_DMA_WEEN		0x00000040	//
#define	_b_DMA_LEEN		0x00000080	//
#define	_b_DMA_RCON		0x00000100	//read address constant
#define	_b_DMA_WCON		0x00000200	//write address constant
#define	_b_DMA_DOUBLE	0x00000400
#define	_b_DMA_QUAD		0x00000800
#define	_b_DMA_SWRESET	0x00001000


//proto
void init_DMAMOD(DMAMOD *p);
void startDMA(DMAMOD *p,int src_addr,int dst_addr,int length);
int getDMAsts(DMAMOD *p);


#endif /* DMA_H_ */
