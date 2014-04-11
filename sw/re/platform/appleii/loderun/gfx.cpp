#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>
#include <sys/stat.h>
#include <memory.h>

#include <allegro.h>

#define ALLEGRO_FULL_VERSION  ((ALLEGRO_VERSION << 4)|(ALLEGRO_SUB_VERSION))
#if ALLEGRO_FULL_VERSION < 0x42
  #define SS_TEXTOUT_CENTRE(s,f,str,w,h,c) \
    textout_centre (s, f, str, w, h, c);
#else
  #define SS_TEXTOUT_CENTRE(s,f,str,w,h,c) \
    textout_centre_ex(s, f, str, w, h, c, 0);
#endif

uint8_t ram[64*1024];

uint8_t title_data[] =
{
	#include "title.c"
};

uint8_t title_rle_data[] =
{
	#include "title_rle.c"
};
#define RLE_SIZE (sizeof(title_rle_data)/sizeof(uint8_t))

void main (int argc, char *argv[])
{
	struct stat	fs;
	int					fd;
	
	char				buf[1024];
	
	FILE *fp = fopen ("0f00.bin", "rb");
	if (!fp)
		exit (0);
	fd = fileno (fp);
	if (fstat	(fd, &fs))
		exit (0);
	fread (&ram[0x0f00], sizeof(uint8_t), fs.st_size, fp);
	fclose (fp);

	allegro_init ();
	install_keyboard ();

	set_color_depth (8);
	set_gfx_mode (GFX_AUTODETECT_WINDOWED, 280, 192, 0, 0);

	clear_bitmap (screen);

	uint16_t x = 0;
	uint8_t y = 0;
	uint16_t a = 0x0f00;
	
	while (y < 192)
	{
		int8_t byte = ram[a++];
		if (byte == 0)
		{
			y++;
			x = 0;
			continue;
		}
		if (byte > 0)
		{
			x = byte * 7;
			continue;
		}
		for (unsigned i=0; i<7; i++)
		{
			if (byte & (1<<i))
				putpixel (screen, x, y, 15);
			x++;
		}
	}

	// converting to 8-bit
	fp = fopen ("title.c", "wt");
	for (y=0; y<192; y++)
	{
		for (x=0; x<280/8; x++)
		{
			uint8_t byte = 0;
			for (int i=0; i<8; i++)
			{
				if (getpixel (screen, x*8+i, y) != 0)
					byte |= (1<<(7-i));
			}
			fprintf (fp, "0x%02X,", byte);
		}
		fprintf (fp, "\n");
	}
	fclose (fp);
		
	clear_bitmap (screen);
	for (y=0; y<192; y++)
	{
		for (x=0; x<280/8; x++)
		{
			uint8_t byte = title_data[y*35+x];
			
			for (int i=0; i<8; i++)
				if (byte & (1<<(7-i)))
					putpixel (screen, x*8+i, y, 15);
		}
	}

	// now RLE it
	fp = fopen ("title_rle.c", "wt");

	int lc = 0;	
	int n = 0;
	while (n < 280/8*192)
	{
		unsigned cnt = 0;
		uint8_t byte = title_data[n];
		
		while (n<280/8*192 && (byte == title_data[n]) && cnt < 256)
		{
			cnt++;
			n++;
		}
		fprintf (fp, "0x%02X, 0x%02X, ", (uint8_t)cnt, byte);
		lc += 2;
		if (lc == 16)
		{
			fprintf (fp, "\n");
			lc = 0;
		}
	}
	fprintf (fp, "\n");
	fclose (fp);

	// now show the rle version
	clear_bitmap (screen);
	x = 0;
	y = 0;
	for (n=0; n<RLE_SIZE; n+=2)
	{
		unsigned cnt = title_rle_data[n];
		uint8_t byte = title_rle_data[n+1];
		
		if (cnt == 0)
			cnt+= 256;

		while (cnt--)
		{
			for (int i=0; i<8; i++)
			{
				if (byte & (1<<(7-i)))
					putpixel (screen, x*8+i, y, 15);
			}
			x++;
			if (x == 280/8)
			{
				x = 0;
				y++;
			}
		}
	}

  while (!key[KEY_ESC]);	  
  while (key[KEY_ESC]);	  
	  
  allegro_exit ();
  printf ("original=%d\n", a-0x0f00);
  printf ("280/8*192=%d\n", 280/8*192);
  printf ("RLE_SIZE=%d\n", RLE_SIZE);
}

END_OF_MAIN();
