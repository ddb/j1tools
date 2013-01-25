//
//  BHJ1CPU.m
//  J1GUI
//
//  Created by David Brown on 1/20/13.
//  Copyright (c) 2013 bithead. All rights reserved.
//

#import "BHJ1CPU.h"

@implementation BHJ1CPU

@synthesize pc = _program_counter;
@synthesize t = _top_of_stack;

static int sx[4] = { 0, 1, -2, -1 }; /* 2-bit sign extension */

- (id)init {
    self = [super init];
    if (self) {
        self.r = [[NSMutableArray alloc] initWithCapacity:32];
        self.d = [[NSMutableArray alloc] initWithCapacity:32];
    }
    return self;
}

- (void)push:(int)v { // push v on the data stack
    self.dsp = 31 & (self.dsp + 1);
    self.d[self.dsp] = [NSNumber numberWithInt:self.t];
    self.t = v;
}

- (int)pop { // pop value from the data stack and return it
    int v = self.t;
    self.t = [self.d[self.dsp] intValue];
    self.dsp = 31 & (self.dsp - 1);
    return v;
}

- (void)execute:(int)entrypoint {
    int _pc, _t, n;
    int currentInstruction = 0x4000 | entrypoint; // First currentInstruction: "call entrypoint"

    do {
        _pc = self.pc + 1;
        if (currentInstruction & 0x8000) { // literal
	  [self push:(currentInstruction & 0x7fff)];
        } else {
            int target = currentInstruction & 0x1fff;
            switch (currentInstruction >> 13) {
                case 0: // jump
                    _pc = target;
                    break;
                case 1: // conditional jump
                    if ([self pop] == 0)
                        _pc = target;
                    break;
                case 2: // call
                    self.rsp = 31 & (self.rsp + 1);
                    self.r[self.rsp] = [NSNumber numberWithInt:(_pc << 1)];
                    _pc = target;
                    break;
                case 3: // ALU
                    if (currentInstruction & 0x1000) /* R->PC */
                        _pc = [self.r[self.rsp] intValue] >> 1;
                    n = [self.d[self.dsp] intValue];
                    switch ((currentInstruction >> 8) & 0xf) {
                        case 0:   _t = self.t; break;
                        case 1:   _t = n; break;
                        case 2:   _t = self.t + n; break;
                        case 3:   _t = self.t & n; break;
                        case 4:   _t = self.t | n; break;
                        case 5:   _t = self.t ^ n; break;
                        case 6:   _t = ~self.t; break;
                        case 7:   _t = -(self.t == n); break;
                        case 8:   _t = -((int16_t)n < (int16_t)self.t); break;
                        case 9:   _t = n >> self.t; break;
                        case 10:  _t = self.t - 1; break;
                        case 11:  _t = [self.r[self.rsp] intValue]; break;
                        case 12:  _t = self.memory[self.t >> 1]; break;
                        case 13:  _t = n << self.t; break;
                        case 14:  _t = (self.rsp << 8) + self.dsp; break;
                        case 15:  _t = -(n < self.t); break;
                    }
                    self.dsp = 31 & (self.dsp + sx[currentInstruction & 3]);
                    self.rsp = 31 & (self.rsp + sx[(currentInstruction >> 2) & 3]);
                    if (currentInstruction & 0x80) /* T->N */
                        self.d[self.dsp] = [NSNumber numberWithInt:self.t];
                    if (currentInstruction & 0x40) /* T->R */
                        self.r[self.rsp] = [NSNumber numberWithInt:self.t];
                    if (currentInstruction & 0x20) /* N->[T] */
                        self.memory[self.t >> 1] = n;
                    self.t = _t;
                    break;
            }
        }
        self.pc = _pc;
        currentInstruction = self.memory[self.pc];
    } while (self.rsp);
}
/* end of CPU */

