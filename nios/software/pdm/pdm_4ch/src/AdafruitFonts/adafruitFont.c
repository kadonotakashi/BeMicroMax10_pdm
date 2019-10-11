/*
 * adafruitFont.c
 *
 *  Created on: 2018/09/24
 *      Author: takashi
 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>


#define PROGMEM		//for erase "PROGMA in Font File"
#include "AdafruitFont.h"

#include "./Fonts/FreeMono9pt7b.h"
#include "./Fonts/FreeMonoBold18pt7b.h"
#include "./Fonts/FreeSans18pt7b.h"
#include "./Fonts/FreeSerif18pt7b.h"



const uint8_t FreeMono9pt7bBitmaps[];
const GFXglyph FreeMono9pt7bGlyphs[];
const GFXfont FreeMono9pt7b;

const uint8_t FreeMonoBold18pt7bBitmaps[];
const GFXglyph FreeMonoBold18pt7bGlyphs[];
const GFXfont FreeMonoBold18pt7b;

const uint8_t FreeSans18pt7bBitmaps[];
const GFXglyph FreeSans18pt7bGlyphs[];
const GFXfont FreeSans18pt7b;

const uint8_t FreeSerif18pt7bBitmaps[];
const GFXglyph FreeSerif18pt7bGlyphs[];
const GFXfont FreeSerif18pt7b;


FontList	FntList[NumOfFont];


int LoadFont(void){

	int height,width;

	FntList[0].pFnt=(GFXfont *)&FreeMono9pt7b;
	strcpy(FntList[0].FontName,"Mono9pt7b\0");

	FntList[1].pFnt=(GFXfont *)&FreeMonoBold18pt7b;
	strcpy(FntList[1].FontName,"MonoBold18pt7b\0");

	FntList[2].pFnt=(GFXfont *)&FreeSans18pt7b;
	strcpy(FntList[2].FontName,"FreeSans18pt7b\0");

	FntList[3].pFnt=(GFXfont *)&FreeSerif18pt7b;
	strcpy(FntList[3].FontName,"FreeSerif18pt7b\0");


	return 2;
}
