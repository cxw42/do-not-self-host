/* Ngb ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   Copyright (c) 2018,        Chris White
   Copyright (c) 2008 - 2016, Charles Childers
   Copyright (c) 2009 - 2010, Luke Parrish
   Copyright (c) 2010,        Marc Simpson
   Copyright (c) 2010,        Jay Skeer
   Copyright (c) 2011,        Kenneth Keating
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <setjmp.h>

// VM machine definitions and constraints

#define CELL         int32_t
#define IMAGE_SIZE   262144
#define ADDRESSES    128
#define STACK_DEPTH  32
#define CELLSIZE     32

enum vm_opcode {
  VM_NOP,  VM_LIT,    VM_DUP,   VM_DROP,    VM_SWAP,   VM_PUSH,  VM_POP,
  VM_JUMP, VM_CALL,   VM_CCALL, VM_RETURN,  VM_EQ,     VM_NEQ,   VM_LT,
  VM_GT,   VM_FETCH,  VM_STORE, VM_ADD,     VM_SUB,    VM_MUL,   VM_DIVMOD,
  VM_AND,  VM_OR,     VM_XOR,   VM_SHIFT,   VM_ZRET,   VM_END,

  // Not in nga
  VM_IN,    // getc
  VM_OUT,   // putc
  VM_CJUMP,

  NUM_OPS
};

// VM memory and registers

CELL sp, rp, ip;
CELL data[STACK_DEPTH];
CELL address[ADDRESSES];
CELL memory[IMAGE_SIZE];

int stats[NUM_OPS];
int max_sp, max_rp;

#define TOS  data[sp]
#define NOS  data[sp-1]
#define TORS address[rp]

// Interactions with the OS

static jmp_buf DONE;
#define DONE_OK (-1)

CELL ngbLoadImage(char *imageFile) {
  FILE *fp;
  CELL imageSize;
  long fileLen;

  if ((fp = fopen(imageFile, "rb")) != NULL) {
    /* Determine length (in cells) */
    fseek(fp, 0, SEEK_END);
    fileLen = ftell(fp) / sizeof(CELL);
    rewind(fp);

    /* Read the file into memory */
    imageSize = fread(&memory, sizeof(CELL), fileLen, fp);
    fclose(fp);
  }
  else {
    printf("Unable to find the ngbImage!\n");
    exit(1);
  }
  return imageSize;
}

void ngbPrepare() {
  ip = sp = rp = max_sp = max_rp = 0;

  for (ip = 0; ip < IMAGE_SIZE; ip++)
    memory[ip] = VM_NOP;

  for (ip = 0; ip < STACK_DEPTH; ip++)
    data[ip] = 0;

  for (ip = 0; ip < ADDRESSES; ip++)
    address[ip] = 0;

  for (ip = 0; ip < NUM_OPS; ip++)
    stats[ip] = 0;
}

void ngbStatsCheckMax() {
  if (max_sp < sp)
    max_sp = sp;
  if (max_rp < rp)
    max_rp = rp;
}

void ngbDisplayStats()
{
  int s, i;

  printf("Runtime Statistics\n");
  printf("NOP:     %d\n", stats[VM_NOP]);
  printf("LIT:     %d\n", stats[VM_LIT]);
  printf("DUP:     %d\n", stats[VM_DUP]);
  printf("DROP:    %d\n", stats[VM_DROP]);
  printf("SWAP:    %d\n", stats[VM_SWAP]);
  printf("PUSH:    %d\n", stats[VM_PUSH]);
  printf("POP:     %d\n", stats[VM_POP]);
  printf("JUMP:    %d\n", stats[VM_JUMP]);
  printf("CALL:    %d\n", stats[VM_CALL]);
  printf("CCALL:   %d\n", stats[VM_CCALL]);
  printf("RETURN:  %d\n", stats[VM_RETURN]);
  printf("EQ:      %d\n", stats[VM_EQ]);
  printf("NEQ:     %d\n", stats[VM_NEQ]);
  printf("LT:      %d\n", stats[VM_LT]);
  printf("GT:      %d\n", stats[VM_GT]);
  printf("FETCH:   %d\n", stats[VM_FETCH]);
  printf("STORE:   %d\n", stats[VM_STORE]);
  printf("ADD:     %d\n", stats[VM_ADD]);
  printf("SUB:     %d\n", stats[VM_SUB]);
  printf("MUL:     %d\n", stats[VM_MUL]);
  printf("DIVMOD:  %d\n", stats[VM_DIVMOD]);
  printf("AND:     %d\n", stats[VM_AND]);
  printf("OR:      %d\n", stats[VM_OR]);
  printf("XOR:     %d\n", stats[VM_XOR]);
  printf("SHIFT:   %d\n", stats[VM_SHIFT]);
  printf("ZRET:    %d\n", stats[VM_ZRET]);
  printf("END:     %d\n", stats[VM_END]);
  printf("IN:      %d\n", stats[VM_IN]);
  printf("OUT:     %d\n", stats[VM_OUT]);
  printf("CJUMP:   %d\n", stats[VM_CJUMP]);
  printf("Max sp:  %d\n", max_sp);
  printf("Max rp:  %d\n", max_rp);

  for (s = i = 0; s < NUM_OPS; s++)
    i += stats[s];
  printf("Total opcodes processed: %d\n", i);
}

