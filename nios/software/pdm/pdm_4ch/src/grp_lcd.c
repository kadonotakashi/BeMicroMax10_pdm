/*
 * grlcd.c
 *
 *  Created on: 2017/10/06
 *      Author: 13539
 */

#include "grp_lcd.h"
#include "./FONT/fonts.h"

extern FontList	FntList[NumOfFont];

uint16_t encodeRGB565(uint8_t RED,uint8_t GREEN,uint8_t BLUE){
	uint16_t TEMP=0;

	TEMP += (RED&0xf8)<<8;
	TEMP += (GREEN&0xfC)<<3;
	TEMP += (BLUE&0xf8)>>3;
	return TEMP;
}

int glcd_Init(uint16_t color){

	LoadFont();


#ifdef SSD1331
	init_SSD1331();
	return 0;
#endif
#ifdef ILI9341
	init_9341(color);
	return 0;
#endif
#ifdef ILI9481
	init_ILI9481(color);
	return 0;
#endif
	return -2;
}



int glcd_PointSet(uint16_t x,uint16_t y,uint16_t color){

#ifdef SSD1331
	pset16_SSD1331((uint8_t) x, (uint8_t) y, color);
	return 0;
#endif
#ifdef ILI9341
	Pset_9341(x,y,color);
	return 0;
#endif
#ifdef ILI9481
	PSET_ILI9481(x,y,color);
	return 0;
#endif
	return -2;

}

int glcd_drawLine(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t color){

#ifdef SSD1331
	line16_SSD1331(	(uint8_t) xs,(uint8_t) ys,(uint8_t)xe,	(uint8_t)ye,color);
	return 0;
#endif
#ifdef ILI9341
	drawLine_9341(xs,ys,xe,ye,color);
	return 0;
#endif
#ifdef ILI9481
	LINE_ILI9481(xs,ys,xe,ye,color);
	return 0;
#endif

	return -2;
}


int glcd_drawHline(uint16_t x,uint16_t y,uint16_t length,uint16_t color){

#ifdef SSD1331
	line16_SSD1331(	(uint8_t) x,(uint8_t) y,(uint8_t) length,	(uint8_t) y,color);
	return 0;
#endif
#ifdef ILI9341
	drawHline_9341(x,y,length,color);
	return 0;
#endif
#ifdef ILI9481
	HLINE_ILI9481(x,y,length,color);
	return 0;
#endif
	return -2;
}

int glcd_drawVline(uint16_t x,uint16_t y,uint16_t length,uint16_t color){

#ifdef SSD1331
	line16_SSD1331(	(uint8_t) x,(uint8_t) y,(uint8_t) x,(uint8_t) length,color);
	return 0;
#endif
#ifdef ILI9341
	drawVline_9341(x,y,length,color);
#endif
#ifdef ILI9481
	VLINE_ILI9481(x,y,length,color);
	return 0;
#endif
	return -2;
}

int glcd_drawRectangle(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t color){

#ifdef SSD1331
	Rectangle16_SSD1331((uint8_t)xs,(uint8_t)ys,(uint8_t)xe,(uint8_t)ye, color	);
	return 0;
#endif
#ifdef ILI9341
	 Box_9341(xs,ys,xe,ye,color);
	return 0;
#endif
#ifdef ILI9481
	Rectangle_ILI9481(xs,xe,ys,ye,color);
	return 0;
#endif
	return -2;
}

int glcd_drawRectangleFill(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t line_color,uint16_t fill_color){

#ifdef SSD1331
	RectangleFill16_SSD1331((uint8_t)xs,(uint8_t)ys,(uint8_t)xe,(uint8_t)ye, line_color,fill_color	);
	return 0;
#endif
#ifdef ILI9341
	Rectangle_9341(xs,xe,ys,ye,fill_color);
	 Box_9341(xs,ys,xe,ye,line_color);

#endif
	return -2;
}

