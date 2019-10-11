/*
 * task_disp.c
 *
 *  Created on: 2018/02/19
 *      Author: 13539
 */


#include "system.h"
#include <stddef.h>

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "taskdef.h"
#include "lcd_que.h"
#include "grp_lcd.h"

extern xQueueHandle GLCD_QUE;

GRAP_LCD_QUE	LocQue;
int debug_disp_raw=0;

void disp_debug_str(uint16_t color,uint8_t *str){

	glcd_put_string_fixed(	8,debug_disp_raw,(char *)str,color,0);
	debug_disp_raw+=12;
	if(debug_disp_raw>228){
		debug_disp_raw=0;
	}
	glcd_drawRectangleFill(	0,debug_disp_raw,319,debug_disp_raw+12,0,0);
}

void task_disp(void *pvParameters )
{  /* USER CODE BEGIN tk_qvga */

	portBASE_TYPE result;
	GRAP_LCD_QUE LocQue;

	glcd_Init(RGB565_BLACK);
	vTaskDelay( 10/portTICK_PERIOD_MS);

	for(;;)
	{

		result = xQueueReceive(GLCD_QUE,&LocQue,0);
#if 1
		if(result==pdTRUE){

			if(LocQue.data[0]==GLCDCMD_INIT){
				glcd_Init(LocQue.INIT.COLOR);
			}
			if(LocQue.data[0]==GLCDCMD_PSET){
				glcd_PointSet( LocQue.PSET.XS,LocQue.PSET.YS,LocQue.PSET.COLOR);
			}
			if(LocQue.data[0]==GLCDCMD_LINE){
				glcd_drawLine(LocQue.LINE.XS,LocQue.LINE.YS,LocQue.LINE.XE,LocQue.LINE.YE,LocQue.LINE.COLOR);
			}
			if(LocQue.data[0]==GLCDCMD_VLINE){
				glcd_drawVline(LocQue.VLINE.XS,LocQue.VLINE.YS,LocQue.VLINE.LENGTH,LocQue.VLINE.COLOR);
			}
			if(LocQue.data[0]==GLCDCMD_HLINE){
				glcd_drawHline(LocQue.HLINE.XS,LocQue.HLINE.YS,LocQue.HLINE.LENGTH,LocQue.HLINE.COLOR);
			}
			if(LocQue.data[0]==GLCDCMD_RECT){
				glcd_drawRectangle(LocQue.RECT.XS,LocQue.RECT.YS,LocQue.RECT.XE,LocQue.RECT.YE,LocQue.RECT.COLOR);
			}
			if(LocQue.data[0]==GLCDCMD_RECT_FILL){
				glcd_drawRectangleFill(LocQue.RECT_FILL.XS,LocQue.RECT_FILL.YS,LocQue.RECT_FILL.XE,LocQue.RECT_FILL.YE,
						LocQue.RECT_FILL.LINE_COLOR,LocQue.RECT_FILL.FILL_COLOR);
			}
			if(LocQue.data[0]==GLCDCMD_PRINT_STRING){
				glcd_put_string_fixed(LocQue.PRINT_STRING.XS,LocQue.PRINT_STRING.YS,LocQue.PRINT_STRING.str,
						LocQue.PRINT_STRING.COLOR,LocQue.PRINT_STRING.FONT_SIZE);
			}
			if(LocQue.data[0]==GLCDCMD_PRINT_STRING_ADA){
				glcd_put_string_Adafruit(LocQue.PRINT_STRING_ADA.XS,LocQue.PRINT_STRING_ADA.YS,LocQue.PRINT_STRING_ADA.str,
												LocQue.PRINT_STRING_ADA.COLOR,LocQue.PRINT_STRING_ADA.FONT_SEL);

			}
			if(LocQue.data[0]==GLCDCMD_BITBLT){
				glcd_BitBLT(LocQue.BITBLT.XS,LocQue.BITBLT.YS, LocQue.BITBLT.XE,LocQue.BITBLT.YE,LocQue.BITBLT.src);
			}
			if(	LocQue.data[0]==GLCDCMD_DEBUGLOG){	//デバッグ用の文字表示
				disp_debug_str( LocQue.DEBUG_LOG.COLOR,LocQue.DEBUG_LOG.pSTR);
			}
			else{
				//驍ｵ�ｽｺ髦ｮ蜻ｻ�ｽｽ迹夊р�ｿｽ�ｽｽ�ｽ･髯樊ｻ薙§�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｽ�ｽｯ髫ｴ蟷｢�ｽｽ�ｽｪ髯橸ｽｳ陞溘ｑ�ｽｽ�ｽｾ�ｿｽ�ｽｽ�ｽｩ
			}
		}
#endif


	vTaskDelay( 1/portTICK_PERIOD_MS);
  }
  /* USER CODE END tk_qvga */


}




