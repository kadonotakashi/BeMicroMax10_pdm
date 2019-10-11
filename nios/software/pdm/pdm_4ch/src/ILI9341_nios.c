/*
 * ILI9341.c for FPGA SPI
 *
 *  Created on: 2017/09/04
 *      Author: 13539
 */

#include "./FONT/fonts.h"
#include "FreeRTOS.h"
#include "task.h"

#include <stdlib.h>

#include "grp_lcd.h"
#include "system.h"
#include "dma.h"

#define	DATA16EXTENTION
#define LCD_DMA

#define	SPI_LCD_BASE	LCD_SPI_BASE

#define Write_Command_9341(cmd)	pLCD_CMD_PORT=cmd
#define Write_Data_9341(data)	pLCD_DATA_PORT=data
#define Write_Data16_9341(data)	pLCD_DATA16_PORT=data

ILI9341mod	*pILI9341 = (ILI9341mod *)ILI9341SPI_BASE;
DMAMOD *pLCD_DMA = (DMAMOD *)DMA_LCD_BASE;

int get_LCD_DMA_sts(){
	return pLCD_DMA->STATUSreg &_b_DMA_BUSY;
}


void init_LCD_DMA(){
	pLCD_DMA->CTRLreg = 	_b_DMA_SWRESET;	//soft reset
	pLCD_DMA->CTRLreg = 	0;	//soft reset

	pLCD_DMA->CTRLreg = 	_b_DMA_HW		//316bit only
						|	_b_DMA_WCON		//destination is fixed address;
						|	_b_DMA_LEEN	;	//
									//disable interrupt
}

void start_LCD_DMA_BitBLT(int src_addr,int length){
	pLCD_DMA->CTRLreg &= ~_b_DMA_GO;	//destination is fixed address;

	pLCD_DMA->CTRLreg |= 	_b_DMA_WCON;	//destination is fixed address;
	pLCD_DMA->CTRLreg &= 	~_b_DMA_RCON;	//RCON<=0 source address increment
	pLCD_DMA->RD_ADDRreg	= src_addr;
	pLCD_DMA->WR_ADDRreg	= (int)&pILI9341->DATA16reg;
	pLCD_DMA->LENGTHreg	= length;

	pLCD_DMA->CTRLreg |= 	_b_DMA_GO;	//destination is fixed address;
}

void start_LCD_DMA_FILL(int src_addr,int length){

	pLCD_DMA->CTRLreg &= ~_b_DMA_GO;	//destination is fixed address;

	pLCD_DMA->CTRLreg |= 	_b_DMA_WCON;	//destination is fixed address;
	pLCD_DMA->CTRLreg |= _b_DMA_RCON;	//RCON:1  source address constant

	pLCD_DMA->RD_ADDRreg	= src_addr;
	pLCD_DMA->WR_ADDRreg	= (int )&pILI9341->DATA16reg;
	pLCD_DMA->LENGTHreg	= length;


	pLCD_DMA->CTRLreg |= _b_DMA_GO;	//destination is fixed address;
}

void start_LCD_DMA_BufferFill(int src_addr,int dst_addr,int length){
	pLCD_DMA->CTRLreg &= ~_b_DMA_GO;	//destination is fixed address;

	pLCD_DMA->CTRLreg &=  ~_b_DMA_WCON;	//destination is fixed address;
	pLCD_DMA->CTRLreg |= _b_DMA_RCON;	//RCON:1  source address constant

	pLCD_DMA->RD_ADDRreg	= src_addr;
	pLCD_DMA->WR_ADDRreg	= dst_addr;
	pLCD_DMA->LENGTHreg	= length;

	pLCD_DMA->CTRLreg |= _b_DMA_GO;	//destination is fixed address;
}

