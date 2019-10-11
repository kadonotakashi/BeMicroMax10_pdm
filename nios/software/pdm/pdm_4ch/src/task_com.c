/*
 * task_com.c
 *
 *  Created on: 2019/06/07
 *      Author: 13539
 */

#define	SEND_4CH


#include <stddef.h>
#include <stdlib.h>
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "taskdef.h"
#include "grp_lcd.h"
#include "ILI9341_nios.h"
#include "ft245_fifo.h"
#include "pdm_sub.h"
#include "dma.h"

extern xQueueHandle SnsorQue;
extern xQueueHandle SendReqQue;
extern volatile int sample_block;

void task_com(void *pvParameters )
{
	FT245FIFOmod *pFT245 = (FT245FIFOmod *) FT245_BASE;
	DMAMOD *pFT245_DMA =(DMAMOD *)DMA_BASE;
	int *pLED = (int *)LED_BASE;




	int LocalQue=SEND_STOP;
	int DMA_SRC_ADDR;
	portBASE_TYPE result;
	volatile int flag;
	int send_block;
	int send_block_max;



	int QueSns;
	int DataTxEn;

	char header[6];
	char footer[2];
	header[1]=0x80;	header[0]=0x00;
	header[3]=0x00;	header[2]=0x01;
	footer[1]=0x7f;	footer[0]=0xff;

	InitCom();		//FT245 initialize
	init_DMAMOD(pFT245_DMA);
	send_block=0;
	DataTxEn=0;

	for(;;){
		result = xQueueReceive(SendReqQue,&LocalQue,1);
		if (result==pdTRUE){
			send_block_max=LocalQue;
			send_block=0;
			DataTxEn=1;


//			QueSns=SnsQue_STOP;
//			xQueueSendToBack(SnsorQue,&QueSns,portMAX_DELAY);

			QueSns=SnsQue_START;
			xQueueSendToBack(SnsorQue,&QueSns,portMAX_DELAY);

		}

		if(DataTxEn == 1){
			if((sample_block>send_block) && (send_block<send_block_max)){
				header[5] = (char)((send_block>>8) & 0xff);
				header[4] = (char)(send_block & 0xff);
//				FT245_SendBlock(header,6);

				//cH0
				DMA_SRC_ADDR = 0xc00000 + (send_block & 0x7f) * 0x1000;
				startDMA ( pFT245_DMA, DMA_SRC_ADDR, (int)&pFT245->Fifo,0x1000);

				flag = getDMAsts(pFT245_DMA);
				while(flag!=0){
					flag = getDMAsts(pFT245_DMA);
					vTaskDelay( 1/ portTICK_PERIOD_MS);
				}
#ifdef SEND_4CH
				//cH1
				DMA_SRC_ADDR = 0xc80000 + (send_block & 0x7f) * 0x1000;
				startDMA ( pFT245_DMA, DMA_SRC_ADDR, (int)&pFT245->Fifo,0x1000);

				flag = getDMAsts(pFT245_DMA);
				while(flag!=0){
					flag = getDMAsts(pFT245_DMA);
					vTaskDelay( 1/ portTICK_PERIOD_MS);
				}

				//cH2
				DMA_SRC_ADDR = 0xD00000 + (send_block & 0x7f) * 0x1000;
				startDMA ( pFT245_DMA, DMA_SRC_ADDR, (int)&pFT245->Fifo,0x1000);

				flag = getDMAsts(pFT245_DMA);
				while(flag!=0){
					flag = getDMAsts(pFT245_DMA);
					vTaskDelay( 1/ portTICK_PERIOD_MS);
				}
				//cH3
				DMA_SRC_ADDR = 0xD80000 + (send_block & 0x7f) * 0x1000;
				startDMA ( pFT245_DMA, DMA_SRC_ADDR, (int)&pFT245->Fifo,0x1000);

				flag = getDMAsts(pFT245_DMA);
				while(flag!=0){
					flag = getDMAsts(pFT245_DMA);
					vTaskDelay( 1/ portTICK_PERIOD_MS);
				}

#endif


//				FT245_SendBlock(footer,2);
				send_block++;
				*pLED = send_block;
			}

			if(send_block>=send_block_max){
				send_block=0;
				DataTxEn=0;
				QueSns=SnsQue_STOP;
				xQueueSendToBack(SnsorQue,&QueSns,portMAX_DELAY);
			}
		}
		vTaskDelay( 1/ portTICK_PERIOD_MS);
	}
}

