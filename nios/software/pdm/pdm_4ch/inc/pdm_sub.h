/*
 * de10_coin_sub.h
 *
 *  Created on: 2018/02/26
 *      Author: 13539
 */

#ifndef INC_PDM_SUB_H_
#define INC_PDM_SUB_H_

#include <stdint.h>

#include "ft245_fifo.h"
int AsciiHex2uint16( char *src,uint16_t *val);
void uint16toAsciiHex( uint16_t val,char *dst);


#define	SEND_START	1
#define	SEND_STOP	2

#define	CH_MAX	8
#define	CH_BUF_SIZE	1024*512 //512lbyte

//queue to task_sns and status
enum SnsQue{
	SnsQue_INIT,
	SnsQue_START,
	SnsQue_STOP
};

enum SnsSTS{
	SnsSTS_IDLE,
	SnsSTS_BUSY,
	SnsSTS_ERROR
};


char conv_4bit_7segdata(char data);
void InitCom(void);
int AsciiHex2char( char *src,uint8_t *val);
void char2AsciiHex( char val,char *dst);


void CmndSeq(char recv_char);
int HostStsChk(void);
int CommandChk(int *STS);
void Execute(void);
void ClearImgBuffer( int page);
void debug_print(uint16_t color,char *str);


#endif /* INC_PDM_SUB_H_ */