- (NSString*)decodeInstruction:(u_int16_t)currentInstruction atAddress:(uint)address {
    NSMutableString* decodedInstruction = [NSMutableString new];
    [decodedInstruction appendFormat:@"%04X    ", currentInstruction];
    if ([self.symbolTable containsObject:[NSNumber numberWithInteger:address]]) {
        [decodedInstruction appendFormat:@"LBL%04X: ", address<<1];
    } else {
        [decodedInstruction appendFormat:@"         "];
    }
    if (currentInstruction & 0x8000) { // literal
        [decodedInstruction appendFormat:@"LITERAL %04X (%u)", (currentInstruction & 0x7fff), (currentInstruction & 0x7fff)];
    } else {
        int target = (currentInstruction & 0x1fff) << 1;
        switch (currentInstruction >> 13) {
            case 0: // jump
                [decodedInstruction appendFormat:@"BRANCH  LBL%04X", target];
                break;

            case 1: // conditional jump
                [decodedInstruction appendFormat:@"0BRANCH LBL%04X", target];
                break;

            case 2: // call
                [decodedInstruction appendFormat:@"CALL    LBL%04X", target];
                break;

            case 3: { // ALU
                [decodedInstruction appendFormat:@"ALU     "];
                if (currentInstruction & 0x1000) /* R->PC */
                    [decodedInstruction appendFormat:@"R->PC "];
                switch ((currentInstruction >> 8) & 0xf) {
                    case 0: [decodedInstruction appendFormat:@"T "]; break;
                    case 1: [decodedInstruction appendFormat:@"N "]; break;
                    case 2: [decodedInstruction appendFormat:@"T+N "]; break;
                    case 3: [decodedInstruction appendFormat:@"T&N "]; break;
                    case 4: [decodedInstruction appendFormat:@"T|N "]; break;
                    case 5: [decodedInstruction appendFormat:@"T^N "]; break;
                    case 6: [decodedInstruction appendFormat:@"~T "]; break;
                    case 7: [decodedInstruction appendFormat:@"T=N "]; break;
                    case 8: [decodedInstruction appendFormat:@"N<T "]; break;
                    case 9: [decodedInstruction appendFormat:@"N>>T "]; break;
                    case 10: [decodedInstruction appendFormat:@"T-1 "]; break;
                    case 11: [decodedInstruction appendFormat:@"R "]; break;
                    case 12: [decodedInstruction appendFormat:@"(T) "]; break;
                    case 13: [decodedInstruction appendFormat:@"N<<T "]; break;
                    case 14: [decodedInstruction appendFormat:@"depth "]; break;
                    case 15: [decodedInstruction appendFormat:@"Nu<T "]; break;
                }
                int dataStackDelta = sx[currentInstruction & 3];
                int returnStackDelta = sx[(currentInstruction >> 2) & 3];
                if (dataStackDelta) {
                    switch (dataStackDelta) {
                        case -1:
                            [decodedInstruction appendFormat:@"drop "];
                            break;

                        case -2:
                            [decodedInstruction appendFormat:@"2drop "];
                            break;

                        default:
                            [decodedInstruction appendFormat:@"push "];
                            break;
                    }
                }
                if (returnStackDelta) {
                    switch (returnStackDelta) {
                        case -1:
                            [decodedInstruction appendFormat:@"rdrop "];
                            break;

                        case -2:
                            [decodedInstruction appendFormat:@"2rdrop "];
                            break;

                        default:
                            [decodedInstruction appendFormat:@"rpush "];
                            break;
                    }
                }
                if (currentInstruction & 0x80) /* T->N */
                    [decodedInstruction appendFormat:@"T->N "];
                if (currentInstruction & 0x40) /* T->R */
                    [decodedInstruction appendFormat:@"T->R "];
                if (currentInstruction & 0x20) /* N->[T] */
                    [decodedInstruction appendFormat:@"N->(T) "];
                decodedInstruction = [[decodedInstruction substringToIndex:[decodedInstruction length] - 1] mutableCopy];
                break;
            }
        }
    }
    return decodedInstruction;
}

- (BOOL)maybeLoadMemoryImageAtURL:(NSURL*)memoryImageURL {
    NSString* rawMemString = [NSString stringWithContentsOfURL:memoryImageURL encoding:NSUTF8StringEncoding error:nil];
    NSMutableArray* cells = [NSMutableArray new];
    [rawMemString enumerateLinesUsingBlock:^(NSString* line, BOOL* stop) {
        if ([line length] > 0 && [line characterAtIndex:0] != '@') {
            uint outVal;
            NSScanner* scanner = [NSScanner scannerWithString:line];
            [scanner scanHexInt:&outVal];
            [cells addObject:[NSNumber numberWithInteger:outVal]];
        }
    }];
    self.memoryImage = [NSMutableData dataWithLength:([cells count] * 2)];
    u_int16_t* mem = [self.memoryImage mutableBytes];
    for (NSNumber* cellValue in cells) {
        *mem++ = [cellValue unsignedIntegerValue];
    }
    self.memory = [self.memoryImage mutableBytes];
    return YES;
}

- (void)buildSymbolTable {
    self.symbolTable = [NSMutableSet new];
    for (int i = 0; i < ([self.memoryImage length] / 2); i++) {
        NSUInteger currentInstruction = self.memory[i];
        if (currentInstruction & 0x8000) { // literal
        } else {
            int target = currentInstruction & 0x1fff;
            switch (currentInstruction >> 13) {
                case 0: // jump
                case 1: // conditional jump
                case 2: // call
                    [self.symbolTable addObject:[NSNumber numberWithInt:target]];
                    break;

                case 3: { // ALU
                    break;
                }
            }
        }
    }
}

- (NSString*)dumpMemoryAtURL:(NSURL*)memoryImageURL {
    NSMutableString* output = [NSMutableString new];
    [self maybeLoadMemoryImageAtURL:memoryImageURL];
    [self buildSymbolTable];
    for (int i = 0; i < ([self.memoryImage length] / 2); i++) {
        [output appendFormat:@"%04X - %@\n", i<<1, [self decodeInstruction:self.memory[i] atAddress:i]];
    }
    return output;
}

@end
