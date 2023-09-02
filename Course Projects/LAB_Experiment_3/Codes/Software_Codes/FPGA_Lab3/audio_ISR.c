#include "globals.h"

/* globals used for audio record/playback */
extern volatile int buf_index_record, buf_index_play;
unsigned int record_l_buf[BUF_SIZE];					// audio record buffer
unsigned int record_r_buf[BUF_SIZE];					// audio record buffer
unsigned int play_l_buf[BUF_SIZE];						// audio play buffer
unsigned int play_r_buf[BUF_SIZE];						// audio play buffer

/***************************************************************************************
 * Audio - Interrupt Service Routine                                
 *                                                                          
 * This interrupt service routine records or plays back audio, depending on which type
 * interrupt (read or write) is pending in the audio device.
****************************************************************************************/
void audio_ISR(struct alt_up_dev *up_dev, unsigned int id)
{
	int num_read; int num_written;

	unsigned int fifospace;
		
	if (alt_up_audio_read_interrupt_pending(up_dev->audio_dev))	// check for read interrupt
	{
		alt_up_parallel_port_write_data (up_dev->green_LEDs_dev, 0x1); // set LEDG[0] on

		// store data until the buffer is full
		if (buf_index_record < BUF_SIZE)
		{
			//printf("record is runnig...\n");
			num_read = alt_up_audio_record_r (up_dev->audio_dev, &(record_r_buf[buf_index_record]),
				BUF_SIZE - buf_index_record);
			/* assume we can read same # words from the left and right */
			(void) alt_up_audio_record_l (up_dev->audio_dev, &(record_l_buf[buf_index_record]),
				num_read);
			buf_index_record += num_read;
			//printf("buf_index_record: %d\n", buf_index_record);
			if (buf_index_record >= BUF_SIZE)
			{
				// done recording
				buf_index_record = 0;
				alt_up_parallel_port_write_data (up_dev->green_LEDs_dev, 0); // turn off LEDG
				alt_up_audio_disable_read_interrupt(up_dev->audio_dev);
			}
		}
	}
	if (alt_up_audio_write_interrupt_pending(up_dev->audio_dev))	// check for write interrupt
	{
		alt_up_parallel_port_write_data (up_dev->green_LEDs_dev, 0x4); // set LEDG[2] on

		// output data until the buffer is empty 
		if (buf_index_play < BUF_SIZE)
		{
			num_written = alt_up_audio_play_r (up_dev->audio_dev, &(play_r_buf[buf_index_play]),
			 	BUF_SIZE - buf_index_play);
			/* assume that we can write the same # words to the left and right */
			(void) alt_up_audio_play_l (up_dev->audio_dev, &(play_l_buf[buf_index_play]),
				num_written);
			buf_index_play += num_written;
			//printf("buf_index_play: %d\n", buf_index_play);

			if (buf_index_play >= BUF_SIZE)
			{
				// done playback
				printf("done playing");
				buf_index_play = 0;
				alt_up_parallel_port_write_data (up_dev->green_LEDs_dev, 0); // turn off LEDG
				alt_up_audio_disable_write_interrupt(up_dev->audio_dev);
			}
		}
	}
	return;
}