void init_9341(int16_t color){

	init_LCD_DMA(pLCD_DMA);

	LCD_RESET_LOW();
	vTaskDelay( 10/ portTICK_PERIOD_MS);
	LCD_RESET_HIGH();
	vTaskDelay( 10/ portTICK_PERIOD_MS);

    Write_Command_9341(0xEF);
    Write_Data_9341(0x03);
    Write_Data_9341(0x80);
    Write_Data_9341(0x02);

    Write_Command_9341(0xCF);
    Write_Data_9341(0x00);
    Write_Data_9341(0XC1);
    Write_Data_9341(0X30);

    Write_Command_9341(0xED);
    Write_Data_9341(0x64);
    Write_Data_9341(0x03);
    Write_Data_9341(0X12);
    Write_Data_9341(0X81);

    Write_Command_9341(0xE8);
    Write_Data_9341(0x85);
    Write_Data_9341(0x00);
    Write_Data_9341(0x78);

    Write_Command_9341(0xCB);
    Write_Data_9341(0x39);
    Write_Data_9341(0x2C);
    Write_Data_9341(0x00);
    Write_Data_9341(0x34);
    Write_Data_9341(0x02);

    Write_Command_9341(0xF7);
    Write_Data_9341(0x20);

    Write_Command_9341(0xEA);
    Write_Data_9341(0x00);
    Write_Data_9341(0x00);

    Write_Command_9341(ILI9341_PWCTR1);    //Power control
    Write_Data_9341(0x23);   //VRH[5:0]

    Write_Command_9341(ILI9341_PWCTR2);    //Power control
    Write_Data_9341(0x10);   //SAP[2:0];BT[3:0]

    Write_Command_9341(ILI9341_VMCTR1);    //VCM control
    Write_Data_9341(0x3e);
    Write_Data_9341(0x28);

    Write_Command_9341(ILI9341_VMCTR2);    //VCM control2
    Write_Data_9341(0x86);  //--

    Write_Command_9341(ILI9341_MADCTL);    // Memory Access Control
    Write_Data_9341(MAC_PORTRAIT);

    Write_Command_9341(ILI9341_VSCRSADD); // Vertical scroll
    Write_Data_9341(0);                 // Zero

    Write_Command_9341(ILI9341_PIXFMT);
    Write_Data_9341(0x55);

    Write_Command_9341(ILI9341_FRMCTR1);
    Write_Data_9341(0x00);
    Write_Data_9341(0x18);

    Write_Command_9341(ILI9341_DFUNCTR);    // Display Function Control
    Write_Data_9341(0x08);
    Write_Data_9341(0x82);
    Write_Data_9341(0x27);

    Write_Command_9341(0xF2);    // 3Gamma Function Disable
    Write_Data_9341(0x00);

    Write_Command_9341(ILI9341_GAMMASET);    //Gamma curve selected
    Write_Data_9341(0x01);

    Write_Command_9341(ILI9341_GMCTRP1);    //Set Gamma
    Write_Data_9341(0x0F);
    Write_Data_9341(0x31);
    Write_Data_9341(0x2B);
    Write_Data_9341(0x0C);
    Write_Data_9341(0x0E);
    Write_Data_9341(0x08);
    Write_Data_9341(0x4E);
    Write_Data_9341(0xF1);
    Write_Data_9341(0x37);
    Write_Data_9341(0x07);
    Write_Data_9341(0x10);
    Write_Data_9341(0x03);
    Write_Data_9341(0x0E);
    Write_Data_9341(0x09);
    Write_Data_9341(0x00);

    Write_Command_9341(ILI9341_GMCTRN1);    //Set Gamma
    Write_Data_9341(0x00);
    Write_Data_9341(0x0E);
    Write_Data_9341(0x14);
    Write_Data_9341(0x03);
    Write_Data_9341(0x11);
    Write_Data_9341(0x07);
    Write_Data_9341(0x31);
    Write_Data_9341(0xC1);
    Write_Data_9341(0x48);
    Write_Data_9341(0x08);
    Write_Data_9341(0x0F);
    Write_Data_9341(0x0C);
    Write_Data_9341(0x31);
    Write_Data_9341(0x36);
    Write_Data_9341(0x0F);

    Write_Command_9341(ILI9341_SLPOUT);    //Exit Sleep
	vTaskDelay( 50/ portTICK_PERIOD_MS);
    Write_Command_9341(ILI9341_DISPON);    //Display on
	vTaskDelay( 50/ portTICK_PERIOD_MS);

	Rectangle_9341(0,319,0, 239,color);


	//    endWrite();
}


