	/*
 * task_main.h
 *
 *  Created on: 2017/12/18
 *      Author: 13539
 */

#ifndef INC_TASKDEF_H_
#define INC_TASKDEF_H_

void task_main(void *pvParameters );
#define TK_MAIN_PRIORITY		( tskIDLE_PRIORITY + 1)

void task_button(void *pvParameters );
#define task_button_PRIORITY		( tskIDLE_PRIORITY + 2 )

void task_disp(void *pvParameters );
#define TK_DISP_PRIORITY		( tskIDLE_PRIORITY + 1)


void task_com(void *pvParameters );
#define TK_COM_PRIORITY		( tskIDLE_PRIORITY + 1)

void task_sns(void *pvParameters );
#define TK_SNS_PRIORITY		( tskIDLE_PRIORITY + 1)

#endif /* INC_TASKDEF_H_ */
