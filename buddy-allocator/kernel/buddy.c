#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"


struct header {
  uint64 size;
  uint64 magic;
}; // state of each block
#define MAGIC_USED 0xAAAAAAAAAAAAAAAAUL 
#define MAGIC_FREE 0xBBBBBBBBBBBBBBBBUL 

struct free_block {
  struct free_block *next;
}; 

static struct free_block *freelist[7]; // freelist for each order
#define HEADER_SIZE sizeof(struct header) // Should be 16

static struct spinlock buddylock;

void
buddyinit(void) {

    initlock(&buddylock, "buddylock");

    for(int i = 0; i < 7; i++) {
        freelist[i] = 0;
    } // initalize freelists as empty 
}

static int
is_power_of_two(uint64 n) 
{
    return n > 0 && (n & (n - 1)) == 0;
}

static uint64
round_up_size(uint64 length) {

    uint64 total = length + HEADER_SIZE;
    uint64 size = 32;

    while (size < total) {
        size *= 2;
    }

    return size;
}

static int
size_to_order(uint64 size) {

    int order = 0;
    uint64 s = 32;

    while (s < size) {
        s *= 2;
        order++;
    }
    
    return order;
} // convert block size to freelist index

static struct header*
remove_first_from_freelist(int order) { 

    if (order < 0 || order >= 7) {
        return 0; 
    }

    struct free_block *block = freelist[order];

    if (block == 0) {
        return 0; // freelist empty
    }

    freelist[order] = block->next; // update head to next node

    return (struct header*)((char*)block - HEADER_SIZE); // header pointer
} // remove and return first block from freelist, returns 0 if empty

static void
remove_from_freelist(struct header *hdr)
{
    int order = size_to_order(hdr->size);
    if (order < 0 || order >= 7) {
        return;
    }

    struct free_block *remove_block = (struct free_block*)((char*)hdr + HEADER_SIZE);

    struct free_block **list = &freelist[order];
    struct free_block *prev = 0;
    struct free_block *curr = *list;

    // Find the node in the sorted list
    while (curr != 0 && curr != remove_block) {
        if ((void*)curr > (void*)remove_block) { // we passed where it should have been
            panic("buddy_free: cannot find buddy in list");
        }
        prev = curr;
        curr = curr->next;
    }

    
    if (curr == 0) { // if curr is 0, didn't find it
        panic("buddy_free: cannot find buddy in list");
    }

    // Unlink the node (curr == remove_block)
    if (prev == 0) {
        *list = curr->next; // Remove from head
    } else {
        prev->next = curr->next; // Remove from middle
    }
}

static void
add_to_freelist(struct header *hdr) {

    int order = size_to_order(hdr->size);
    if (order < 0 || order >= 7) {
        return; 
    }
    
    // set the free magic number
    hdr->magic = MAGIC_FREE;

    // get the pointer to the free_block (in the usable space)
    struct free_block *new_block = (struct free_block*)((char*)hdr + HEADER_SIZE);

    // insert into list, sorted by address
    struct free_block **list = &freelist[order];
    struct free_block *prev = 0;
    struct free_block *curr = *list;

    while (curr != 0 && (void*)curr < (void*)new_block) {
        prev = curr;
        curr = curr->next;
    }

    // Insert new_block between prev and curr
    new_block->next = curr;
    if (prev == 0) {
        *list = new_block; // Insert at head
    } else {
        prev->next = new_block; // Insert in middle
    }
} // adds a free block to the correct free list, keeping the list sorted by address

void*
buddy_alloc(uint64 length) {

    if (length == 0) {
        return 0;
    } // zero request

    if (length > 4096 - HEADER_SIZE) {
        return 0;
    } // greater than 4080 request

    uint64 block_size = round_up_size(length); // total block size needed

    if (block_size == 4096) {
        void *page = kalloc();

        if (page == 0) {
            return 0; // out of memory
        }

        struct header *hdr = (struct header*)page;
        hdr->magic = MAGIC_USED;
        hdr->size = 4096;
        
        return (void*)((char*)hdr + HEADER_SIZE);// Return the pointer to the usable space
    } // fresh 4096 block

    int target_order = size_to_order(block_size);

    acquire(&buddylock);

    struct header *hdr = 0;
    int order_found = -1;

    for (int o = target_order; o < 7; o++) {
        hdr = remove_first_from_freelist(o); // try to get a block
        if (hdr != 0) {
            order_found = o; // we found a block of this order
            break;
        }
    } // search lists, from target size upwards

    // if all lists empty, get a new page
    if (hdr == 0) {
        void *page = kalloc();
        if (page == 0) {
            release(&buddylock);
            return 0; // out of memory
        }
        
        hdr = (struct header*)page;
        hdr->size = 4096;
        order_found = size_to_order(4096); // will be 7
    }

    // we have a block hdr of order_found
    // we need a block of target_order
    while (order_found > target_order) { // block too big, split it
        
        uint64 current_size = hdr->size;
        uint64 half_size = current_size / 2;

        // the buddy is at the higher address
        struct header *buddy_hdr = (struct header*)((char*)hdr + half_size);
        buddy_hdr->size = half_size;

        add_to_freelist(buddy_hdr);

        hdr->size = half_size;
        order_found--; // block we have is now one order smaller
    }

    // hdr points to a block of target_order size
    hdr->magic = MAGIC_USED; 

    release(&buddylock);

    return (void*)((char*)hdr + HEADER_SIZE); // pointer to usable space
}

