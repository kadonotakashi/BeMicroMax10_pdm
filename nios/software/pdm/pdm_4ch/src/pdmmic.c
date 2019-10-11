/*
 * pdmmic.c
 *
 *  Created on: 2019/05/29
 *      Author: 13539
 */

#include <stdlib.h>
#include "math.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "pdmmic.h"
#include "system.h"

#include "grp_lcd.h"

PDMMIC_MOD *pPDM=(PDMMIC_MOD *)PDM_BASE;
PDMMIC_DATA *pPDMDATA =(PDMMIC_DATA *)0x00c00000;	//SDRAM second half

static float	CoeffOfstCncl	;

void init_PDM(void){
	pPDM->CtrlReg = _b_PDMMIC_CLR;

	for( int i=0;i<MIC_CH_MAX;i++){
		pPDM->OffsetCansel[i]=DEFAULT_OFFST_CAN;
	}
}

void enable_PDM(void){
	pPDM->CtrlReg &= ~_b_PDMMIC_CLR;

}

void disable_PDM(void){
	pPDM->CtrlReg |= _b_PDMMIC_CLR;

}

int CansellOffset(int ch,int datacount){

	int Setteichi;
	int16_t snsdata;
	int count;
	int sum;
	float avg;

	if(ch>=MIC_CH_MAX)
		return -1;
	if(datacount>0x40000)
		return -1;

	disable_PDM();
	enable_PDM();

	count=pPDM->SmpleCountReg;
	while(count<datacount){
		count=pPDM->SmpleCountReg;
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}
	disable_PDM();


	for(sum=0,count=0;count<datacount;count++){
		snsdata = pPDMDATA->Data[ch][count];
		sum += snsdata;
	}

	avg = (float)sum/datacount;

	Setteichi = pPDM->OffsetCansel[ch];

	Setteichi -= (int16_t)(avg/39.2);
	pPDM->OffsetCansel[ch] = Setteichi;

	enable_PDM();
	count=pPDM->SmpleCountReg;
	while(count<datacount){
		count=pPDM->SmpleCountReg;
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}
	disable_PDM();


	for(sum=0,count=0;count<datacount;count++){
		snsdata = pPDMDATA->Data[ch][count];
		sum += snsdata;
	}

	avg = (float)sum/datacount;

	return (int)avg;
}

int MicCarivration(void){

#define	CaribSmplCount	4096
#define	OffsetMargin	100.0

	int delta;
	float average;
	int Setteichi;
	int16_t snsdata;
	int SampleCount;
	int ch;
	int flag;

	int Max[MIC_CH_MAX];
	int sum[MIC_CH_MAX];
	float avg[MIC_CH_MAX];
	int16_t temp16;

	char TryCount=0;
	char str[20];

	pPDM->OffsetCansel[0] = 0;
	pPDM->OffsetCansel[1] = 0;
	pPDM->OffsetCansel[2] = 0;
	pPDM->OffsetCansel[3] = 0;

	while(TryCount<20){
		disable_PDM();
		enable_PDM();	//sample start

		SampleCount = pPDM->SmpleCountReg;
		while(SampleCount<CaribSmplCount){
			SampleCount=pPDM->SmpleCountReg;
			vTaskDelay( 1/portTICK_PERIOD_MS);
		}
		disable_PDM();	//sample end




		//各CHの現在の平均値を求める。
		for(ch=0;ch<MIC_CH_MAX;ch++){
				Max[ch]=0;
				for(sum[ch]=0,SampleCount=0;SampleCount<CaribSmplCount;SampleCount++){
				snsdata = pPDMDATA->Data[ch][SampleCount];
				if (Max[ch]<abs(snsdata)){
					Max[ch]=abs(snsdata);
				}

				sum[ch] += snsdata;
			}
			avg[ch] = (float)sum[ch] / CaribSmplCount;
		}

		for(flag=0,ch=0;ch<MIC_CH_MAX;ch++){
			average=avg[ch];
			if(	fabsf(average) > OffsetMargin ){	//オフセット値がマージンに収まっていない
//				delta=(int16_t)(avg[ch]/79.78);
//				delta=(int16_t)(avg[ch]/9.97);
				delta=(int16_t)(avg[ch]/CoeffOfstCncl);
				Setteichi = pPDM->OffsetCansel[ch];
				Setteichi -= delta;
				pPDM->OffsetCansel[ch] = Setteichi;
				flag++;
			}
		}
		if (flag==0){
			return 0;
		}
		else{
			TryCount++;
		}
	}
	return -1;
}


void getMicData(int SampleCount){

#define	CaribSmplCount	4096
#define	OffsetMargin	100.0

	volatile int Count;

	disable_PDM();
	enable_PDM();	//sample start

	Count = pPDM->SmpleCountReg;
	while(Count<SampleCount){
		Count=pPDM->SmpleCountReg;
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}
	disable_PDM();	//sample end
}

int setMicGain( uint8_t gain){

	if (gain>=8){
		return -1;
	}


	CoeffOfstCncl	= FIRGAIN/ pow(2,(12-gain));

	pPDM->GainReg=gain;
	return 0;
}

int setSampleFreq( uint8_t Freq){

	if ((Freq==0)||(Freq==1)){
		pPDM->ModeReg =(uint32_t)Freq;
		return 0;
	}
	return -1;
}


