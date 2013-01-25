//
//  main.m
//  j1disasm
//
//  Created by David Brown on 1/20/13.
//  Copyright (c) 2013 bithead. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "J1DisasmApp.h"
#import "BHJ1CPU.h"

int main(int argc, const char * argv[])
{

    int result;

    @autoreleasepool {
        result = DDCliAppRunWithClass([J1DisasmApp class]);
    }
    return result;
}

