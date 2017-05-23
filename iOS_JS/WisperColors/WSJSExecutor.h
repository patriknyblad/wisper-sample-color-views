//
//  WSJSExecutor.h
//
//  Created by Patrik Nyblad on 27/11/14.
//  Copyright (c) 2014 Widespace AB. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionHandler)(id result, NSError *error);

@class WSJSExecutor;

/**
 *  Protocol for receiving communication from the JSExecutor
 *
 *  From Javascript you may pass messages back to Objective C using one of the following approaches:
 *
 *  #Option 1 (iOS 8 and above)
 *  window.webkit.messageHandlers.WSJSExecutor.postMessage("What's the meaning of life, native code?");
 *
 *  #Option 2
 *  window.location = "rpc:{_JSON_OBJECT_}"
 *
 *  #Option 3
 *  var iframe = document.createElement("IFRAME");
 *  iframe.setAttribute("src", "rpc:{_JSON_OBJECT_}");
 *  document.documentElement.appendChild(iframe);
 *  iframe.parentNode.removeChild(iframe);
 *  iframe = null;
 */
@protocol WSJSExecutorDelegate <NSObject>
@required
/**
 *  The JSExecutor is trying to send a message.
 *  @param jsExecotur  The JSExecutor instance
 *  @param message String containing the message from the JSExecutor
 */
-(void)jsExecutor:(WSJSExecutor *)jsExecutor didSendMessage:(NSString *)message;

@end

/**
 *  Abstraction of Javascript implementation that spans different iOS versions. This class 
 *  cluster uses a WKWebView if available and UIWebView as fallback.
 *
 *  # Ram consumption:
 *  --------------------------------------
 *  * iOS 7.1 (Sim) UIWebView 32-bit 4.8mb
 *  * iOS 7.1 (Sim) UIWebView 64-bit 7.0mb
 *
 *  * iOS 8.1 (Sim) WKWebView 32-bit 0.9mb
 *  * iOS 8.1 (Sim) WKWebView 64-bit 1.2mb
 *
 *  * iOS 8.1 (iPhone 6) WKWebView 64-bit 1.4mb
 *
 *  @warning Please weak link the WebKit.framework so that we can instantiate the WKWebView 
 *  when available but still be able to deploy for older iOS versions using UIWebView.
 */
@interface WSJSExecutor : NSObject

/**
 *  Delegate of our JSExecutor.
 */
@property (nonatomic, weak) id<WSJSExecutorDelegate> delegate;

/**
 *  Initializes the JS environment by automatically selecting the WKWebView if the class is available, otherwise it uses UIWebView as a fallback.
 *  @return Instance of JSExecutor
 */
-(instancetype)init;

/**
 *  Initialize the JS environment by using a WKWebView.
 *  @return Instance of JSExecutor
 */
-(instancetype)initUsingWKWebView;

/**
 *  Initialize the JS environment by using a UIWebView. 
 *  You might want to do this for legacy reasons or different supported Web APIs.
 *  @return Instance of JSExecutor
 */
-(instancetype)initUsingUIWebView;

/**
 *  Initialize the JSExecutor with a URL.
 *  @param url The URL to load
 *  @return Instance of JSExecutor
 */
-(instancetype)initWithURL:(NSURL *)url;

/**
 *  Initialize the JSExecutor with an HTML string and base URL.
 *  @param html The html string to inject.
 *  @param url The URL set as the base URL for subsequent loads to treat as the domain/current location.
 *  @return Instance of JSExecutor
 */
-(instancetype)initWithHTMLString:(NSString *)html baseURL:(NSURL *)url;

/**
 *  Tell the Javascript engine to load some URL.
 *  @param url The URL to load.
 */
-(void)loadURL:(NSURL *)url;

/**
 *  Inject some HTML into the Javascript engine
 *  @param html String representing HTML content.
 *  @param url  he base url to use for relative paths/security domains etc.
 */
-(void)loadHTMLString:(NSString *)html baseURL:(NSURL *)url;

/**
 *  Run some code on the Javascript engine.
 *  @param scriptString The script you want to evaluate.
 */
-(void)evaluateJavaScript:(NSString *)javaScriptString;

/**
 *  Run some code on the Javascript engine.
 *  @param scriptString The script you want to evaluate.
 *  @param completion Block that is fired when the passed script has been evaluated by the 
 *  Javascipt engine. The block will continue the result of evaluating the script.
 */
-(void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(CompletionHandler)completion;

@end
