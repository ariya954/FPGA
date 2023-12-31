#include "globals.h"
#include "sys/alt_timestamp.h"
#include "system.h"

/* these globals are written by interrupt service routines; we have to declare
 * these as volatile to avoid the compiler caching their values in registers */
extern volatile unsigned char byte1, byte2, byte3, copy_byte1, copy_byte2, copy_byte3;	/* modified by PS/2 interrupt service routine */
extern volatile int timeout;							// used to synchronize with the timer
extern int count;
extern volatile unsigned int record_l_buf[BUF_SIZE];					// audio record buffer
extern volatile unsigned int record_r_buf[BUF_SIZE];					// audio record buffer
extern volatile unsigned int play_l_buf[BUF_SIZE];						// audio play buffer
extern volatile unsigned int play_r_buf[BUF_SIZE];
extern struct alt_up_dev up_dev;							/* pointer to struct that holds pointers to


																		open devices */

// mouse variables
int echo = 0;
volatile int flag_denoise, flag_play;
volatile int left_button_click, right_button_click, middle_button_click;
volatile int x_mouse, prev_x_mouse, y_mouse, prev_y_mouse, max_x_mouse, max_y_mouse;
volatile int prev_x_mouse_back, prev_x_mouse_front, prev_y_mouse_back, prev_y_mouse_front;
volatile int mouse_width = 0.3;
volatile int number_of_coefficients = 64;
float denoise_filter_coefficients[] = {
		-0.0019989013671875,
		-0.0050506591796875,
		-0.008331298828125,
		-0.0105438232421875,
		-0.0092926025390625,
		-0.0046539306640625,
		 0.0021209716796875,
		 0.0072174072265625,
		 0.0078125,
		 0.0027618408203125,
		-0.004852294921875,
		-0.0102081298828125,
		-0.008819580078125,
		-0.0006866455078125,
		 0.0095977783203125,
		 0.0146331787109375,
		 0.009735107421875,
		-0.0036163330078125,
		-0.0170440673828125,
		-0.0205535888671875,
		-0.009063720703125,
		 0.01220703125,
		 0.0296478271484375,
		 0.028717041015625,
		 0.00469970703125,
		-0.031494140625,
		-0.056121826171875,
		-0.0446319580078125,
		 0.013763427734375,
		 0.106964111328125,
		 0.2028656005859375,
		 0.2635040283203125,
		 0.2635040283203125,
		 0.2028656005859375,
		 0.106964111328125,
		 0.013763427734375,
		-0.0446319580078125,
		-0.056121826171875,
		-0.031494140625,
		 0.00469970703125,
		 0.028717041015625,
		 0.0296478271484375,
		 0.01220703125,
		-0.009063720703125,
		-0.0205535888671875,
		-0.0170440673828125,
		-0.0036163330078125,
		 0.009735107421875,
		 0.0146331787109375,
		 0.0095977783203125,
		-0.0006866455078125,
		-0.008819580078125,
		-0.0102081298828125,
		-0.004852294921875,
		 0.0027618408203125,
		 0.0078125,
		 0.0072174072265625,
		 0.0021209716796875,
		-0.0046539306640625,
		-0.0092926025390625,
		-0.0105438232421875,
		-0.008331298828125,
		-0.0050506591796875,
		-0.0019989013671875,
};

/* function prototypes */
void HEX_PS2(unsigned char, unsigned char, unsigned char);
void denoise_the_noisy_sound();
void PS2_Init(alt_up_ps2_dev *);
void show_mouse_buttons_states_on_Red_LEDs(unsigned char);
void echo_maker(unsigned int[], unsigned int[], unsigned int*, unsigned int*);
alt_u8 check_for_click(unsigned int, unsigned int, unsigned int, unsigned int);
void check_KEYs(int *, int *, int *, int *, alt_up_parallel_port_dev *, alt_up_audio_dev *);
void print_mouse_on_given_position(alt_up_pixel_buffer_dma_dev *, unsigned int, unsigned int);
void erase_previous_mouse_position(alt_up_pixel_buffer_dma_dev *, alt_up_char_buffer_dev *);
void print_screen(alt_up_pixel_buffer_dma_dev *, alt_up_char_buffer_dev *);
void interval_timer_ISR(void *, unsigned int);
//void pushbutton_ISR(void *, unsigned int);
void audio_ISR(void *, unsigned int);
void PS2_ISR(void *, unsigned int);
void setMouseBounds(unsigned int, unsigned int);
void getMouseState();

