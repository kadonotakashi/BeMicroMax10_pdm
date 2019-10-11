/*
 * task_main.c
 *
 *  Created on: 2017/12/18
 *      Author: 13539
 */

#include <stddef.h>
#include <stdlib.h>
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "taskdef.h"

#include "lcd_que.h"
#include "grp_lcd.h"

#include "pdm_sub.h"

extern xQueueHandle ButtonQue;
extern xQueueHandle GLCD_QUE;
extern xQueueHandle SnsctrlQue;

extern CmdRespBuf RspBuf;
extern CmdRespBuf CmdBuf;

volatile int IFSTS;
GRAP_LCD_QUE	QUE_GLCD_LOCAL;


void task_main(void *pvParameters )
{
	char BUTTON_STS;
	int flag;
	portBASE_TYPE result;

	RspBuf.stx='(';
	RspBuf.etx=')';

	for(;;){
		//ボタンチェック
//		result = xQueueReceive(ButtonQue,&BUTTON_STS,1);
//		if (result==pdTRUE){
//			debug_print(RGB565_WHITE,"button pushed");
//		}
		//コマンドチェック

		flag = HostStsChk();
		if(flag!=0){
			flag = CommandChk(&IFSTS);
			if(flag==0){	//有効なコマンド
				Execute();
			}
			else{	//有効なコマンドでなかった
				RspBuf.command=CmdBuf.command;
				RspBuf.sub_command=CmdBuf.sub_command;


				if (flag==-1){
					RspBuf.param[0]='c';
					RspBuf.param[1]='e';
				}
				else if (flag==-2){
					RspBuf.param[0]='p';
					RspBuf.param[1]='e';
				}
				else{
					RspBuf.param[0]='?';
					RspBuf.param[1]='?';
				}
				RspBuf.param[2]='0';
				RspBuf.param[3]='0';
				RspBuf.param[4]='0';
				RspBuf.param[5]='0';
				FT245_SendBlock((char *)&RspBuf,10);
			}
		}
		vTaskDelay( 1/ portTICK_PERIOD_MS);
	}
}

