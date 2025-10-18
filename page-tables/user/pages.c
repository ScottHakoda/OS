#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int 
main(int argc, char *argv[]) 
{
    if(argc < 2){
        printf("Usage: pages <pid>\n");
        exit(1);
    }
    int pid = atoi(argv[1]);
    int result = pages(pid);
    if (result == -1) {
        printf("Error: invalid PID or printing failed\n");
    }
    exit(0);
}