/*
 * task_button.c
 *
 *  Created on: 2017/12/01
 *      Author: 13539
 */



#include "system.h"
#include <stddef.h>

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "taskdef.h"

extern xQueueHandle ButtonQue;


void task_button(void *pvParameters )
{

#define	DEGLITCH_CNT	10

	char	BTN_STS=0x00;	//deGlitch後のボタンのステータス

	unsigned char *pBTN =(unsigned char *)BUTTON_BASE;
	uint8_t BtnREAD;

	int COUNT0 = 0;
	int COUNT1 = 0;
	int COUNT2 = 0;
	int COUNT3 = 0;

	for(;;){
		BTN_STS=0x00;
		BtnREAD = (~(*pBTN))&0x0f;

		//button0
		if (BtnREAD & 0x1){//push
			if (COUNT0<DEGLITCH_CNT){
				COUNT0++;
			}
		}
		else{	//release
			if (COUNT0==DEGLITCH_CNT){	//release after 100ms push
				BTN_STS += 0x01;
			}
			COUNT0=0;
		}

		//button1
		if (BtnREAD & 0x2){//push
			if (COUNT1 < DEGLITCH_CNT){
				COUNT1++;
			}
		}
		else{	//release
			if (COUNT1==DEGLITCH_CNT){	//release after 100ms push
				BTN_STS += 0x02;
			}
			COUNT1 = 0;
		}

		//button2
		if (BtnREAD & 0x4){//push
			if (COUNT2 < DEGLITCH_CNT){
				COUNT2++;
			}
		}
		else{	//release
			if (COUNT2==DEGLITCH_CNT){	//release after 100ms push
				BTN_STS += 0x04;
			}
			COUNT2 = 0;
		}

		//button3
		if (BtnREAD & 0x8){//push
			if (COUNT3 < DEGLITCH_CNT){
				COUNT3++;
			}
		}
		else{	//release
			if (COUNT3==DEGLITCH_CNT){	//release after 100ms push
				BTN_STS += 0x08;
			}
			COUNT3 = 0;
		}


		if(BTN_STS!=0){
			xQueueSendToBack(ButtonQue,&BTN_STS,portMAX_DELAY);
		}

		vTaskDelay( 10/ portTICK_PERIOD_MS);
	}
}



