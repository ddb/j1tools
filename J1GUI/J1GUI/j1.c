static unsigned short t;  
static unsigned short d[32]; /* data stack */
static unsigned short r[32]; /* return stack */
static unsigned short pc;    /* program counter, counts CELLS */
static unsigned char dsp, rsp; /* point to top entry */
static unsigned short* memory; /* RAM */
static int sx[4] = { 0, 1, -2, -1 }; /* 2-bit sign extension */

static void push(int v) // push v on the data stack
{
  dsp = 31 & (dsp + 1);
  d[dsp] = t;
  t = v;
}

static int pop(void) // pop value from the data stack and return it
{
  int v = t;
  t = d[dsp];
  dsp = 31 & (dsp - 1);
  return v;
}

static void execute(int entrypoint)
{
  int _pc, _t, n;
  int insn = 0x4000 | entrypoint; // First insn: "call entrypoint"

  do {
    _pc = pc + 1;
    if (insn & 0x8000) { // literal
      push(insn & 0x7fff);
    } else {
      int target = insn & 0x1fff;
      switch (insn >> 13) {
      case 0: // jump
        _pc = target;
        break;
      case 1: // conditional jump
        if (pop() == 0)
          _pc = target;
        break;
      case 2: // call
        rsp = 31 & (rsp + 1);
        r[rsp] = _pc << 1;
        _pc = target;
        break;
      case 3: // ALU
        if (insn & 0x1000) /* R->PC */
          _pc = r[rsp] >> 1;
        n = d[dsp];
        switch ((insn >> 8) & 0xf) {
        case 0:   _t = t; break;
        case 1:   _t = n; break;
        case 2:   _t = t + n; break;
        case 3:   _t = t & n; break;
        case 4:   _t = t | n; break;
        case 5:   _t = t ^ n; break;
        case 6:   _t = ~t; break;
        case 7:   _t = -(t == n); break;
        case 8:   _t = -((signed short)n < (signed short)t); break;
        case 9:   _t = n >> t; break;
        case 10:  _t = t - 1; break;
        case 11:  _t = r[rsp]; break;
        case 12:  _t = memory[t >> 1]; break;
        case 13:  _t = n << t; break;
        case 14:  _t = (rsp << 8) + dsp; break;
        case 15:  _t = -(n < t); break;
        }
        dsp = 31 & (dsp + sx[insn & 3]);
        rsp = 31 & (rsp + sx[(insn >> 2) & 3]);
        if (insn & 0x80) /* T->N */
          d[dsp] = t;
        if (insn & 0x40) /* T->R */
          r[rsp] = t;
        if (insn & 0x20) /* N->[T] */
          memory[t >> 1] = n;
        t = _t;
        break;
      }
    }
    pc = _pc;
    insn = memory[pc];
  } while (rsp);
}
/* end of CPU */

/* start of I/O demo */

#include <stdio.h>
#include <stdlib.h>

void
forthmain()
{
  unsigned short m[32768];
  FILE *f = fopen("j1.bin", "r");
  fread(m, 8192, sizeof(m[0]), f);

  memory = m;
  push(7);
  execute(0);
  printf("pop: %d\n", pop());

  // Dump memory starting at cell 16384
  int i; 
  for (i = 0x4000; m[i]; i++)
    printf("%04x: %04x\n", i, m[i]);
  // Print the same memory, assumes 0 terminator!
  printf("%s\n", (char*)&m[0x4000]);

  exit(0);
}
