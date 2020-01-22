/*
 * test_read.c
 *
 * 测试读取磁盘的逻辑
 */

#include <stdio.h>

#define SYSSIZE	0x3000 // 最大192KB
#define SYSSEG	0x1000
#define ENDSEG	(SYSSEG + SYSSIZE)

int sectors = 17;

volatile int es = SYSSEG;
volatile int bp = 0;

volatile int sread = 5;
volatile int track = 0;
volatile int head = 0;


void read_track(sector, count)
{
	printf("%04x:%04x    <-    [%3d, %3d, %3d ~ %3d, %3d, %3d],    cnt=%3d\n", 
			es, bp, track, head, sread+1, track, head, sread + count, count);
}

/* 
 * 读取磁盘中的system到内存
 *
 * dest: es:bp
 * src:  track, head, sector
 */
void rp_read()
{
	int count = 0;
	int count1, count2;
	while (es < ENDSEG) {
		count1 = sectors - sread;
		count2 = (0x10000 - bp) >> 9;
		count = count1 < count2 ? count1 : count2;

		read_track(sread + 1, count);
		
		// 更新dest
		bp += count << 9;
		if (bp == 0x10000) {
			es += 0x1000;
			bp = 0;
		}
		// 更新src
		sread =  sread + count;
		if (sread == sectors) {
			sread = 0;
			if (head == 0)
				head = 1;
			else {
				head = 0;
				track++;
			}
		}
	}
}

int main()
{
	// 打印信息
	printf("\nLoading System...\n\n");

	// 读取system到0x10000
	rp_read();

	return 0;
}