int BitBlt_9341(uint16_t sx, uint16_t ex, uint16_t sy, uint16_t ey,uint16_t *data) {
  // VRAM内の書き込み矩形領域を設定するとCMD_MEMORY_WRITEに続くデータがその領域内に書かれる

	int size,flag;
	int i;
	uint16_t *endp;
	uint16_t *sp;

	if((sx<0) ||(sx>ex) || (ex>=ILI9341_IMG_WIDTH)){
		return -1;
	}
	if((sy<0) ||(sy>ey) || (ey>=ILI9341_IMG_HEIGHT)){
		return -1;
	}

	sp=data;

#ifdef	DATA16EXTENTION
	GRAY_MODE_OFF();
	Write_Command_9341(ILI9341_CASET);
	Write_Data16_9341(sx);
	Write_Data16_9341(ex);

	Write_Command_9341(ILI9341_PASET);
	Write_Data16_9341(sy);
	Write_Data16_9341(ey);
	Write_Command_9341(ILI9341_RAMWR);

	endp=(ex-sx+1)*(ey-sy+1)+sp;
	size=(ex-sx+1)*(ey-sy+1);
#ifdef LCD_DMA
	start_LCD_DMA_BitBLT( (int)data, size*2);
	flag = get_LCD_DMA_sts();
	while (flag!=0){
		flag = get_LCD_DMA_sts();
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}

#else

	for(;sp<endp;i++,sp++){
		Write_Data16_9341(*sp);
	}
#endif
#else
	Write_Command_9341(ILI9341_CASET);
	Write_Data_9341((uint8_t)(sx>>8));
	Write_Data_9341((uint8_t)(sx&0xff));
	Write_Data_9341((uint8_t)(ex>>8));
	Write_Data_9341((uint8_t)(ex&0xff));

	Write_Command_9341(ILI9341_PASET);
	Write_Data_9341((uint8_t)(sy>>8));
	Write_Data_9341((uint8_t)(sy&0xff));
	Write_Data_9341((uint8_t)(ey>>8));
	Write_Data_9341((uint8_t)(ey&0xff));
	Write_Command_9341(ILI9341_RAMWR);

	for(i=0;i<(ex-sx+1)*(ey-sy+1);i++,sp++){

		Write_Data_9341(*sp>>8);
		Write_Data_9341((*sp) & 0xff);
	}
#endif
	return 0;
}

int BitBlt_9341_GRAY8(uint16_t sx, uint16_t ex, uint16_t sy, uint16_t ey,uint8_t *data) {
  // VRAM内の書き込み矩形領域を設定するとCMD_MEMORY_WRITEに続くデータがその領域内に書かれる

	int i;
	uint8_t *sp,*endp;

	if((sx<0) ||(sx>ex) || (ex>=ILI9341_IMG_WIDTH)){
		return -1;
	}
	if((sy<0) ||(sy>ey) || (ey>=ILI9341_IMG_HEIGHT)){
		return -1;
	}

	sp = (uint8_t *)data;

	Write_Command_9341(ILI9341_CASET);
	Write_Data16_9341(sx);
	Write_Data16_9341(ex);

	Write_Command_9341(ILI9341_PASET);
	Write_Data16_9341(sy);
	Write_Data16_9341(ey);
	Write_Command_9341(ILI9341_RAMWR);

	GRAY_MODE_ON();

	endp=(ex-sx+1)*(ey-sy+1)+sp;
	for(;sp<endp;i++,sp++){
		Write_Data16_9341(*sp);
	}
	return 0;
}


int Rectangle_9341(uint16_t sx, uint16_t ex, uint16_t sy, uint16_t ey,uint16_t color) {

	int size;
	volatile int flag;
	int loop_count;

	if((sx<0) ||(sx>ex) || (ex>=ILI9341_IMG_WIDTH)){
		return -1;
	}
	if((sy<0) ||(sy>ey) || (ey>=ILI9341_IMG_HEIGHT)){
		return -1;
	}
#ifdef	DATA16EXTENTION
	Write_Command_9341(ILI9341_CASET);
	Write_Data16_9341(sx);
	Write_Data16_9341(ex);

	Write_Command_9341(ILI9341_PASET);
	Write_Data16_9341(sy);
	Write_Data16_9341(ey);

	Write_Command_9341(ILI9341_RAMWR);
	size=(ex-sx+1)*(ey-sy+1);
#ifdef LCD_DMA
	start_LCD_DMA_FILL( (int)&color, size*2);
	loop_count=0;
	flag = get_LCD_DMA_sts();
	while (flag!=0){
		flag = get_LCD_DMA_sts();
		loop_count++;
		vTaskDelay( 1/portTICK_PERIOD_MS);
	}

#else
	for(;size>0;size--){
		Write_Data16_9341(color);
	}
#endif
#else
	Write_Command_9341(ILI9341_CASET);
	Write_Data_9341((uint8_t)(sx>>8));
	Write_Data_9341((uint8_t)(sx&0xff));
	Write_Data_9341((uint8_t)(ex>>8));
	Write_Data_9341((uint8_t)(ex&0xff));

	Write_Command_9341(ILI9341_PASET);
	Write_Data_9341((uint8_t)(sy>>8));
	Write_Data_9341((uint8_t)(sy&0xff));
	Write_Data_9341((uint8_t)(ey>>8));
	Write_Data_9341((uint8_t)(ey&0xff));

	Write_Command_9341(ILI9341_RAMWR);
	size=(ex-sx+1)*(ey-sy+1);

	for(;size>0;size--){
		Write_Data_9341((uint8_t)(color>>8));	//8bitずつ
		Write_Data_9341((uint8_t)( color & 0xff));	//8bitずつ
	}
#endif
	return 0;
}

