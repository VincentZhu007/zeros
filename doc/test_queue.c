/*
 * test_queue.c
 *
 * 测试数组实现循环队列
 */

#include <stdio.h>
#include <string.h>

#define BUF_SIZE 16 // 必须是2的整次幂

struct myqueue {
	unsigned long head; // 下一个待存放的位置
	unsigned long tail; // 最早的有效数据位置
	unsigned char buf[BUF_SIZE];
};

/*
 * 要点：用位运算&来替代求余%
 */
/* 查询 */
#define INC(i) ((i) = ((i)+1) & (BUF_SIZE-1))
#define EMPTY(q) ((q).head == (q).tail) /* LEN(q) == 0 */
#define LEN(q) (((q).head - (q).tail) & (BUF_SIZE - 1)) /* 0~1023 */
#define LEFT(q) (((q).tail - (q).head - 1) & (BUF_SIZE - 1))
#define FULL(q) (LEN(q) == BUF_SIZE - 1) /* (!LEFT(q)) */
/* 操作 */
#define INIT(q) \
	{(q).head = (q).tail = 0;}
#define GETCH(q,c) \
	{(c) = (q).buf[(q).tail]; INC((q).tail);}
#define PUTCH(q,c) \
	{(q).buf[(q).head] = (c); INC((q).head);}

int main()
{
	struct  myqueue q;
	INIT(q);
	char s[] = "hello,world!";
	char d[1024];
	for (int i=0; i<=strlen(s); i++) {
		PUTCH(q, s[i]);
	}
	printf("len=%lu, left=%lu, head=%lu, tail=%lu\n", LEN(q), LEFT(q), q.head, q.tail);

	int j=0;
	while (LEN(q) > 10) {
		GETCH(q, d[j]);
		j++;
	}
	d[j] = '\0';
	// printf("%s\n", d);
	printf("len=%lu, left=%lu, head=%lu, tail=%lu\n", LEN(q), LEFT(q), q.head, q.tail);

	for (int i=0; i<=3; i++) {
		PUTCH(q, s[i]);
	}
	printf("len=%lu, left=%lu, head=%lu, tail=%lu\n", LEN(q), LEFT(q), q.head, q.tail);

	return 0;
}
