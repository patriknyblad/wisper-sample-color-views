//
//  WSJSExecutor.m
//
//  Created by Patrik Nyblad on 27/11/14.
//  Copyright (c) 2014 Widespace AB. All rights reserved.
//

/*
 Heavily based the communication back from the webview to us on this thread:
 http://stackoverflow.com/questions/26851630/javascript-synchronous-native-communication-to-wkwebview
 */


#import "WSJSExecutor.h"
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
#import "WSPRHelper.h"

//Tiny model object for keeping evaluation objects until webview is ready
@interface WSJSExecutorEvalObject : NSObject
@property (nonatomic, strong) NSString *evalString;
@property (nonatomic, copy) CompletionHandler completion;
+(instancetype)evalObjectWithString:(NSString *)string andCompletion:(CompletionHandler)completion;
@end
@implementation WSJSExecutorEvalObject
+(instancetype)evalObjectWithString:(NSString *)string andCompletion:(CompletionHandler)completion
{
    WSJSExecutorEvalObject *evalObject = [[WSJSExecutorEvalObject alloc] init];
    evalObject.evalString = string;
    evalObject.completion = completion;
    return evalObject;
}
@end

@interface WSJSExecutor () <UIWebViewDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) UIWebView *legacyWebView;
@property (nonatomic, strong) WKWebView *webKitWebView;
@property (nonatomic, strong) WKUserContentController *userContentController;
@property (nonatomic, strong) NSMutableArray *evaluationQueue;

@end

@implementation WSJSExecutor

-(instancetype)init
{
    //Check to see if WKWebView is available
    Class wkWebViewClass = NSClassFromString(@"WKWebView");
    if (wkWebViewClass)
    {
        self = [self initUsingWKWebView];
    }
    else
    {
        self = [self initUsingUIWebView];
    }
    return self;
}

-(instancetype)initUsingWKWebView
{
    return [self initWithLegacyWebView:NO];
}

-(instancetype)initUsingUIWebView
{
    return [self initWithLegacyWebView:YES];
}

-(instancetype)initWithLegacyWebView:(BOOL)shouldUseLegacy
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    self = [super init];
    if (self)
    {
        CGRect dummyFrame = CGRectMake(-200, -200, 100, 100);
        
        self.evaluationQueue = [NSMutableArray array];
                
        if(shouldUseLegacy)
        {
            self.legacyWebView = [[UIWebView alloc] initWithFrame:dummyFrame];
            _legacyWebView.delegate = self;
            
            //Add to view hierarchy to make sure some javascript specific methods are performing at full speed.
            if (window)
            {
                [[[[UIApplication sharedApplication] delegate] window] addSubview:_legacyWebView];
            }
        }
        else
        {
            WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
            
            self.userContentController = [[WKUserContentController alloc] init];
            [_userContentController addScriptMessageHandler:self name:@"wisper"];
            config.userContentController = _userContentController;
            
            self.webKitWebView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:dummyFrame configuration:config];
            _webKitWebView.navigationDelegate = self;
            
            //Add to view hierarchy to make sure some javascript specific methods are performing at full speed.
            if (window)
            {
                [[[[UIApplication sharedApplication] delegate] window] addSubview:_webKitWebView];
            }
        }
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [self init];
    if (self)
    {
        [self loadURL:url];
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)html baseURL:(NSURL *)url
{
    self = [self init];
    if (self)
    {
        [self loadHTMLString:html baseURL:url];
    }
    return self;
}

-(void)loadURL:(NSURL *)url
{
    [_webKitWebView loadRequest:[NSURLRequest requestWithURL:url]];
    [_legacyWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)loadHTMLString:(NSString *)html baseURL:(NSURL *)url
{
    [_webKitWebView loadHTMLString:html baseURL:url];
    [_legacyWebView loadHTMLString:html baseURL:url];
}

-(void)evaluateJavaScript:(NSString *)javaScriptString
{
    [self evaluateJavaScript:javaScriptString completionHandler:nil];
}

-(void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(CompletionHandler)completion
{
    //We must wait until the webview is done before evaluating any JS, @see -webViewDidFinishLoad:
    if (_evaluationQueue)
    {
        [_evaluationQueue addObject:[WSJSExecutorEvalObject evalObjectWithString:javaScriptString andCompletion:completion]];
        return;
    }
    
    if (_webKitWebView)
    {
        [_webKitWebView evaluateJavaScript:javaScriptString completionHandler:^(id result, NSError *error) {
            if (completion)
            {
                completion(result, error);
            }
        }];
    }
    else
    {
        NSString *result = [_legacyWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
        if (completion)
        {
            completion(result, nil);
        }
    }
}


#pragma mark - Legacy

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self runEvaluationQueue];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *messageMarker = @"rpc:";
    NSString *urlDecodedString = [self urlDecodedStringFromRequest:request];
    if ([urlDecodedString rangeOfString:messageMarker].location == 0)
    {
        NSString *messageString = [urlDecodedString substringFromIndex:messageMarker.length];
        if ([_delegate respondsToSelector:@selector(jsExecutor:didSendMessage:)])
        {
            [_delegate jsExecutor:self didSendMessage:messageString];
        }
        return NO;
    }
    
    return YES;
}


#pragma mark - WebKit

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self runEvaluationQueue];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    
    NSString *messageMarker = @"rpc:";
    NSString *urlDecodedString = [self urlDecodedStringFromRequest:navigationAction.request];
    if ([urlDecodedString rangeOfString:messageMarker].location == 0)
    {
        decisionHandler(WKNavigationActionPolicyCancel);
        NSString *messageString = [urlDecodedString substringFromIndex:messageMarker.length];
        if ([_delegate respondsToSelector:@selector(jsExecutor:didSendMessage:)])
        {
            [_delegate jsExecutor:self didSendMessage:messageString];
        }
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([_delegate respondsToSelector:@selector(jsExecutor:didSendMessage:)])
    {
        __weak WSJSExecutor *weakSelf = self;
        [WSPRHelper jsonStringFromObject:message.body completion:^(NSString *jsonString, NSError *error) {
            [weakSelf.delegate jsExecutor:self didSendMessage:jsonString];
        }];
    }
}


#pragma mark - Javascript Core


#pragma mark - Helpers

-(void)runEvaluationQueue
{
    //Copy the array and nil it so no further objects are attached to the array
    NSArray *evalObjects = [NSArray arrayWithArray:_evaluationQueue];
    self.evaluationQueue = nil;
    
    //Run all queued objects, they will no longer be cought by the _evaluationQueue array
    for (WSJSExecutorEvalObject *evalObject in evalObjects)
    {
        [self evaluateJavaScript:evalObject.evalString completionHandler:evalObject.completion];
    }
}

-(NSString *)urlDecodedStringFromRequest:(NSURLRequest *)request
{
    return [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


@end
