//
//  ViewController.m
//  WisperColors
//
//  Created by Patrik Nyblad on 2017-05-23.
//  Copyright © 2017 WidespaceAB. All rights reserved.
//

#import "ViewController.h"
#import "JavaScriptRuntime.h"


@interface WSJSExecutor ()

@property (nonatomic, readonly) UIWebView *legacyWebView;

@end


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [JavaScriptRuntime sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIWebView *jsExecutorWebview = [[[JavaScriptRuntime sharedInstance] jsExecutor] legacyWebView];
    jsExecutorWebview.frame = CGRectMake(20, 20, self.view.frame.size.width - 40, self.view.frame.size.width - 40);
    jsExecutorWebview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:jsExecutorWebview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