int glcd_BitBLT(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t *pSRC)
{
#ifdef SSD1331
	BitBLT16_SSD1331((uint8_t) xs,(uint8_t) ys,	(uint8_t) xe,(uint8_t) ye,pSRC	);
	return 0;
#endif
#ifdef ILI9341
	BitBlt_9341(xs,xe,ys,ye,pSRC);
	return 0;
#endif
#ifdef ILI9481
	BitBlt_ILI9481(xs,xe,ys,ye,pSRC);
#endif
	return -2;
}


int put_charPattern(char CharCode,uint16_t CHAR_COLOR,uint16_t xs,uint16_t ys,int FontSize)
{

	uint8_t *pFNT;
	uint32_t LINE_PATTERN;
	int x,y;
	int FontWidth,FontHeight,FontCap,byte_line;

	if ((CharCode>0x7e)||(CharCode<0x20))
		return -1;

	//Font�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽSTM�ｿｽ�ｽｿ�ｽｽ�ｾ鯉ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽC�ｿｽ�ｽｿ�ｽｽu�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｾ峨▽繧托ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｾ�繧托ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｾ後ｑ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽg�ｿｽ�ｽｿ�ｽｽp
	if(FontSize==FNT12){	//font12,w=7,h=12
		FontWidth=Font12.Width;
		FontHeight=Font12.Height;
		pFNT=(uint8_t *)Font12.table;
		FontCap=12;
		byte_line=1;
	}
	else if(FontSize==FNT16){
		FontWidth=Font16.Width;
		FontHeight=Font16.Height;
		pFNT=(uint8_t *)Font16.table;
		FontCap=32;
		byte_line=2;
	}
	else if(FontSize==FNT20){
		FontWidth=Font20.Width;
		FontHeight=Font20.Height;
		pFNT=(uint8_t *)Font20.table;
		FontCap=40;
		byte_line=2;
	}
	else if(FontSize==FNT24){
		FontWidth=Font24.Width;
		FontHeight=Font24.Height;
		pFNT=(uint8_t *)Font24.table;
		FontCap=72;
		byte_line=3;
	}else{
		return -1;
	}

	pFNT += ((CharCode-' ')*FontCap);		//�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽp�ｿｽ�ｽｿ�ｽｽ^�ｿｽ�ｽｿ�ｽｽ[�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ'�ｿｽ�ｽｿ�ｽｽX�ｿｽ�ｽｿ�ｽｽy�ｿｽ�ｽｿ�ｽｽ[�ｿｽ�ｽｿ�ｽｽX '(0x20)�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ隰ｫ�ｽｪ
	for(y=ys;y<ys+FontHeight;y++){

		LINE_PATTERN = (*pFNT) * 0x1000000 + *(pFNT+1) * 0x10000 + *(pFNT+2) * 0x100 + *(pFNT+3);
		for(x=xs;x<FontWidth+xs;x++){
			if(LINE_PATTERN & 0x80000000){
#ifdef SSD1331
				pset16_SSD1331((uint8_t)x, (uint8_t)y,CHAR_COLOR);
#endif
#ifdef ILI9341
				Pset_9341(x,y,CHAR_COLOR);
#endif;
#ifdef ILI9481
				PSET_ILI9481(x,y,CHAR_COLOR);
#endif;
			}
			LINE_PATTERN=LINE_PATTERN<<1;
		}
		pFNT+=byte_line;
	}


	return 0;
}


