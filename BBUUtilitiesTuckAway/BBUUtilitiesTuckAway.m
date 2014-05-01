//
//  BBUUtilitiesTuckAway.m
//  BBUUtilitiesTuckAway
//
//  Created by Boris Bügling on 01/05/14.
//    Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import <objc/runtime.h>

#import "BBUUtilitiesTuckAway.h"
#import "NSObject+YOLO.h"

static BBUUtilitiesTuckAway *sharedPlugin;

@interface NSObject (ShutUpWarnings)

@property(readonly) id activeWorkspaceTabController;

-(BOOL)isUtilitiesAreaVisible;
-(void)toggleUtilitiesVisibility:(id)arg1;
-(NSArray*)workspaceWindowControllers;

@end

#pragma mark -

@interface BBUUtilitiesTuckAway()

@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation BBUUtilitiesTuckAway

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        
        [self performSelector:@selector(swizzleDidChangeTextInSourceTextView)
                   withObject:nil
                   afterDelay:5.0];
    }
    return self;
}

- (void)swizzleDidChangeTextInSourceTextView
{
    [[objc_getClass("DVTSourceTextView") new] yl_swizzleSelector:@selector(didChangeText)
                                                       withBlock:^void(id sself) {
                                                           [self toggleUtilitiesIfNeeded];
                                                           
                                                           [sself yl_performSelector:@selector(didChangeText)
                                                                       returnAddress:NULL
                                                                   argumentAddresses:NULL];
                                                       }];
}

- (void)toggleUtilitiesIfNeeded
{
    for (NSWindowController *workspaceWindowController in [objc_getClass("IDEWorkspaceWindowController")
                                                           workspaceWindowControllers])
    {
        id tabController = [workspaceWindowController activeWorkspaceTabController];
        if ([tabController isUtilitiesAreaVisible]) {
            [tabController toggleUtilitiesVisibility:nil];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
