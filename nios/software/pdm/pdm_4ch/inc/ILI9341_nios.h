/*
 * ILI9341.h
 *
 *  Created on: 2017/09/04
 *      Author: 13539
 *
 *  This is our library for the Adafruit ILI9341 Breakout and Shield
 * 　　----> http://www.adafruit.com/products/1651
 *	を参考に修正した（2018/02/15）
 */

#ifndef ILI9341_H_
#define ILI9341_H_

#include <stdint.h>
#include "system.h"
#define PORTRAIT

//
//	FPGAに作りこんだILI9341パラレルインタフェースモジュール
//
//
typedef struct{
	volatile int	CMDreg;		//0x00
	volatile int	DATAreg;	//0x04
	volatile int	CTRLreg;	//0x08
	volatile int	DATA16reg;	//0x0c
}ILI9341mod;

#define	GrayModeBit	0x2;

//
//	PARARELLで接続するための定義 SPIも同じ
//
#define	pLCD_CMD_PORT		(*(volatile int*)(ILI9341SPI_BASE))		//
#define	pLCD_DATA_PORT		(*(volatile int*)(ILI9341SPI_BASE+4))		//
#define	pLCD_CTRL_PORT		(*(volatile int*)(ILI9341SPI_BASE+8))		//
#define	pLCD_DATA16_PORT	(*(volatile int*)(ILI9341SPI_BASE+12))		//

#define	LCD_RESET_LOW()		pLCD_CTRL_PORT=1
#define	LCD_RESET_HIGH()	pLCD_CTRL_PORT=0

#define	GRAY_MODE_ON()	pLCD_CTRL_PORT=GrayModeBit
#define	GRAY_MODE_OFF()	pLCD_CTRL_PORT&=0

#define CMD_MEMORY_ACCESS_CONTROL 0x36
#define CMD_COLMOD 0x3a

#define ILI9341_TFTWIDTH   240
#define ILI9341_TFTHEIGHT  320

#define ILI9341_NOP        0x00
#define ILI9341_SWRESET    0x01
#define ILI9341_RDDID      0x04
#define ILI9341_RDDST      0x09

#define ILI9341_SLPIN      0x10
#define ILI9341_SLPOUT     0x11
#define ILI9341_PTLON      0x12
#define ILI9341_NORON      0x13

#define ILI9341_RDMODE     0x0A
#define ILI9341_RDMADCTL   0x0B
#define ILI9341_RDPIXFMT   0x0C
#define ILI9341_RDIMGFMT   0x0D
#define ILI9341_RDSELFDIAG 0x0F

#define ILI9341_INVOFF     0x20
#define ILI9341_INVON      0x21
#define ILI9341_GAMMASET   0x26
#define ILI9341_DISPOFF    0x28
#define ILI9341_DISPON     0x29

#define ILI9341_CASET      0x2A
#define ILI9341_PASET      0x2B
#define ILI9341_RAMWR      0x2C
#define ILI9341_RAMRD      0x2E

#define ILI9341_PTLAR      0x30
#define ILI9341_MADCTL     0x36
#define ILI9341_VSCRSADD   0x37
#define ILI9341_PIXFMT     0x3A

#define ILI9341_FRMCTR1    0xB1
#define ILI9341_FRMCTR2    0xB2
#define ILI9341_FRMCTR3    0xB3
#define ILI9341_INVCTR     0xB4
#define ILI9341_DFUNCTR    0xB6

#define ILI9341_PWCTR1     0xC0
#define ILI9341_PWCTR2     0xC1
#define ILI9341_PWCTR3     0xC2
#define ILI9341_PWCTR4     0xC3
#define ILI9341_PWCTR5     0xC4
#define ILI9341_VMCTR1     0xC5
#define ILI9341_VMCTR2     0xC7

#define ILI9341_RDID1      0xDA
#define ILI9341_RDID2      0xDB
#define ILI9341_RDID3      0xDC
#define ILI9341_RDID4      0xDD

#define ILI9341_GMCTRP1    0xE0
#define ILI9341_GMCTRN1    0xE1

#define MAC_PORTRAIT 0xe8
#define MAC_LANDSCAPE 0x48
#define COLMOD_16BIT 0x55
#define COLMOD_18BIT 0x66

#if defined(PORTRAIT)
#define MAC_CONFIG MAC_PORTRAIT
#define ILI9341_IMG_WIDTH 320
#define ILI9341_IMG_HEIGHT 240
#else
# define MAC_CONFIG MAC_LANDSCAPE
# define WIDTH 240
# define HEIGHT 320
#endif

#define	RGB565_WHITE	0xffff
#define	RGB565_BLACK	0x0000
#define	RGB565_RED		0xf800
#define	RGB565_GREEN	0x07e0
#define	RGB565_BLUE		0x001f
#define	RGB565_MAGENTA	0xf81f
#define	RGB565_YELLOW	0xffe0
#define	RGB565_CYAN		0x07FF

int get_LCD_DMA_sts();
void init_LCD_DMA();
void start_LCD_DMA_BitBLT(int src_addr,int length);
void start_LCD_DMA_FILL(int src_addr,int length);
void start_LCD_DMA_BufferFill(int src_addr,int dst_addr,int length);

void init_9341(int16_t color);
int BitBlt_9341(uint16_t sx, uint16_t ex, uint16_t sy, uint16_t ey,uint16_t *data);
int BitBlt_9341_GRAY8(uint16_t sx, uint16_t ex, uint16_t sy, uint16_t ey,uint8_t *data);
int Rectangle_9341(uint16_t sx, uint16_t ex, uint16_t sy, uint16_t ey,uint16_t color);
int Pset_9341(uint16_t x, uint16_t y,uint16_t color);
void ClearScreen_9341(uint16_t color);
int drawVline_9341(uint16_t x,uint16_t y,uint16_t length,uint16_t color);
int drawLine_9341(uint16_t sx,uint16_t sy,uint16_t ex,uint16_t ey,uint16_t color);
int Box_9341(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t color);

#endif /* ILI9341_H_ */