// VM instructions =========================================================

void inst_nop() {
}

void inst_lit() {
  sp++;
  ip++;
  TOS = memory[ip];
  ngbStatsCheckMax();
}

void inst_dup() {
  sp++;
  data[sp] = NOS;
  ngbStatsCheckMax();
}

void inst_drop() {
  data[sp] = 0;
   if (--sp < 0)
     ip = IMAGE_SIZE;
}

void inst_swap() {
  int a;
  a = TOS;
  TOS = NOS;
  NOS = a;
}

void inst_push() {
  rp++;
  TORS = TOS;
  inst_drop();
  ngbStatsCheckMax();
}

void inst_pop() {
  sp++;
  TOS = TORS;
  rp--;
}

void inst_jump() {
  ip = TOS - 1;
  inst_drop();
}

void inst_call() {
  rp++;
  TORS = ip;
  ip = TOS - 1;
  inst_drop();
  ngbStatsCheckMax();
}

void inst_ccall() {
  int a, b;
  rp++;
  TORS = ip;
  a = TOS; inst_drop();  /* Destination address */
  b = TOS; inst_drop();  /* Flag  */
  if (b != 0)
    ip = a - 1;
}

void inst_return() {
  ip = TORS;
  rp--;
}

void inst_eq() {
  if (NOS == TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}

void inst_neq() {
  if (NOS != TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}

void inst_lt() {
  if (NOS < TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}

void inst_gt() {
  if (NOS > TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}

void inst_fetch() {
  TOS = memory[TOS];
}

void inst_store() {
  memory[TOS] = NOS;
  inst_drop();
  inst_drop();
}

void inst_add() {
  NOS += TOS;
  inst_drop();
}

void inst_sub() {
  NOS -= TOS;
  inst_drop();
}

void inst_mul() {
  NOS *= TOS;
  inst_drop();
}

void inst_divmod() {
  int a, b;
  a = TOS;
  b = NOS;
  TOS = b / a;
  NOS = b % a;
}

void inst_and() {
  NOS = TOS & NOS;
  inst_drop();
}

void inst_or() {
  NOS = TOS | NOS;
  inst_drop();
}

void inst_xor() {
  NOS = TOS ^ NOS;
  inst_drop();
}

void inst_shift() {
  if (TOS < 0)
    NOS = NOS << (TOS * -1);
  else
    NOS >>= TOS;
  inst_drop();
}

void inst_zret() {
  if (TOS == 0) {
    inst_drop();
    ip = TORS;
    rp--;
  }
}

void inst_end() {
  ip = IMAGE_SIZE;
}

// Not in nga

void inst_in() {
  sp++;
  TOS = getc(stdin);
  ngbStatsCheckMax();
}

void inst_out() {
  printf("%c", (char)(data[sp]&0xff));
  sp--;
}

void inst_cjump() {
  fprintf(stderr,"CJUMP not yet implemented");
  inst_end();
}

// Instruction table
typedef void (*Handler)(void);

Handler instructions[NUM_OPS] = {
  inst_nop, inst_lit, inst_dup, inst_drop, inst_swap, inst_push, inst_pop,
  inst_jump, inst_call, inst_ccall, inst_return, inst_eq, inst_neq, inst_lt,
  inst_gt, inst_fetch, inst_store, inst_add, inst_sub, inst_mul, inst_divmod,
  inst_and, inst_or, inst_xor, inst_shift, inst_zret, inst_end,
  inst_in,
  inst_out,
  inst_cjump,
};

// Interpreter =============================================================

void ngbProcessOpcode() {
  stats[memory[ip]]++;
  instructions[memory[ip]]();
}

#ifndef NO_MAIN

int main(int argc, char **argv) {
  ngbPrepare();
  if (argc == 2)
      ngbLoadImage(argv[1]);
  else
      ngbLoadImage("ngbImage");

  CELL opcode, i;

  int retval = setjmp(DONE);

  if(retval == 0) {   // First time through: run it

    ip = 0;
    while (ip < IMAGE_SIZE) {
      opcode = memory[ip];
      if (opcode >= 0 && opcode < NUM_OPS) {
        ngbProcessOpcode();
      } else {
        printf("Invalid instruction!\n");
        printf("At %d, opcode %d\n", ip, opcode);
        exit(1);
      }
      ip++;
    }

  } //endif first time through

  if(retval == DONE_OK) { retval = 0; }
    //because longjmp can't provide a 0 value

  int bot = sp-100;   // print up to the top 100 stack entries
  if(bot<1) { bot = 1; }

  for (i = bot; i <= sp; i++) {
    printf("%8d: %d ", i, data[i]);
  }

  printf("\n");
  exit(retval);
}

#endif