int glcd_put_string_fixed(int x,int y,char *string,uint16_t CharColor,int FontSize)
{
	int i,j;
	char *STR;

	int FontWidth,FontHeight;

	//Font�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽSTM�ｿｽ�ｽｿ�ｽｽ�ｾ鯉ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽC�ｿｽ�ｽｿ�ｽｽu�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｾ峨▽繧托ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｾ�繧托ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｾ後ｑ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽg�ｿｽ�ｽｿ�ｽｽp
	if(FontSize==FNT12){	//font12,w=7,h=12
		FontWidth=Font12.Width;
		FontHeight=Font12.Height;
	}
	else if(FontSize==FNT16){
		FontWidth=Font16.Width;
		FontHeight=Font16.Height;
	}
	else if(FontSize==FNT20){
		FontWidth=Font20.Width;
		FontHeight=Font20.Height;
	}
	else if(FontSize==FNT24){
		FontWidth=Font24.Width;
		FontHeight=Font24.Height;
	}
	else{
		return -1;
	}

	if((x<0) || (x + FontWidth>GLCD_IMG_WIDTH)){
		return -1;
	}
	if((y<0) ||(y+FontHeight>GLCD_IMG_HEIGHT)){
		return -1;
	}

	STR = (char *)string;

	for(i=0,j=x;;i++,j+=FontWidth,STR++){
		if (j>GLCD_IMG_WIDTH-1- FontWidth){
			return -1;
		}
		if (*STR==0){
			return 0;	//�ｿｽ�ｽｿ�ｽｽw�ｿｽ�ｽｿ�ｽｽ髢ｧ�ｽｳ�ｿｽ�ｽｿ�ｽｽ鮟ｷ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｾ檎ｵゑｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ
		}
		if ((*STR>0x7f)||(*STR<0x20)){
			return -2;
		}
		put_charPattern(*STR,CharColor,j,y,FontSize);
	}
	return 0;
}

/*
 * Adafruit Font Library
 * */
int put_charPattern_Adafruit(char CharCode,uint16_t CHAR_COLOR,uint16_t xs,uint16_t ys,int FontSel)
{
	uint8_t FirstCode,char_offset;
	uint8_t *pFNT;

	int x,y;
	int FontWidth,FontHeight,FontDotCap,bitCnt;
	int xOffset,yOffset;
	uint8_t LinePattern;
	int BitCount;

	FirstCode = FntList[FontSel].pFnt->first;
	if ((CharCode > FntList[FontSel].pFnt->last)||(CharCode < FirstCode)){
		return -1;
	}

	char_offset=(CharCode - FirstCode);
	pFNT = FntList[FontSel].pFnt->bitmap;
	pFNT += FntList[FontSel].pFnt->glyph[char_offset].bitmapOffset;

	FontWidth = FntList[FontSel].pFnt->glyph[char_offset].width;
	FontHeight = FntList[FontSel].pFnt->glyph[char_offset].height;
	FontDotCap = FontWidth * FontHeight;

	xOffset = FntList[FontSel].pFnt->glyph[char_offset].xOffset;
	yOffset = FntList[FontSel].pFnt->glyph[char_offset].yOffset;

	x=0;
	y=0;
	BitCount=8;

	for(bitCnt=0;bitCnt<FontDotCap;bitCnt++){
		if (8==BitCount){
			LinePattern = *pFNT++;
			BitCount=0;
		}
		if((LinePattern & 0x80)!=0){
#ifdef ILI9341
			Pset_9341(x+xs+xOffset,y+ys+yOffset,CHAR_COLOR);
#endif
#ifdef ILI9481
			PSET_ILI9481(x+xs+xOffset,y+ys+yOffset,CHAR_COLOR);
#endif
		}else{
			 //back
		}

		LinePattern = LinePattern<<1;

		if(x>=FontWidth-1){
			x=0;	y++;
		}else{
			x++;
		}
		BitCount++;
	}
	return FntList[FontSel].pFnt->glyph[char_offset].xAdvance;
}

int glcd_put_string_Adafruit(int x,int y,char *string,uint16_t CharColor,int FontSel)
{
	int i,j,k;
	char *STR;

	if((x<0) || (x > GLCD_IMG_WIDTH)){
		return -1;
	}
	if((y<0) ||(y > GLCD_IMG_HEIGHT)){
		return -1;
	}

	STR = (char *)string;

	for(j=x;;STR++){

		if (*STR==0){
			return 0;
		}
		if (j>GLCD_IMG_WIDTH){
			return 0;
		}

		k=put_charPattern_Adafruit(*STR,CharColor,j,y,FontSel);
		if(k<0){
			return -2;
		}else{
			j=j+k;
		}
	}
	return 0;
}
