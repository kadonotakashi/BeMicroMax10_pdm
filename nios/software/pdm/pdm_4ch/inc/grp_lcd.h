/*
 * grp_lcd.h
 *
 *  Created on: 2017/10/06
 *      Author: 13539
 */

#ifndef GRP_LCD_H_
#define GRP_LCD_H_


//#define	SSD1331
#define	ILI9341

#include "stdint.h"
#include "../src/AdafruitFonts/AdafruitFont.h"

#ifdef ILI9341

#include "ILI9341_nios.h"
#define	IMGWIDTH_MAX ILI9341_IMG_WIDTH
#define	IMGHEIGHT_MAX ILI9341_IMG_HEIGHT
#define	GLCD_IMG_HEIGHT	ILI9341_IMG_HEIGHT
#define	GLCD_IMG_WIDTH	ILI9341_IMG_WIDTH

#else
#include "ssd1331.h"
#define	IMGWIDTH_MAX SSD1331_IMG_WIDTH
#define	IMGHEIGHT_MAX SSD1331_IMG_HEIGHT
#endif


//STM32CUBEMX‚Ìfont—¬—p
//FontSize‚ÌŽw’è
#define	FNT12	0
#define	FNT16	1
#define	FNT20	2
#define	FNT24	3

uint16_t encodeRGB565(uint8_t RED,uint8_t GREEN,uint8_t BLUE);
int glcd_Init(uint16_t color);
int glcd_PointSet(uint16_t x,uint16_t y,uint16_t color);
int glcd_drawLine(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t color);
int glcd_drawHline(uint16_t x,uint16_t y,uint16_t length,uint16_t color);
int glcd_drawVline(uint16_t x,uint16_t y,uint16_t length,uint16_t color);
int glcd_drawRectangle(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t color);
int glcd_drawRectangleFill(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t line_color,uint16_t fill_color);
int glcd_BitBLT(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t *pSRC);
int glcd_put_string_fixed(int x,int y,char *string,uint16_t CharColor,int FontSize);
int glcd_put_string_Adafruit(int x,int y,char *string,uint16_t CharColor,int FontSel);
int put_charPattern_Adafruit(char CharCode,uint16_t CHAR_COLOR,uint16_t xs,uint16_t ys,int FontSel);

#endif /* GRP_LCD_H_ */
