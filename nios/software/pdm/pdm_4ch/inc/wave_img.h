/*
 * wave_img.h
 *
 *  Created on: 2019/05/30
 *      Author: 13539
 */

#ifndef INC_WAVE_IMG_H_
#define INC_WAVE_IMG_H_

#include "stdint.h"



typedef struct{
	uint16_t BMP[200][256];
}DISP_BUF;


int DispWaveImg(DISP_BUF *pDISPBUF,int mode,int Vscale,int Hscale);
#endif /* INC_WAVE_IMG_H_ */
