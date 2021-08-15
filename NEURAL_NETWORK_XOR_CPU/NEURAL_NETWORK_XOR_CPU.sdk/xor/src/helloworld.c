#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xbasic_types.h"
#include "xparameters.h"
#include "xtime_l.h"

Xuint32 *baseaddr_p = (Xuint32 *)XPAR_XOR_IP_0_S00_AXI_BASEADDR;

void print_all_reg(){
	xil_printf("---------------------------\n");
	for(int i = 0; i < 31;i++){
		xil_printf("REG %d: 0x%08x \n", i , *(baseaddr_p+i));
	}
	xil_printf("---------------------------\n");
}

int main()
{
    init_platform();
    XTime tStart, tEnd;
    print("Solving XOR problem with neural network\n");
    print("Learning...\n");
    //print_all_reg();
    XTime_GetTime(&tStart);
    *(baseaddr_p+0) = 0x00000000;
    //INPUTS
    *(baseaddr_p+1) = 0x00000000;
    *(baseaddr_p+2) = 0x00000100;
    *(baseaddr_p+3) = 0x01000000;
    *(baseaddr_p+4) = 0x01000100;

    //GOALS
    *(baseaddr_p+5) = 0x00000000;
    *(baseaddr_p+6) = 0x01000000;
    *(baseaddr_p+7) = 0x01000000;
    *(baseaddr_p+8) = 0x00000000;

    //MIN ERROR -1 AND MAX EPOCH 100000
    *(baseaddr_p+11) = 0xFFFF2710;

    //INIT WEIGHTS
    *(baseaddr_p+13) = 0x12345612;
    *(baseaddr_p+14) = 0x30000000;
    *(baseaddr_p+15) = 0x00000000;
    *(baseaddr_p+16) = 0x00000000;

    //SAVE LEARN WITHOUT RAM INIT
    *(baseaddr_p+0) = 0x02000004;
    *(baseaddr_p+0) = 0x02000006;

    //ENABLE AND WAIT FOR DONE_LEARNIGN
    *(baseaddr_p+0) = 0x00000001;
    while(*(baseaddr_p+9) == 0x00000000){};
    XTime_GetTime(&tEnd);
    printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
        printf("Output took %.2f us.\n",
               1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));

    print_all_reg();
    //*(baseaddr_p+9) = 0x00000000;
    print("Done learning!\n");

    print("Start testing!\n");
    //LEARNING DONE, GO TO TEST PHASE
    *(baseaddr_p+0) = 0x00000000;
    *(baseaddr_p+1) = 0x00000000;
    *(baseaddr_p+0) = 0x00000002;
    *(baseaddr_p+0) = 0x00000001;
	while(*(baseaddr_p+9) == 0x00000000){};
	xil_printf("%d: 0x%08x \n", 1 , *(baseaddr_p+10));

	*(baseaddr_p+0) = 0x00000000;
    *(baseaddr_p+1) = 0x00000100;
    *(baseaddr_p+0) = 0x00000002;
    *(baseaddr_p+0) = 0x00000001;
	while(*(baseaddr_p+9) == 0x00000000){};
	xil_printf("%d: 0x%08x \n", 1 , *(baseaddr_p+10));

	*(baseaddr_p+0) = 0x00000000;
    *(baseaddr_p+1) = 0x01000000;
    *(baseaddr_p+0) = 0x00000002;
    *(baseaddr_p+0) = 0x00000001;
	while(*(baseaddr_p+9) == 0x00000000){};
	xil_printf("%d: 0x%08x \n", 1 , *(baseaddr_p+10));

	*(baseaddr_p+0) = 0x00000000;
    *(baseaddr_p+1) = 0x01000100;
    *(baseaddr_p+0) = 0x00000002;
    *(baseaddr_p+0) = 0x00000001;
	while(*(baseaddr_p+9) == 0x00000000){};
	xil_printf("%d: 0x%08x \n", 1 , *(baseaddr_p+10));


	print("Done testing!\n");
    cleanup_platform();
    return 0;
}
