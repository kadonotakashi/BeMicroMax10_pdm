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
#include "pdmmic.h"

#include "wave_img.h"
#include	"ILI9341_nios.h"

extern PDMMIC_DATA *pPDMDATA;

//
//	Vscale 0:32768->100dot
//         1:16383->100dot
//         2:8192 ->100dot
//         3:4096 ->100dot
//         4:2048 ->100dot
//         5:1024 ->100dot
//
//	Hscale 0:8192 ->256dot
//         1:4096 ->256dot
//         2:2048 ->256dot
//         3:1024 ->256dot
//         4:512  ->256dot
//         5:256  ->256dot
//
//	Mode   0: CH0
//         1: CH1
//         2: CG2
//         3: CH3
//         4: CH4
//
//
//
int plotPoint(DISP_BUF *pDISPBUF,int x,int y,uint16_t color){

	if( (x>=0) && (x<=256) && (y>=0) && (y<=199)){
		pDISPBUF->BMP[y][x] = color;
		return 0;
	}
	return -1;
}



int DispWaveImg(DISP_BUF *pDISPBUF,int mode,int Vscale,int Hscale){

	int ch;
	volatile int flag;
	uint16_t back_color=RGB565_BLACK;
	uint16_t scale_color=RGB565_RED;
	int HMAX=0;
	int	Vshift;
	int tstep;
	int16_t mic_data;
	uint16_t DotColor;

	int StrtCh,EndCh;



	int ypos;

	//clear display buffer
	start_LCD_DMA_BufferFill(&back_color,pDISPBUF,200*256*2);
	flag = get_LCD_DMA_sts();
	while(flag!=0){
		flag = get_LCD_DMA_sts();
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}

	//set Hscale
	HMAX=0;
	switch(Hscale){
	case 0:	HMAX=4096;	break;
	case 1:	HMAX=2048;	break;
	case 2:	HMAX=1024;	break;
	case 3:	HMAX=512;	break;
	case 4:	HMAX=256;	break;
	default:			break;
	}//end  switch(Hscale)
	if(HMAX==0){
		return -1;
	}
	tstep=HMAX/256;


	//set Vscale
	Vshift=0;
	switch(Vscale){
	case 0:	Vshift=8;	break;
	case 1:	Vshift=7;	break;
	case 2:	Vshift=6;	break;
	case 3:	Vshift=5;	break;
	case 4:	Vshift=4;	break;
	default:			break;
	}//end  switch(Hscale)

	if(Vshift==0){
		return -1;
	}

	//scale v=0
	start_LCD_DMA_BufferFill( &scale_color, &pDISPBUF->BMP[100][0], 256*2 );
	flag = get_LCD_DMA_sts();
	while(flag!=0){
		flag = get_LCD_DMA_sts();
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}

	//plot mic data

	if( 4 == mode){
		StrtCh=0;
		EndCh=4;
	}
	else{
		StrtCh=mode;
		EndCh=mode+1;
	}

	for(ch=StrtCh; ch<EndCh ;ch++){
		switch(ch){
			case 0:DotColor = RGB565_YELLOW;break;
			case 1:DotColor = RGB565_CYAN;break;
			case 2:DotColor = RGB565_MAGENTA;break;
			case 3:DotColor = RGB565_GREEN;break;
			default:DotColor = RGB565_WHITE;break;
		}
		for(int i=0,tpos=0,tsub=0;i<HMAX;i++){
			mic_data=pPDMDATA->Data[ch][i];
			mic_data = mic_data>>Vshift;
			ypos= 100 - mic_data;
			plotPoint(pDISPBUF,tpos,ypos,DotColor);

			if(tsub==tstep-1){
				tpos++;
				tsub=0;
			}
			else{
				tsub++;
			}
		}
	}
	return 0;
}