int Pset_9341(uint16_t x, uint16_t y,uint16_t color) {
  // 点を打つ

	if((x<0) ||(x>=ILI9341_IMG_WIDTH)){		return -1;	}
	if((y<0) ||(y>=ILI9341_IMG_HEIGHT)){	return -1;	}
#ifdef	DATA16EXTENTION
	Write_Command_9341(ILI9341_CASET);
	Write_Data16_9341(x);
	Write_Data16_9341(x);

	Write_Command_9341(ILI9341_PASET);
	Write_Data16_9341(y);
	Write_Data16_9341(y);

	Write_Command_9341(ILI9341_RAMWR);
	Write_Data16_9341(color);
#else
	Write_Command_9341(ILI9341_CASET);
	Write_Data_9341((uint8_t)(x>>8));
	Write_Data_9341((uint8_t)(x&0xff));
	Write_Data_9341((uint8_t)(x>>8));
	Write_Data_9341((uint8_t)(x&0xff));

	Write_Command_9341(ILI9341_PASET);
	Write_Data_9341((uint8_t)(y>>8));
	Write_Data_9341((uint8_t)(y&0xff));
	Write_Data_9341((uint8_t)(y>>8));
	Write_Data_9341((uint8_t)(y&0xff));

	Write_Command_9341(ILI9341_RAMWR);

	Write_Data_9341((uint8_t)((color>>8)));	//8bitずつ
	Write_Data_9341((uint8_t)((color & 0xff)));	//8bitずつ
#endif
	return 0;
}


void ClearScreen_9341(uint16_t color) {
	Rectangle_9341(0,319, 0, 239,color);
}

int drawVline_9341(uint16_t x,uint16_t y,uint16_t length,uint16_t color){
	int i;

	for(i=0;i<length;i++){
		Pset_9341(x, y+i,color);
	}

	return 0;
}

int drawHline_9341(uint16_t x,uint16_t y,uint16_t length,uint16_t color){
	int i;

	for(i=0;i<length;i++){
		Pset_9341(x+i, y,color);
	}

	return 0;
}

int drawLine_9341(uint16_t sx,uint16_t sy,uint16_t ex,uint16_t ey,uint16_t color)
{
	float a,b;
	int x,y;


	if((sx<0)||(sx>=ILI9341_IMG_WIDTH))		return -1;
	if((sy<0)||(sy>=ILI9341_IMG_HEIGHT))	return -1;
	if((ex<0)||(ex>=ILI9341_IMG_WIDTH))		return -1;
	if((ey<0)||(ey>=ILI9341_IMG_HEIGHT))	return -1;

	if(sx==ex){
		if(sy<ey){
			drawVline_9341(sx,sy,(ey-sy+1),color);
		}
		else if(ey<sy){
			drawVline_9341(sx,ey,(sy-ey+1),color);
		}
		else{
			Pset_9341(sx,sy,color);
		}
	}

	if(sy==ey){
		if(sx<ex){
			drawHline_9341(sx,sy,(ex-sx+1),color);
		}
		else if(ex<sx){
			drawHline_9341(ex,sy,(sx-ex+1),color);
		}
		else{
			Pset_9341(sx,sy,color);
		}
	}

	if(abs(ex-sx)>abs(ey-sy))
	{	//y = ax + b
		b=(float)(sy*ex-ey*sx)/(float)(ex-sx);
		if(ex!=0){
			a=((float)ey-b)/(float)ex;
		}else{
			a=((float)sy-b)/(float)sx;
		}

		if (sx<ex){
			for(x=sx;x<=ex;x++){
				y=(int)(((x*a)+b)+0.5);
				Pset_9341(x,y,color);
			}
		}
		else{
			for(x=ex;x<=sx;x++){
				y=(int)(((x*a)+b)+0.5);
				Pset_9341(x,y,color);
			}

		}
	}else{
		//x = ay + b
		b=(float)(sx*ey-ex*sy)/(float)(ey-sy);
		if(ey!=0){
			a=((float)ex-b)/(float)ey;
		}else{
			a=((float)sx-b)/(float)sy;
		}
		if (sy<ey){
			for(y=sy;y<=ey;y++){
				x=(int)(((y*a)+b)+0.5);
				Pset_9341(x,y,color);
			}
		}
		else{
			for(y=ey;y<=sy;y++){
				x=(int)(((y*a)+b)+0.5);
				Pset_9341(x,y,color);
			}
		}
	}
	return 0;
}


int Box_9341(uint16_t xs,uint16_t ys, uint16_t xe,uint16_t ye,uint16_t color){

	drawVline_9341(xs,ys,(ye-ys+1),color);
	drawVline_9341(xe,ys,(ye-ys+1),color);
	drawHline_9341(xs,ys,(xe-xs+1),color);
	drawHline_9341(xs,ye,(xe-xs+1),color);
	return 0;
}

