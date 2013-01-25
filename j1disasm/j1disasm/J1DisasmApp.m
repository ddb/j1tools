#import "J1DisasmApp.h"
#import "BHJ1CPU.h"

@implementation J1DisasmApp

- (id) init {
    self = [super init];
    if (self == nil)
        return nil;
    return self;
}

- (void)printUsage:(FILE*)stream; {
    ddfprintf(stream, @"%@: Usage [OPTIONS] <argument> [...]\n", DDCliApp);
}

- (void)setTrace:(BOOL)trace {
    self.verbose = trace;
}

- (void)application:(DDCliApplication*)app
   willParseOptions:(DDGetoptLongParser*)optionsParser {
    DDGetoptOption optionTable[] = 
    {
        // Long         Short   Argument options
        {"trace",     't',      DDGetoptNoArgument},
        {nil,           0,      0},
    };
    [optionsParser addOptionsFromTable:optionTable];
}

- (void)runWithURL:(NSURL*)url {
    BHJ1CPU* cpu = [BHJ1CPU new];
    [cpu runCodeFromURL:url verbose:self.verbose];
}

- (int)application:(DDCliApplication*)app
  runWithArguments:(NSArray*)arguments {
    if ([arguments count] < 1) {
        ddfprintf(stderr, @"%@: At least one argument is required\n", DDCliApp);
        [self printUsage:stderr];
        return EX_USAGE;
    }
    
    [self runWithURL:[NSURL fileURLWithPath:[arguments lastObject]]];
    return EXIT_SUCCESS;
}

@end
