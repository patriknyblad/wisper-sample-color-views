//
//  JavaScriptRuntime.h
//  WisperColors
//
//  Created by Patrik Nyblad on 2017-05-23.
//  Copyright © 2017 WidespaceAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Wisper/WSPRGatewayRouter.h>
#import "WSJSExecutor.h"

@interface JavaScriptRuntime : NSObject

@property (nonatomic, readonly) WSPRGatewayRouter *gatewayRouter;
@property (nonatomic, readonly) WSJSExecutor *jsExecutor;

+(instancetype)sharedInstance;

@end