void 
buddy_free(void *ptr) {

    acquire(&buddylock);

    if (ptr == 0) {
        release(&buddylock);
        return;
    }

    struct header *hdr = (struct header*)((char*)ptr - HEADER_SIZE);

    if (hdr->magic != MAGIC_USED) {
        panic("buddy_free: bad magic number");
    } // check magic

    if (hdr->size < 32 || hdr->size > 4096 || !is_power_of_two(hdr->size)) {
        panic("buddy_free: bad size");
    } // check size

    if ((uint64)hdr % hdr->size != 0) {
        panic("buddy_free: bad alignment");
    } // check alignment

   
    while (hdr->size < 4096) { // loop, merging until we hit 4096, or no mergable buddy
        
        // find buddy's address
        uint64 buddy_addr = (uint64)hdr ^ hdr->size;
        struct header *buddy_hdr = (struct header*)buddy_addr;

        // check if buddy free and same size
        if (buddy_hdr->magic != MAGIC_FREE || buddy_hdr->size != hdr->size) {
            break; // buddy is allocated or wrong size
        }

        remove_from_freelist(buddy_hdr); // remove buddy from free list

        
         
        if ((uint64)buddy_hdr < (uint64)hdr) {
            hdr = buddy_hdr; // new header is the lower address
        }
       
        hdr->size *= 2; // new block's size
    }

    if (hdr->size == 4096) {
        kfree(hdr);
    } else {
        add_to_freelist(hdr);
    }

    release(&buddylock);
}


static void
print_indent(int depth)
{
    for (int i = 0; i < depth; i++) {
        printf("  "); // Use a simple 2-space indent
    }
}

/**
 * The recursive helper for buddy_print.
 * addr: The address of the *start* of the block to inspect.
 * size: The size of the block we are inspecting (e.g., 4096, 2048...).
 * depth: The current recursion depth for indentation.
 */
static void
print_recursive(uint64 addr, uint64 size, int depth)
{
    // Get the header for the block at this address
    struct header *hdr = (struct header*)addr;

    // --- Base Case ---
    // If the header's size matches the size we are currently
    // inspecting, this block is a "leaf" (it's not split).
    if (hdr->size == size) {
        print_indent(depth);
        if (hdr->magic == MAGIC_USED) {
            printf("USED (%ld)\n", size);
        } else if (hdr->magic == MAGIC_FREE) {
            printf("FREE (%ld)\n", size);
        } else {
            // This can happen when printing the buddy of a
            // merged block. It's not a critical error.
            printf("BAD_DATA (size=%ld) at 0x%ld\n", size, addr);
        }
        return; // Stop recursing
    }

    // --- Recursive Step ---
    // The block must be split (because hdr->size < size).
    // Print this parent node and recurse on its children.
    
    // We only check this at the root
    if (size == 4096 && hdr->magic == MAGIC_USED && hdr->size == 4096) {
        printf("USED (4096)\n");
        return;
    }
    
    print_indent(depth);
    printf("(SPLIT %ld)\n", size);

    uint64 half_size = size / 2;
    int next_depth = depth + 1;

    // Recurse on the two children (buddies)
    
    // Buddy 1 (lower address)
    print_recursive(addr, half_size, next_depth);
    
    // Buddy 2 (higher address)
    print_recursive(addr + half_size, half_size, next_depth);
}


void
buddy_print(void *ptr)
{
    if (ptr == 0) {
        printf("buddy_print: null pointer\n");
        return;
    }

    // Find the 4096-byte page this pointer belongs to.
    // PGROUNDDOWN rounds *down* to the nearest page.
    uint64 root_addr = (uint64)PGROUNDDOWN((uint64)ptr);
    
    // Start the recursion from the root (4096-byte block)
    // We start with the full 4096-byte page at depth 0.
    print_recursive(root_addr, 4096, 0);
}

void
buddy_test(void)
{
    printf("Starting buddy test\n");

    printf("\nallocating 1024-byte block\n");
    void *e = buddy_alloc(1000);
    buddy_print(e);

    printf("\nallocating 128-byte block\n");
    void *c = buddy_alloc(112);
    buddy_print(c);

    printf("\nallocating 32-byte block\n");
    void *a = buddy_alloc(16);
    buddy_print(a);

    printf("\nfreeing 1024-byte block\n");
    buddy_free(e);
    buddy_print(a);

    printf("\nallocating 128-byte block\n");
    void *b = buddy_alloc(112);
    buddy_print(b);

    printf("\nfreeing 32-byte block\n");
    buddy_free(a);
    buddy_print(b);

    printf("\nfreeing first 128-byte block\n");
    buddy_free(c);
    buddy_print(b);

    printf("\nallocating 2048-byte block\n");
    void *d = buddy_alloc(2000);
    buddy_print(d);

    printf("\nfreeing other 128-byte block\n");
    buddy_free(b);
    buddy_print(d);

    printf("\nfreeing 2048-byte block\n");
    buddy_free(d);
}