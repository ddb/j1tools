//
//  BHAppDelegate.h
//  J1GUI
//
//  Created by David Brown on 1/20/13.
//  Copyright (c) 2013 bithead. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BHAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;

- (IBAction)saveAction:(id)sender;

@end
