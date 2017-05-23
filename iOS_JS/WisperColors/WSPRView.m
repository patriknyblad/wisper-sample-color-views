//
//  WSPRView.m
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 04/12/15.
//  Copyright © 2015 Widespace . All rights reserved.
//

#import "WSPRView.h"
@interface WSPRView ()

@property (nonatomic, strong) UIView *retainedView;

@end

@implementation WSPRView

+(WSPRClass *)rpcRegisterClass
{
    // Create a class representation compatible with RPC
    WSPRClass *rpcClassRepresentation = [super rpcRegisterClass];
    rpcClassRepresentation.classRef = self;
    
    [rpcClassRepresentation addProperty:[WSPRClassProperty propertyWithMapName:@"parent"
                                                                       keyPath:@"parent"
                                                                          type:WSPR_PARAM_TYPE_INSTANCE
                                                                       andMode:WSPRPropertyModeReadOnly]];
    
    [rpcClassRepresentation addInstanceMethod:[[WSPRClassMethod alloc] initWithMapName:@"~"
                                                                              selector:@selector(initWithFrameObject:)
                                                                         andParamTypes:@[WSPR_PARAM_TYPE_DICTIONARY]]];
    
    return rpcClassRepresentation;
}

- (instancetype)initWithFrameObject:(NSDictionary *)dictFrame
{
    self = [self init];
    if (self) {
        self.view.frame = CGRectMake( [dictFrame[@"x"] floatValue], [dictFrame[@"y"] floatValue], [dictFrame[@"width"] floatValue], [dictFrame[@"height"] floatValue] );
    }
    return self;
}

-(void)rpcDestructor
{
    [super rpcDestructor];
    self.parent = nil;
}


-(void)setView:(UIView *)view
{
    [super setView:view];
    self.retainedView = view;
}

-(void)setParent:(WSPRRootView *)parent
{
    if (_parent != parent)
    {
        [_parent view:self willChangeToParent:parent];
        _parent = parent;
    }
}


@end
