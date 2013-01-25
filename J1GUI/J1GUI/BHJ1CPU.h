//
//  BHJ1CPU.h
//  J1GUI
//
//  Created by David Brown on 1/20/13.
//  Copyright (c) 2013 bithead. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHJ1CPU : NSObject

@property u_int16_t t;
@property NSMutableArray* d; /* data stack */
@property NSMutableArray* r; /* return stack */
@property u_int16_t pc;    /* program counter, counts CELLS */
@property u_int8_t dsp, rsp; /* point to top entry */
@property u_int16_t* memory; /* RAM */
@property NSMutableData* memoryImage;
@property NSMutableSet* symbolTable;

- (NSString*)dumpMemoryAtURL:(NSURL*)memoryImageURL;

@end