/********************************************************************************
 * This program demonstrates use of the media ports in the DE2 Media Computer
 *
 * It performs the following:
 *  	1. records audio for about 10 seconds when an interrupt is generated by
 *  	   pressing KEY[1]. LEDG[0] is lit while recording. Audio recording is
 *  	   controlled by using interrupts
 * 	2. plays the recorded audio when an interrupt is generated by pressing
 * 	   KEY[2]. LEDG[1] is lit while playing. Audio playback is controlled by
 * 	   using interrupts
 * 	3. Draws a blue box on the VGA display, and places a text string inside
 * 	   the box. Also, moves the word ALTERA around the display, "bouncing" off
 * 	   the blue box and screen edges
 * 	4. Shows a text message on the LCD display, and scrolls the message
 * 	5. Displays the last three bytes of data received from the PS/2 port
 * 	   on the HEX displays on the DE2 board. The PS/2 port is handled using
 * 	   interrupts
 * 	6. The speed of scrolling the LCD display and of refreshing the VGA screen
 * 	   are controlled by interrupts from the interval timer
********************************************************************************/
int main(void)
{
	/* declare device driver pointers for devices */
	alt_up_parallel_port_dev *KEY_dev;
	alt_up_parallel_port_dev *green_LEDs_dev;
	alt_up_parallel_port_dev *red_LEDs_dev;
	alt_up_ps2_dev *PS2_dev;
	alt_up_character_lcd_dev *lcd_dev;
	alt_up_audio_dev *audio_dev;
	alt_up_char_buffer_dev *char_buffer_dev;
	alt_up_pixel_buffer_dma_dev *pixel_buffer_dev;
	/* declare volatile pointer for interval timer, which does not have HAL functions */
	volatile int * interval_timer_ptr = (int *) 0x10002000;	// interval timer base address

	/* initialize some variables */
	byte1 = 0; byte2 = 0; byte3 = 0;
	copy_byte1 = 0; copy_byte2 = 0; copy_byte3 = 0;// used to hold PS/2 data
	timeout = 0;										// synchronize with the timer
	count = 0;
	flag_denoise = 0; flag_play = 0;

	x_mouse = 0; y_mouse = 0;                       // first mouse position is (0,0)
	setMouseBounds(319, 239);                   // screen size is 319 * 239
	prev_x_mouse_front = x_mouse;
	prev_y_mouse_front = y_mouse;
	prev_x_mouse_back = x_mouse;
	prev_y_mouse_back = y_mouse;
	prev_x_mouse = prev_x_mouse_front;
	prev_y_mouse = prev_y_mouse_front;

	/* these variables are used for the VGA screen */
	int ALT_x1; int ALT_x2; int ALT_y;
	int ALT_inc_x; int ALT_inc_y;
	int blue_x1; int blue_y1; int blue_x2; int blue_y2;
	int screen_x; int screen_y; int char_buffer_x; int char_buffer_y;
	short color; short trans_color = 0x1863;
	alt_u8 buffer_type = 1;

	// variables for Play, Record and Echo boxes on VGA screen
	int y1_boxes = 26; int y2_boxes = 34;
	int x1_box_record = 8; int x2_box_record = 26;
	int x1_box_play = 30; int x2_box_play = 48;
	int x1_box_echo = 52; int x2_box_echo = 70;
	int play = 0; int record = 0;  int denoise = 0;

	// variables for audio buffer
	int buffer_index = 0;
	unsigned int left_buf[BUF_SIZE];
	unsigned int right_buf[BUF_SIZE];
	unsigned int echo_left_buf[BUF_SIZE];
	unsigned int echo_right_buf[BUF_SIZE];
	int num_read; int num_written;

	/* set the interval timer period for scrolling the HEX displays */
	int counter = 0x960000;				// 1/(50 MHz) x (0x960000) ~= 200 msec
	*(interval_timer_ptr + 0x2) = (counter & 0xFFFF);
	*(interval_timer_ptr + 0x3) = (counter >> 16) & 0xFFFF;

	/* start interval timer, enable its interrupts */
	*(interval_timer_ptr + 1) = 0x7;	// STOP = 0, START = 1, CONT = 1, ITO = 1


	// open the pushbutton KEY parallel port
	KEY_dev = alt_up_parallel_port_open_dev ("/dev/Pushbuttons");
	if ( KEY_dev == NULL)
	{
		alt_printf ("Error: could not open pushbutton KEY device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened pushbutton KEY device\n");
		up_dev.KEY_dev = KEY_dev;	// store for use by ISRs
	}
	/* write to the pushbutton interrupt mask register, and set 3 mask bits to 1
	 * (bit 0 is Nios II reset) */
	alt_up_parallel_port_set_interrupt_mask (KEY_dev, 0xE);

	// open the green LEDs parallel port
	green_LEDs_dev = alt_up_parallel_port_open_dev ("/dev/Green_LEDs");
	if ( green_LEDs_dev == NULL)
	{
		alt_printf ("Error: could not open green LEDs device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened green LEDs device\n");
		up_dev.green_LEDs_dev = green_LEDs_dev;	// store for use by ISRs
	}

	// open the red LEDs parallel port
	red_LEDs_dev = alt_up_parallel_port_open_dev ("/dev/Red_LEDs");
	if ( red_LEDs_dev == NULL)
	{
		alt_printf ("Error: could not open red LEDs device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened red LEDs device\n");
		up_dev.red_LEDs_dev = red_LEDs_dev;	// store for use by ISRs
	}

	// open the PS2 port
	PS2_dev = alt_up_ps2_open_dev ("/dev/PS2_Port");
	if ( PS2_dev == NULL)
	{
		alt_printf ("Error: could not open PS2 device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened PS2 device\n");
		up_dev.PS2_dev = PS2_dev;	// store for use by ISRs
	}
	(void) alt_up_ps2_write_data_byte (PS2_dev, 0xFF);		// reset
	alt_up_ps2_enable_read_interrupt (PS2_dev); // enable interrupts from PS/2 port

	// open the audio port
	audio_dev = alt_up_audio_open_dev ("/dev/Audio");
	if ( audio_dev == NULL)
	{
		alt_printf ("Error: could not open audio device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened audio device\n");
		up_dev.audio_dev = audio_dev;	// store for use by ISRs
	}

	// open the 16x2 character display port
	lcd_dev = alt_up_character_lcd_open_dev ("/dev/Char_LCD_16x2");
	if ( lcd_dev == NULL)
	{
		alt_printf ("Error: could not open character LCD device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened character LCD device\n");
		up_dev.lcd_dev = lcd_dev;	// store for use by ISRs
	}

	/* use the HAL facility for registering interrupt service routines. */
	/* Note: we are passing a pointer to up_dev to each ISR (using the context argument) as
	 * a way of giving the ISR a pointer to every open device. This is useful because some of the
	 * ISRs need to access more than just one device (e.g. the pushbutton ISR accesses both
	 * the pushbutton device and the audio device) */
	alt_irq_register (0, (void *) &up_dev, (void *) interval_timer_ISR);
	//alt_irq_register (1, (void *) &up_dev, (void *) pushbutton_ISR);
	alt_irq_register (6, (void *) &up_dev, (void *) audio_ISR);
	alt_irq_register (7, (void *) &up_dev, (void *) PS2_ISR);

	/* create a messages to be displayed on the VGA and LCD displays */
	char text_top_LCD[80] = "Welcome to the DE2 Media Computer...\0";
	char text_top_VGA[20] = "Altera DE2\0";
	char text_bottom_VGA[20] = "Media Computer\0";
	char text_ALTERA[10] = "ALTERA\0";
	char text_erase[10] = "      \0";

	/* output text message to the LCD */
	alt_up_character_lcd_set_cursor_pos (lcd_dev, 0, 0);	// set LCD cursor location to top row
	alt_up_character_lcd_string (lcd_dev, text_top_LCD);
	alt_up_character_lcd_cursor_off (lcd_dev);				// turn off the LCD cursor

	/* open the pixel buffer */
	pixel_buffer_dev = alt_up_pixel_buffer_dma_open_dev ("/dev/VGA_Pixel_Buffer");
	if ( pixel_buffer_dev == NULL)
		alt_printf ("Error: could not open pixel buffer device\n");
	else
		alt_printf ("Opened pixel buffer device\n");

	/* the following variables give the size of the pixel buffer */
/*	screen_x = 319; screen_y = 239;
	color = 0x1863;		// a dark grey color
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, 0, 0, screen_x,
		screen_y, color, 0); // fill the screen

	// draw a medium-blue box in the middle of the screen, using character buffer coordinates
	blue_x1 = 28; blue_x2 = 52; blue_y1 = 26; blue_y2 = 34;
	// character coords * 4 since characters are 4 x 4 pixel buffer coords (8 x 8 VGA coords)
	color = 0x187F;		// a medium blue color
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue_x1 * 4, blue_y1 * 4, blue_x2 * 4,
		blue_y2 * 4, color, 0);
*/
	/* output text message in the middle of the VGA monitor */
	char_buffer_dev = alt_up_char_buffer_open_dev ("/dev/VGA_Char_Buffer");
	if ( char_buffer_dev == NULL)
		alt_printf ("Error: could not open character buffer device\n");
	else
		alt_printf ("Opened character buffer device\n");

/*	alt_up_char_buffer_string (char_buffer_dev, text_top_VGA, blue_x1 + 5, blue_y1 + 3);
	alt_up_char_buffer_string (char_buffer_dev, text_bottom_VGA, blue_x1 + 5, blue_y1 + 4);

	char_buffer_x = 79; char_buffer_y = 59;
	ALT_x1 = 0; ALT_x2 = 5/* ALTERA = 6 chars /; ALT_y = 0; ALT_inc_x = 1; ALT_inc_y = 1;
	alt_up_char_buffer_string (char_buffer_dev, text_ALTERA, ALT_x1, ALT_y);
*/
	print_screen(pixel_buffer_dev, char_buffer_dev);
	//PS2_Init(PS2_dev);

	/* this loops "bounces" the word ALTERA around on the VGA screen */
	while (1)
	{
		//while (!timeout)
		//	;	// wait to synchronize with timeout, which is set by the interval timer ISR
/*
		if(byte2 > 0 || byte3 > 0)
		{
			erase_previous_mouse_position(pixel_buffer_dev, char_buffer_dev);
		}

*/		if(count == 4){
			getMouseState();
			alt_up_pixel_buffer_dma_draw_box(pixel_buffer_dev, prev_x_mouse, prev_y_mouse,
						prev_x_mouse + mouse_width, prev_y_mouse + mouse_width, trans_color, buffer_type);

			alt_up_pixel_buffer_dma_draw_box(pixel_buffer_dev, x_mouse, y_mouse,
						x_mouse + mouse_width, y_mouse + mouse_width, 0xFFFFFFFF,
						buffer_type);                                //medium blue

					//alt_up_pixel_buffer_dma_swap_buffers(pixel_buffer_dev);

					//buffer_type = 1 - buffer_type; //toggle back and front buffer

			prev_x_mouse = x_mouse;
			prev_y_mouse = y_mouse;
			//byte1 = 0; byte2 = 0; byte3 = 0;
			count = 1;
        }

		// check if either KEY1 or KEY2 is pressed for record and play
        check_KEYs(&record, &flag_play, &flag_denoise, &buffer_index, KEY_dev, audio_dev);
/*
		if (record)
		{
			while (!alt_up_audio_read_interrupt_pending(up_dev.audio_dev)){}	// check for read interrupt
			printf("record is running\n");
			alt_up_parallel_port_write_data(green_LEDs_dev, 0x1); // set LEDG[0] on

			// record data until the buffer is full
			if (buffer_index < BUF_SIZE)
			{
				num_read = alt_up_audio_record_r(audio_dev, &(right_buf[buffer_index]),
					BUF_SIZE - buffer_index);

				(void)alt_up_audio_record_l(audio_dev, &(left_buf[buffer_index]),
					num_read);
				buffer_index += num_read;
				printf("num:%d\n", buffer_index);

				if (buffer_index >= BUF_SIZE)
				{
					printf("done record\n");
					// done recording
					buffer_index = 0;
					record = 0;
					alt_up_parallel_port_write_data(green_LEDs_dev, 0x0); // set LEDG off
					//echo =1;
				}
			}
		}
		else if (play)
		{
			printf("play is running\n");
			alt_up_parallel_port_write_data(green_LEDs_dev, 0x2); // set LEDG[1] on

			// output data until the buffer is empty
			if (buffer_index < BUF_SIZE)
			{
				num_written = alt_up_audio_play_r(audio_dev, &(right_buf[buffer_index]),
					BUF_SIZE - buffer_index);

				(void)alt_up_audio_play_l(audio_dev, &(left_buf[buffer_index]),
					num_written);
				buffer_index += num_written;

				if (buffer_index == BUF_SIZE)
				{
					printf("done play\n");
					// done playback
					buffer_index = 0;
					play = 0;
					alt_up_parallel_port_write_data(green_LEDs_dev, 0x0); // set LEDG off
				}
			}
		}
		else if (echo) {

			printf("echo is running\n");
			alt_up_parallel_port_write_data(green_LEDs_dev, 0x4); // set LEDG[2] on

			// output data until the buffer is empty
			if (buffer_index < BUF_SIZE)
			{
				num_written = alt_up_audio_play_r(audio_dev, &(echo_right_buf[buffer_index]),
					BUF_SIZE - buffer_index);

				(void)alt_up_audio_play_l(audio_dev, &(echo_left_buf[buffer_index]),
					num_written);
				buffer_index += num_written;

				if (buffer_index == BUF_SIZE)
				{
					printf("done echo\n");
					// done playback
					buffer_index = 0;
					echo = 0;
					alt_up_parallel_port_write_data(green_LEDs_dev, 0x0); // set LEDG off
				}
			}
		}
		else if (denoise) {

			while (!alt_up_audio_write_interrupt_pending(up_dev.audio_dev)){}	// check for write interrupt
			//echo_maker(left_buf, right_buf, echo_left_buf, echo_right_buf);
			printf("denoise is running\n");
			alt_up_parallel_port_write_data(green_LEDs_dev, 0x4); // set LEDG[2] on

			// output data until the buffer is empty
			if (buffer_index < BUF_SIZE)
			{
				num_written = alt_up_audio_play_r(audio_dev, &(right_buf[buffer_index]),
					BUF_SIZE - buffer_index);

				(void)alt_up_audio_play_l(audio_dev, &(left_buf[buffer_index]),
					num_written);
				buffer_index += num_written;

				if (buffer_index >= BUF_SIZE)
				{
					printf("done denoise\n");
					// done playback
					buffer_index = 0;
					play = 0;
					alt_up_parallel_port_write_data(green_LEDs_dev, 0x0); // set LEDG off
				}
			}

		}
*/
		//print_mouse_on_given_position(pixel_buffer_dev, mouse_x, mouse_y);

		/* move the ALTERA text around on the VGA screen */
		/*alt_up_char_buffer_string (char_buffer_dev, text_erase, ALT_x1, ALT_y); // erase
		ALT_x1 += ALT_inc_x;
		ALT_x2 += ALT_inc_x;
		ALT_y += ALT_inc_y;

		if ( (ALT_y == char_buffer_y) || (ALT_y == 0) )
			ALT_inc_y = -(ALT_inc_y);
		if ( (ALT_x2 == char_buffer_x) || (ALT_x1 == 0) )
			ALT_inc_x = -(ALT_inc_x);

		if ( (ALT_y >= blue_y1 - 1) && (ALT_y <= blue_y2 + 1) )
		{
			if ( ((ALT_x1 >= blue_x1 - 1) && (ALT_x1 <= blue_x2 + 1)) ||
				((ALT_x2 >= blue_x1 - 1) && (ALT_x2 <= blue_x2 + 1)) )
			{
				if ( (ALT_y == (blue_y1 - 1)) || (ALT_y == (blue_y2 + 1)) )
					ALT_inc_y = -(ALT_inc_y);
				else
					ALT_inc_x = -(ALT_inc_x);
			}
		}
		alt_up_char_buffer_string (char_buffer_dev, text_ALTERA, ALT_x1, ALT_y);
*/
		/* also, display any PS/2 data (from its interrupt service routine) on HEX displays */

		//VGA screen update
		if((byte2 > 0 || byte3 > 0))
		//if(x_mouse != prev_x_mouse && y_mouse != prev_y_mouse)
		{
			//count = (count == 2) ? 0 : count + 1;
			//if(count == 1){


			//}
					/*if (buffer_type) {
						prev_x_mouse_front = x_mouse;
						prev_y_mouse_front = y_mouse;
						prev_x_mouse = prev_x_mouse_back;
						prev_y_mouse = prev_y_mouse_back;
					} else {
						prev_x_mouse_back = x_mouse;
						prev_y_mouse_back = y_mouse;
						prev_x_mouse = prev_x_mouse_front;
						prev_y_mouse = prev_y_mouse_front;
					}*/
		}

		// check if either Record, Play or Echo box is clicked
		if(check_for_click(x1_box_record, x2_box_record, y1_boxes, y2_boxes)){
			record = 1;
		}
		if(check_for_click(x1_box_play, x2_box_play, y1_boxes, y2_boxes)){
			play = 1;
		}
		if(check_for_click(x1_box_echo, x2_box_echo, y1_boxes, y2_boxes)){
			echo = 1;
		}

		HEX_PS2 (byte1, byte2, byte3);
		show_mouse_buttons_states_on_Red_LEDs (byte1);
		timeout = 0;
	}
}

