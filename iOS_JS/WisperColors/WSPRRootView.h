//
//  WSPRRootView.h
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 17/12/15.
//  Copyright © 2015 Widespace . All rights reserved.
//

#import "WSPRObject.h"
#import "WSPRViewParentProtocol.h"
#import <UIKit/UIKit.h>

@interface WSPRRootView : WSPRObject <WSPRViewParentProtocol>

//The view we are controlling
@property (nonatomic, assign) UIView *view; //Remember that this is an assigned reference!
@property (nonatomic, assign) BOOL ownsConnectedView;

//Wisper interface properties
@property (nonatomic, strong) NSDictionary *frame;
@property (nonatomic, strong) NSNumber *opacity;
@property (nonatomic, strong) NSNumber *userInteractionEnabled;
@property (nonatomic, weak) WSPRRootView *superview;

/**
 *  Designated initializer, if used you may specify what view you want to controll. If the regular -init method is used a view will be created for you.
 *  @param view The View you want this object to be controlling and listening to.
 *  @return An instance of this object connected with the passed view.
 */
- (instancetype)initWithView:(UIView *)view;

@end
