/*
 * lcd_que.h
 *
 *  Created on: 2017/11/23
 *      Author: Takashi
 */

#ifndef LCD_QUE_H_
#define LCD_QUE_H_

#define	GLCDCMD_INIT			0x0000
#define	GLCDCMD_PSET			0x0100
#define	GLCDCMD_LINE			0x1000
#define	GLCDCMD_VLINE			0x1100
#define	GLCDCMD_HLINE			0x1200
#define	GLCDCMD_RECT			0x2000
#define	GLCDCMD_RECT_FILL		0x2100
#define	GLCDCMD_BITBLT			0x3000
#define	GLCDCMD_PRINT_STRING	0x4000
#define	GLCDCMD_PRINT_STRING_ADA	0x4100
#define	GLCDCMD_DEBUGLOG		0x8000

typedef union{
	uint16_t	data[8];
	//16byte

	struct{
		uint16_t	CMD;	//=0x0000
		uint16_t	COLOR;	//
		//4byte
	}INIT;

	struct{
		uint16_t	CMD;	//=0x0100
		uint16_t	COLOR;	//
		uint16_t 	XS;		//
		uint16_t 	YS;		//
		//8byte
	}PSET;

	struct{
		uint16_t	CMD;	//=0x1000
		uint16_t	COLOR;	//
		uint16_t 	XS;		//
		uint16_t 	YS;		//
		uint16_t 	XE;		//
		uint16_t 	YE;		//
		//12byte
	}LINE;

	struct{
		uint16_t	CMD;	//=0x1100
		uint16_t	COLOR;	//
		uint16_t 	XS;		//
		uint16_t 	YS;		//
		uint16_t 	LENGTH;		//
		//10byte
	}VLINE;

	struct{
		uint16_t	CMD;	//=0x1200
		uint16_t	COLOR;	//
		uint16_t 	XS;		//
		uint16_t 	YS;		//
		uint16_t 	LENGTH;		//
		//10byte
	}HLINE;

	struct{
		uint16_t	CMD;	//=GLCDCMD_RECT
		uint16_t	COLOR;	//
		uint16_t 	XS;		//
		uint16_t 	YS;		//
		uint16_t 	XE;		//
		uint16_t 	YE;		//
		//12byte
	}RECT;

	struct{
		uint16_t	CMD;	//=GLCDCMD_RECT_FILL
		uint16_t	LINE_COLOR;	//
		uint16_t	FILL_COLOR;	//
		uint16_t 	XS;		//
		uint16_t 	YS;		//
		uint16_t 	XE;		//
		uint16_t 	YE;		//
		//14byte
	}RECT_FILL;

	struct{
		uint16_t	CMD;	//=GLCDCMD_PRINT_STRING
		uint16_t	COLOR;
		uint16_t	BACK;
		uint16_t 	XS;
		uint16_t 	YS;
		uint16_t 	FONT_SIZE;
		char	 	*str;
	}PRINT_STRING;
	//14byte

	struct{
		uint16_t	CMD;	//=GLCDCMD_PRINT_STRING
		uint16_t	COLOR;
		uint16_t	BACK;
		uint16_t 	XS;
		uint16_t 	YS;
		uint16_t 	FONT_SEL;
		char 		*str;
	}PRINT_STRING_ADA;
	//14byte

	struct{
		uint16_t	CMD;	//=GLCDCMD_BITBLT
		uint16_t 	XS;
		uint16_t 	YS;
		uint16_t 	XE;		//
		uint16_t 	YE;		//
		uint16_t 	*src;
	}BITBLT;
	//14byte

	struct{
		uint16_t	CMD;	//=GLCDCMD_BITBLT
		uint16_t	COLOR;	//=GLCDCMD_BITBLT
		uint8_t 	*pSTR;
	}DEBUG_LOG;


}GRAP_LCD_QUE;			//�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽv�ｿｽ�ｽｿ�ｽｽ@16byte


//�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽm�ｿｽ�ｽｿ�ｽｽN�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽOLED

#define	OLEDCMD_INIT			0x00
#define	OLEDCMD_RECT			0x01
#define	OLEDCMD_PRINT_STRING	0x02

typedef union{
	uint8_t	data[8];

	struct{
		uint8_t	CMD;	//=0
		uint8_t	MODE;	//
		uint8_t 	XS;		//
		uint8_t 	YS;		//
		uint8_t 	XE;		//
		uint8_t 	YE;		//
	}RECT;	//6byte

	struct{
		uint8_t	CMD;	//=1
		uint8_t	MODE;
		uint8_t XS;
		uint8_t YS;
		uint8_t *str;
	}PRINT_STRING;	//8byte

}OLED_QUE;			//�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽ�ｿｽ�ｽｿ�ｽｽv�ｿｽ�ｽｿ�ｽｽ@8byte


#endif /* LCD_QUE_H_ */