/****************************************************************************************
 * Subroutine to show a string of HEX data on the HEX displays
 * Note that we are using pointer accesses for the HEX displays parallel port. We could
 * also use the HAL functions for these ports instead
****************************************************************************************/
void HEX_PS2(unsigned char b1, unsigned char b2, unsigned char b3)
{
	volatile int *HEX3_HEX0_ptr = (int *) 0x10000020;
	volatile int *HEX7_HEX4_ptr = (int *) 0x10000030;

	/* SEVEN_SEGMENT_DECODE_TABLE gives the on/off settings for all segments in
	 * a single 7-seg display in the DE2 Media Computer, for the hex digits 0 - F */
	unsigned char	seven_seg_decode_table[] = {	0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07,
		  										0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71 };
	unsigned char	hex_segs[] = { 0, 0, 0, 0, 0, 0, 0, 0 };
	unsigned int shift_buffer, nibble;
	unsigned char code;
	int i;

	shift_buffer = (b1 << 16) | (b2 << 8) | b3;
	for ( i = 0; i < 6; ++i )
	{
		nibble = shift_buffer & 0x0000000F;		// character is in rightmost nibble
		code = seven_seg_decode_table[nibble];
		hex_segs[i] = code;
		shift_buffer = shift_buffer >> 4;
	}
	/* drive the hex displays */
	*(HEX3_HEX0_ptr) = *(int *) (hex_segs);
	*(HEX7_HEX4_ptr) = *(int *) (hex_segs+4);
}
void PS2_Init(alt_up_ps2_dev *PS2_dev)
{
	unsigned char PS2_data;

	/* check for PS/2 data--display on HEX displays */
	if (alt_up_ps2_read_data_byte (PS2_dev, &PS2_data) == 0)
	{
		/* allows save the last three bytes of data */
		byte1 = byte2;
		byte2 = byte3;
		byte3 = PS2_data;

		if ( (byte2 == (unsigned char) 0xAA) && (byte3 == (unsigned char) 0x00) )
			// mouse inserted; initialize sending of data
			(void) alt_up_ps2_write_data_byte (PS2_dev, (unsigned char) 0xF4);
	}
	return;
}
void show_mouse_buttons_states_on_Red_LEDs(unsigned char b1)
{
	/* writing mouse buttons states on Red LEDs 1, 2 and 3 */

	if(b1 % 2){ /* left button is in b1[0] */
		alt_up_parallel_port_write_data (up_dev.red_LEDs_dev, 0x4);
	}

	if((b1 >> 1) % 2){ /* right button is in b1[1] */
		alt_up_parallel_port_write_data (up_dev.red_LEDs_dev, 0x1);
	}

	if((b1 >> 2) % 2){ /* middle button is in b1[2] */
		alt_up_parallel_port_write_data (up_dev.red_LEDs_dev, 0x2);
	}

    if((b1 != 12) && (b1 != 10) && (b1 != 9)){
		alt_up_parallel_port_write_data (up_dev.red_LEDs_dev, 0);
	}

}
alt_u8 check_for_click(unsigned int start_x_region, unsigned int end_x_region, unsigned int start_y_region, unsigned int end_y_region) {
	if (left_button_click && x_mouse > start_x_region && x_mouse < end_x_region
			&& y_mouse > start_y_region && y_mouse < end_y_region) {
		return 1;
	} else {
		return 0;
	}
}
void check_KEYs(int* KEY1, int* KEY2, int* KEY3, int* counter, alt_up_parallel_port_dev* KEY_dev, alt_up_audio_dev* audio_dev)
{
	int KEY_value;

	KEY_value = alt_up_parallel_port_read_data(KEY_dev);

	while (alt_up_parallel_port_read_data(KEY_dev));	// wait for pushbutton KEY release

	if (KEY_value == 0x2)					// check KEY1
	{
		// reset counter to start recording
		*counter = 0;
		alt_up_audio_reset_audio_core(audio_dev);
		alt_up_audio_enable_read_interrupt (audio_dev);
		*KEY1 = 1;

	}
	else if (KEY_value == 0x4)				// check KEY2
	{
		// reset counter to start playback
		*counter = 0;
		alt_up_audio_reset_audio_core(audio_dev);
		flag_play = 1;
		alt_up_audio_enable_write_interrupt (audio_dev);
	}
	else if (KEY_value == 0x8)				// check KEY3
	{

		// reset counter to start playback
		*counter = 0;
		alt_up_audio_reset_audio_core(audio_dev);
		alt_timestamp_start();

		int j = 0;
		int k = 0;
		for(j = 0; j < BUF_SIZE; j++){
			play_r_buf[j] = ALT_CI_FIR_FILTER_0(record_r_buf[j]);
		}
		for(k = 0; k < BUF_SIZE; k++){
			play_l_buf[k] = ALT_CI_FIR_FILTER_0(record_l_buf[k]);
		}
		printf("Time taken to remove noise from the noisy sound was %3.f seconds\n", (float)alt_timestamp() / (float)alt_timestamp_freq());
		flag_denoise = 1;
		alt_up_audio_enable_write_interrupt (audio_dev);
	}
}
void print_mouse_on_given_position(alt_up_pixel_buffer_dma_dev *pixel_buffer_dev, unsigned int x_mouse, unsigned int y_mouse)
{
	/* printing a white square on mouse position*/
	int color = 0xFFFFFFFF; /* 1 = white */
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x_mouse * 4, y_mouse * 4, (x_mouse + mouse_width) * 4,
		(y_mouse + mouse_width) * 4, color, 0);
}
void erase_previous_mouse_position(alt_up_pixel_buffer_dma_dev *pixel_buffer_dev, alt_up_char_buffer_dev *char_buffer_dev)
{
	int x1, x2, y1, y2, color;

	if(8 <= x_mouse && x_mouse <= 26 && 26 <= y_mouse && y_mouse <= 34)
	{
		// draw a box in the left of the screen, using character buffer coordinates
		x1 = 8; x2 = 26; y1 = 26; y2 = 34;
		// character coords * 4 since characters are 4 x 4 pixel buffer coords (8 x 8 VGA coords)
		color = 0x187F;		// a medium blue color
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x1 * 4, y1 * 4, x2 * 4,
			y2 * 4, color, 0);
		alt_up_char_buffer_string (char_buffer_dev, "Record", x1 + 6, y1 + 4);
	}
	else if(30 <= x_mouse && x_mouse <= 48 && 26 <= y_mouse && y_mouse <= 34)
	{
		// draw a box in the left of the screen, using character buffer coordinates
		x1 = 8; x2 = 26; y1 = 26; y2 = 34;
		// character coords * 4 since characters are 4 x 4 pixel buffer coords (8 x 8 VGA coords)
		color = 0x187F;		// a medium blue color
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x1 * 4, y1 * 4, x2 * 4,
			y2 * 4, color, 0);
		alt_up_char_buffer_string (char_buffer_dev, "Play", x1 + 6, y1 + 4);
	}
	else if(52 <= x_mouse && x_mouse <= 70 && 26 <= y_mouse && y_mouse <= 34)
	{
		// draw a box in the left of the screen, using character buffer coordinates
		x1 = 8; x2 = 26; y1 = 26; y2 = 34;
		// character coords * 4 since characters are 4 x 4 pixel buffer coords (8 x 8 VGA coords)
		color = 0x187F;		// a medium blue color
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x1 * 4, y1 * 4, x2 * 4,
			y2 * 4, color, 0);
		alt_up_char_buffer_string (char_buffer_dev, "Echo", x1 + 7, y1 + 4);
	}
	else
	{
		color = 0x1863;		// fill the screen with a dark grey color
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x_mouse, y_mouse, x_mouse + 0.3,
				y_mouse + 0.3, color, 0);
	}

}
void setMouseBounds(unsigned int x_max, unsigned int y_max)
{
	max_x_mouse = x_max;
	max_y_mouse = y_max;
}
void getMouseState()
{
	left_button_click = byte1 % 2; /* left button is in byte1[0] */
	right_button_click = (byte1  >> 1) % 2; /* right button is in byte1[0] */
	middle_button_click = (byte1 >> 2) % 2; /* middle button is in byte1[0] */

	/* x_sign is in byte1[4], 0 = + and 1 = - */
	int x_sign = ((byte1 >> 4) % 2) ? 1 : 0;
	//x_mouse = x_mouse + byte2;
	x_mouse = !x_sign ? x_mouse + (( byte2)) : x_mouse - (( byte2)); /* x_difference is in byte2 */
	x_mouse = (x_mouse >= max_x_mouse) ? max_x_mouse :
			  (x_mouse <= 0) ? 0 :
			   x_mouse;

	/* y_sign is in byte1[5], 0 = + and 1 = - */
	int y_sign = ((byte1 >> 5) % 2) ? 1 : 0;
	//y_mouse = y_mouse + byte3;
	y_mouse = !y_sign ? y_mouse + (( byte3)) : y_mouse - ((( byte3 ))); /* y_difference is in byte3 */
	y_mouse = (y_mouse >= max_y_mouse) ? max_y_mouse :
			  (y_mouse <= 0) ? 0 :
			   y_mouse;
}
void print_screen(alt_up_pixel_buffer_dma_dev *pixel_buffer_dev, alt_up_char_buffer_dev *char_buffer_dev)
{
	int x1, x2, y1, y2;
	int color = 0x1863;		// fill the screen with a dark grey color
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, 0, 0, max_x_mouse,
			max_y_mouse, color, 0);

	// draw Record, Play and Echo boxes in the left, middle and right of the screen

	// draw a box in the left of the screen, using character buffer coordinates
	x1 = 8; x2 = 26; y1 = 26; y2 = 34;
	// character coords * 4 since characters are 4 x 4 pixel buffer coords (8 x 8 VGA coords)
	color = 0x187F;		// a medium blue color
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x1 * 4, y1 * 4, x2 * 4,
		y2 * 4, color, 0);
	alt_up_char_buffer_string (char_buffer_dev, "Record", x1 + 6, y1 + 4);
	// draw a medium-blue box in the middle of the screen, using character buffer coordinates
	x1 = 30; x2 = 48;
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x1 * 4, y1 * 4, x2 * 4,
		y2 * 4, color, 0);
	alt_up_char_buffer_string (char_buffer_dev, "Play", x1 + 7, y1 + 4);
	// draw a medium-blue box in the right of the screen, using character buffer coordinates
	x1 = 52; x2 = 70;
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, x1 * 4, y1 * 4, x2 * 4,
		y2 * 4, color, 0);
	alt_up_char_buffer_string (char_buffer_dev, "Echo", x1 + 7, y1 + 4);
}
void denoise_the_noisy_sound()
{
	int n;
	for(n = 0; n < BUF_SIZE; n++)
	{
		//printf("%d\n", n);
		float result = 0;
		int k;
		for(k = 0; k <= n && k < number_of_coefficients; k++)
		{
			float record = (float)(record_r_buf[n - k] >> 8);
			float temp = denoise_filter_coefficients[k]  * (record / (2 ^ 23));
			result = result + temp;
		}
		play_l_buf[n] = (int)(result * (2 ^ 30));
		play_r_buf[n] = (int)(result * (2 ^ 30));
		//printf("%d\n", play_l_buf[n]);
	}
}
void echo_maker(unsigned int l_buf[], unsigned int r_buf[], unsigned int* echol_buf, unsigned int* echor_buf) {
	int i;
	for (i = 0; i < BUF_SIZE; ++i) {
		if (i >= ECHO_INDEX1) {
			if (i >= ECHO_INDEX2) {
				echol_buf[i] = l_buf[i] >> 1 + l_buf[i - ECHO_INDEX2] >> 2;
				echor_buf[i] = r_buf[i] >> 1 + r_buf[i - ECHO_INDEX2] >> 2;
			}
			else {
				echol_buf[i] = l_buf[i] >> 1 + l_buf[i - ECHO_INDEX1] >> 2;
				echor_buf[i] = r_buf[i] >> 1 + r_buf[i - ECHO_INDEX1] >> 2;
			}
		}
		else {
			echol_buf[i] = l_buf[i];
			echor_buf[i] = r_buf[i];
		}
	}
}
