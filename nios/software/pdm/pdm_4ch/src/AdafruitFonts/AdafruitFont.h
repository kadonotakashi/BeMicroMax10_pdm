/*
 * AdafruitFont.h
 *
 *  Created on: 2018/09/24
 *      Author: takashi
 */

#ifndef ADAFRUITFONT_H_
#define ADAFRUITFONT_H_

#include "gfxfont.h"

#define NumOfFont	4

typedef struct{
	GFXfont *pFnt;
	char FontName[16];
}FontList;


int LoadFont(void);



#endif /* ADAFRUITFONT_H_ */
