//
//  JavaScriptRuntime.m
//  WisperColors
//
//  Created by Patrik Nyblad on 2017-05-23.
//  Copyright © 2017 WidespaceAB. All rights reserved.
//

#import "JavaScriptRuntime.h"
#import <Wisper/Wisper.h>
#import "WSPRRootView.h"
#import "WSPRView.h"

#define RPCMessageEndPoint @"wisper.rpc.message"
#define RPCURLScheme @"RPC"

#define GetFileData(fileName, fileExtension) [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:fileExtension]]

@interface JavaScriptRuntime () <WSPRGatewayDelegate, WSJSExecutorDelegate>

@property (nonatomic, strong) WSJSExecutor *jsExecutor;
@property (nonatomic, strong) WSPRGatewayRouter *gatewayRouter;

@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, assign) BOOL handshakeDone;

+(void)sendWindowEventUsingGatewayRouter:(WSPRGatewayRouter *)gatewayRouter;

@end


@implementation JavaScriptRuntime

static __strong WSPRRootView *window;

+(instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static JavaScriptRuntime *sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[JavaScriptRuntime alloc] init];
    });
    
    return sharedInstance;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        //Disable WKWebView in the JSExecutor since WKWebView does not support HTML5 Application Cache
        self.jsExecutor = [[WSJSExecutor alloc] initUsingUIWebView];

        NSString *configurationScript = @"var wisper = {"
                                        "    client: {"
                                        "        platform: 'ios',"
                                        "    }"
                                        "};";
        NSString *htmlString = [[NSString alloc] initWithData:GetFileData(@"index", @"html") encoding:NSUTF8StringEncoding];
        [self.jsExecutor loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"https://wisper.colors"]];

        _jsExecutor.delegate = self;
        [_jsExecutor evaluateJavaScript:configurationScript];
        
        self.gatewayRouter = [[WSPRGatewayRouter alloc] init];
        _gatewayRouter.delegate = self;
        
        
        //UI
        [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRRootView class]]
                             onPath:@"wisp.ui.RootView"];
        [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRView class]]
                             onPath:@"wisp.ui.View"];
        
        
        self.messageQueue = [NSMutableArray array];
        
        [[self class] sendWindowEventUsingGatewayRouter:_gatewayRouter];
    }
    return self;
}

#pragma mark - Actions

- (void)sendRPCMessage:(NSString *)message
{
    if (!_handshakeDone)
    {
        [_messageQueue addObject:message];
        return;
    }
    
    NSString *jsEvalString = [NSString stringWithFormat:@"%@('%@')", RPCMessageEndPoint, message];
    
    //Make sure that we only manipulate the webview on the main thread
    if ([[NSThread currentThread] isMainThread])
    {
        [self.jsExecutor evaluateJavaScript:jsEvalString];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.jsExecutor evaluateJavaScript:jsEvalString];
        });
    }
}


#pragma mark - WSPRGatewayDelegate

-(void)gateway:(WSPRGateway *)rpcController didOutputMessage:(NSString *)message
{
    [self sendRPCMessage:message];
}

-(void)gateway:(WSPRGateway *)rpcController didReceiveMessage:(WSPRMessage *)message
{
    if ([message isKindOfClass:[WSPRRequest class]])
    {
        WSPRRequest *request = (WSPRRequest *)message;
        if ([request.method isEqualToString:@".handshake"])
        {
            NSLog(@"Handshake received!");
            
            //Enable sending messages
            self.handshakeDone = YES;
            
            //Perform the handshake
            WSPRResponse *response = [request createResponse];
            request.responseBlock(response);
            
            //Run through all of the queue
            for (NSString *message in _messageQueue)
            {
                [self sendRPCMessage:message];
            }
            
            //Delete the queue
            self.messageQueue = nil;
        }
    }
}


#pragma mark - Helpers

+(void)sendWindowEventUsingGatewayRouter:(WSPRGatewayRouter *)gatewayRouter
{
    UIWindow *appWindow = [[[UIApplication sharedApplication] delegate] window];
    if (appWindow)
    {
        WSPRClassRouter *rootViewClassRouter = [gatewayRouter routerAtPath:@"wisp.ui.RootView"];
        window = [[WSPRRootView alloc] initWithView:appWindow];
        WSPRClassInstance *windowWisperInstance = [rootViewClassRouter addInstance:window];
        
        WSPRNotification *windowNotification = [[WSPRNotification alloc] init];
        windowNotification.method = @"wisper.app!";
        windowNotification.params = @[@"window", windowWisperInstance.instanceIdentifier];
        [gatewayRouter.gateway sendMessage:windowNotification];
    }
}



@end
