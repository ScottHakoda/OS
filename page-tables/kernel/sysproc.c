#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  kexit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return kfork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return kwait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
  argint(1, &t);
  addr = myproc()->sz;

  if(t == SBRK_EAGER || n < 0) {
    if(growproc(n) < 0) {
      return -1;
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
      return -1;
    myproc()->sz += n;
  }
  return addr;
}

uint64
sys_pause(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  if(n < 0)
    n = 0;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kkill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

void page_tree(int pid, pagetable_t pagetable, int level, uint64 va_start, int depth){

  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) {
      uint64 pa = PTE2PA(pte);

      char attrs[20] = "";
      int len = 0;
      if (!(pte & PTE_R)) {
        attrs[len++] = ' ';
        attrs[len++] = '!';
        attrs[len++] = 'r';
      }
      if (!(pte & PTE_W)) {
        attrs[len++] = ' ';
        attrs[len++] = '!';
        attrs[len++] = 'w';
      }
      if (!(pte & PTE_X)) {
        attrs[len++] = ' ';
        attrs[len++] = '!';
        attrs[len++] = 'x';
      }
      if (!(pte & PTE_U)) {
        attrs[len++] = ' ';
        attrs[len++] = '!';
        attrs[len++] = 'u';
      }
      attrs[len] = '\0';
      if (len == 12) {
        attrs[0] = '\0';
      }
      
      for (int d = 0; d < depth; d++) printf("   ");
      printf("[%d] -> %p%s\n", i, (void*)pa, attrs);
      
      if (level > 0 && (pte & (PTE_R | PTE_W | PTE_X)) == 0) {
        uint64 va = va_start | ((uint64)i << PXSHIFT(level));
        pagetable_t next_level = (pagetable_t)pa;
        page_tree(pid, next_level, level - 1, va, depth + 1);
      }
    }
  }
}

uint64
sys_pages(void)
{
  int pid;
  argint(0, &pid);

  extern struct proc proc[NPROC];
  struct proc *p;
  int success = -1; 

  if (pid == 0){
    for (p = proc; p < &proc[NPROC]; p++) {
      if (p->state != UNUSED) {
        printf("pid: %d\n", p->pid);
        printf("[satp] ─> %p\n", p->pagetable);
        page_tree(p->pid, p->pagetable, 2, 0, 1);
        success = 0;
        continue;
      }
    }
  } else {
    for (p = proc; p < &proc[NPROC]; p++) {
      if (p->pid == pid && p->state != UNUSED) {
        printf("pid: %d\n", p->pid);
        printf("[satp] ─> %p\n", p->pagetable);
        page_tree(p->pid, p->pagetable, 2, 0, 1);
        success = 0;
        break;
      }
    }
  }
  return success;
}

