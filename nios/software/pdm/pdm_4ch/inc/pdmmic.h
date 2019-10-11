/*
 * pdmmic.h
 *
 *  Created on: 2019/05/29
 *      Author: 13539
 */

#ifndef INC_PDMMIC_H_
#define INC_PDMMIC_H_

#include <stdint.h>

typedef	volatile struct{

	volatile int16_t TMPBUF[1024];

	volatile uint32_t CtrlReg;			//0x00
	volatile uint32_t ChReg;			//0x04
	volatile uint32_t SmpleCountReg;	//0x08
	volatile uint32_t GainReg;			//0x0c
	volatile uint32_t ModeReg;			//0x0c
	volatile uint32_t dmy[3];			//0x10-1f
	volatile uint32_t OffsetCansel[8];	//0x20-3F
}PDMMIC_MOD;






typedef	volatile struct{
	uint16_t Data[8][256*1024];		//512kbyte x 8ch
}PDMMIC_DATA;

#define	_b_PDMMIC_CLR	0x00000001
#define	MIC_CH_MAX		4
//#define	DEFAULT_OFFST_CAN	2512

#define	DEFAULT_OFFST_CAN	0

#define	FIRGAIN	(float)2553


void init_PDM(void);
void enable_PDM(void);
void disable_PDM(void);
int setMicGain( uint8_t gain);
int CansellOffset(int ch,int datacount);
int MicCarivration(void);
void getMicData(int SampleCount);
int setSampleFreq( uint8_t Freq);
int setMicGain( uint8_t gain);

#endif /* INC_PDMMIC_H_ */
