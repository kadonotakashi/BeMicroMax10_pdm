/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

#include "taskdef.h"

#include "lcd_que.h"

xQueueHandle SendReqQue;
xQueueHandle ButtonQue;
xQueueHandle GLCD_QUE;

xQueueHandle SnsorQue;




int main()
{
	//Queue
	SnsorQue = xQueueCreate(4,sizeof(int));
	SendReqQue = xQueueCreate(4,sizeof(int));
	ButtonQue = xQueueCreate(4,sizeof(char));
	GLCD_QUE = xQueueCreate(32,sizeof(GRAP_LCD_QUE));

	//main only create 7 scheduling  TASK
	xTaskCreate( task_com, "TK_COM", configMINIMAL_STACK_SIZE, NULL, TK_COM_PRIORITY, NULL );
	xTaskCreate( task_sns, "TK_SNS", configMINIMAL_STACK_SIZE, NULL, TK_SNS_PRIORITY, NULL );
	xTaskCreate( task_button, "TK_BUTTON", configMINIMAL_STACK_SIZE, NULL, TK_MAIN_PRIORITY, NULL );
	xTaskCreate( task_main, "TK_MAIN", configMINIMAL_STACK_SIZE, NULL, TK_MAIN_PRIORITY, NULL );
	xTaskCreate( task_disp, "TK_DISP", configMINIMAL_STACK_SIZE, NULL, TK_DISP_PRIORITY, NULL );

	vTaskStartScheduler();
	while(1){}



}
