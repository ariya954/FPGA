#include "globals.h"

extern volatile unsigned char byte1, byte2, byte3, copy_byte1, copy_byte2, copy_byte3;
int count=0; int flag;

/***************************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine checks which KEY has been pressed. If it is KEY1 or KEY2, it writes this 
 * value to the global variable key_pressed. If it is KEY3 then it loads the SW switch 
 * values and stores in the variable pattern
****************************************************************************************/
void PS2_ISR(struct alt_up_dev *up_dev, unsigned int id)
{
	unsigned char PS2_data;

	/* check for PS/2 data--display on HEX displays */
	if (alt_up_ps2_read_data_byte (up_dev->PS2_dev, &PS2_data) == 0)
	{
		/* allows save the last three bytes of data */
		copy_byte1 = copy_byte2;
		copy_byte2 = copy_byte3;
		copy_byte3 = PS2_data;

		if(count > 0){
			if(count != 4){
				count++;
			}
			if(count == 4){
				byte1 = copy_byte1;
				byte2 = copy_byte2;
				byte3 = copy_byte3;
			}
		}
		if(count == 0){
			if ( (copy_byte2 == (unsigned char) 0xAA) && (copy_byte3 == (unsigned char) 0x00) ){
					// mouse inserted; initialize sending of data
					(void) alt_up_ps2_write_data_byte_with_ack (up_dev->PS2_dev, (unsigned char) 0xF4);
					count = 1;
			}
		}


	}
	return;
}
