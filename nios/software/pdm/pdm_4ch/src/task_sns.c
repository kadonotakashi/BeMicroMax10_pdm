/*
 * task_sns.c
 *
 *  Created on: 2019/05/29
 *      Author: 13539
 */

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "system.h"

#include "taskdef.h"
#include "pdmmic.h"
#include "pdm_sub.h"

#include "grp_lcd.h"
#include "lcd_que.h"
#include "wave_img.h"

extern xQueueHandle SendReqQue;
extern xQueueHandle GLCD_QUE;
extern xQueueHandle ButtonQue;

extern xQueueHandle SnsorQue;


volatile int sample_block;

int SnsCtrlSTS;


void task_sns(void *pvParameters ){

	PDMMIC_MOD *pPDM =(PDMMIC_MOD *)PDM_BASE;
	int acq_flag;

	#define	COM_BLK_SIZE	2048
	int sample_count;
	int flag;
	portBASE_TYPE result;
	int localSnsQue;


	vTaskDelay( 1000/portTICK_PERIOD_MS);

	init_PDM();
	setMicGain(5);	//default

debug_print(RGB565_CYAN,"Mic caribration start");


	flag = MicCarivration();	//cansel Mic offset level
	if (flag==0){
		debug_print(RGB565_CYAN,"Mic caribration end");
	}else{
		debug_print(RGB565_CYAN,"Mic caribration ERROR");
	}

	sample_count = 0;
	sample_block = 0;
	acq_flag = 0;

	for(;;){
		//button push? (start/stop)
		result = xQueueReceive(SnsorQue,&localSnsQue,1);
		if(result==pdTRUE){
			if (localSnsQue == SnsQue_INIT){
				sample_count = 0;
				sample_block = 0;
				acq_flag = 0;

				SnsCtrlSTS = SnsSTS_BUSY;
				init_PDM();
debug_print(RGB565_CYAN,"Mic caribration start");
				flag = MicCarivration();	//cansel Mic offset level
				if (flag== 0){
debug_print(RGB565_CYAN,"Mic caribration end");
					SnsCtrlSTS = SnsSTS_IDLE;
				}
				else{
					SnsCtrlSTS = SnsSTS_ERROR;
debug_print(RGB565_RED,"Mic caribration err");
				}
			}
			else if (localSnsQue == SnsQue_START){
				sample_count = 0;
				sample_block = 0;
				acq_flag = 1;
				SnsCtrlSTS= SnsSTS_BUSY;
debug_print(RGB565_YELLOW,"Record start");
				enable_PDM();	//sample start

			}
			else if (localSnsQue == SnsQue_STOP){
debug_print(RGB565_YELLOW,"Record end");
				disable_PDM();	//sample stop
				SnsCtrlSTS= SnsSTS_IDLE;
				sample_count = 0;
				sample_block = 0;
				acq_flag=0;
			}else{
			}
		}

		if(acq_flag==1){	// in acquision
			sample_count = pPDM->SmpleCountReg;
			sample_block = sample_count/COM_BLK_SIZE;
		}
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}
}
