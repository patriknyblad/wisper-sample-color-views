//
//  WSPRRootView.m
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 17/12/15.
//  Copyright © 2015 Widespace . All rights reserved.
//

#import "WSPRRootView.h"
#import "WSPRView.h"
#import "WSPRInstanceRegistry.h"

@interface WSPRRootView () 

@property (nonatomic, strong) NSArray *subviewReferences;
@property (nonatomic, strong) NSArray *wisperViews;
@property (nonatomic, strong) UIView *retainedView;
@property (nonatomic, assign) BOOL isUpdatingChildren;

@end

@implementation WSPRRootView

+(WSPRClass *)rpcRegisterClass
{
    // Create a class representation compatible with RPC
    WSPRClass *wisperClass = [super rpcRegisterClass];
    
    WSPRClassProperty *frameProperty = [WSPRClassProperty propertyWithMapName:@"frame"
                                                                      keyPath:@"view.frame"
                                                                         type:WSPR_PARAM_TYPE_DICTIONARY
                                                                      andMode:WSPRPropertyModeReadWrite];
    [frameProperty setSerializeWisperPropertyBlock:^id(NSObject *propertyValue) {
        CGRect rect = [(NSValue *)propertyValue CGRectValue];
        return [[self class] rectDictionaryFromRect:rect];
    }];
    [frameProperty setDeserializeWisperPropertyBlock:^id(NSObject *wisperValue) {
        NSDictionary *rectDictionary = (NSDictionary *)wisperValue;
        return [NSValue valueWithCGRect:[[self class] rectFromRectDictionary:rectDictionary]];
    }];
    [wisperClass addProperty:frameProperty];
    
    WSPRClassProperty *colorProperty = [WSPRClassProperty propertyWithMapName:@"color"
                                                                      keyPath:@"view.backgroundColor"
                                                                         type:WSPR_PARAM_TYPE_DICTIONARY
                                                                      andMode:WSPRPropertyModeReadWrite];
    [colorProperty setSerializeWisperPropertyBlock:^id(NSObject *propertyValue) {
        UIColor *backgroundColor = (UIColor *)propertyValue;
        return [[self class] rgbaDictionaryFromColor:backgroundColor];
    }];
    [colorProperty setDeserializeWisperPropertyBlock:^id(NSObject *wisperValue) {
        NSDictionary *rgbaDictionary = (NSDictionary *)wisperValue;
        return [[self class] colorFromRGBADictionary:rgbaDictionary];
    }];
    [wisperClass addProperty:colorProperty];
    
    WSPRClassProperty *transformProperty = [WSPRClassProperty propertyWithMapName:@"transform"
                                                                          keyPath:@"view.transform"
                                                                             type:WSPR_PARAM_TYPE_DICTIONARY
                                                                          andMode:WSPRPropertyModeReadWrite];
    [transformProperty setSerializeWisperPropertyBlock:^id(NSObject *propertyValue) {
        CGAffineTransform transform = [(NSValue *)propertyValue CGAffineTransformValue];
        return [[self class] transformDictionaryFromTransform:transform];
    }];
    
    [transformProperty setDeserializeWisperPropertyBlock:^id(NSObject *wisperValue) {
        NSDictionary *transformDictionary = (NSDictionary *)wisperValue;
        return [NSValue valueWithCGAffineTransform:[[self class] transformFromTransformDictionary:transformDictionary]];
    }];
    
    [wisperClass addProperty:transformProperty];
    
    
    [wisperClass addProperty:[WSPRClassProperty propertyWithMapName:@"children"
                                                            keyPath:@"subviewReferences"
                                                               type:WSPR_PARAM_TYPE_ARRAY
                                                            andMode:WSPRPropertyModeReadWrite]];
    
    [wisperClass addProperty:[WSPRClassProperty propertyWithMapName:@"opacity"
                                                            keyPath:@"opacity"
                                                               type:WSPR_PARAM_TYPE_NUMBER
                                                            andMode:WSPRPropertyModeReadWrite]];
    
    [wisperClass addProperty:[WSPRClassProperty propertyWithMapName:@"userInteractionEnabled"
                                                            keyPath:@"userInteractionEnabled"
                                                               type:WSPR_PARAM_TYPE_NUMBER
                                                            andMode:WSPRPropertyModeReadWrite]];
    
    [wisperClass addInstanceMethod:[[WSPRClassMethod alloc] initWithMapName:@"getAbsolutePosition"
                                                                   selector:@selector(absolutePosition)
                                                                 paramTypes:@[]
                                                              andVoidReturn:NO]];
    
    [wisperClass addInstanceMethod:[[WSPRClassMethod alloc] initWithMapName:@"screenshot"
                                                                   selector:@selector(base64ScreenshotWithQuality:andScale:)
                                                                 paramTypes:@[WSPR_PARAM_TYPE_NUMBER, WSPR_PARAM_TYPE_NUMBER]
                                                              andVoidReturn:NO]];
    

    
    return wisperClass;
}


#pragma mark - Lifecycle

- (instancetype)init
{
    UIView *view = [[UIView alloc] init];
    view.autoresizesSubviews = NO;
    self = [self initWithView:view];
    if (self)
    {
        self.retainedView = view;
        //We are allowed to detach the view if it was created by us.
        self.ownsConnectedView = YES;
    }
    return self;
}

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self)
    {
        self.view = view;
        self.userInteractionEnabled = @YES;
        self.opacity = @1;
    }
    return self;
}

-(void)rpcDestructor
{
    [super rpcDestructor];
    if (_ownsConnectedView)
    {
        [self.view removeFromSuperview];
    }
    self.subviewReferences = @[];
}


#pragma mark - Setters and getters

-(void)setSubviewReferences:(NSArray *)subviewReferences
{
    if (_subviewReferences != subviewReferences)
    {
        self.isUpdatingChildren = YES;
        
        //Make a list of the views that will not be attached to this view anymore
        NSMutableArray *removedSubviewReferences = [NSMutableArray arrayWithArray:_subviewReferences];
        for (NSString *subviewReference in subviewReferences)
        {
            [removedSubviewReferences removeObject:subviewReference];
        }
        
        NSArray *subviews = [self fetchSubviewInstancesForIds:removedSubviewReferences];
        [self removeWisperSubviews:subviews];
        
        //Make a list of new views that where previously not attached to this view
        NSMutableArray *addedSubviewReferences = [NSMutableArray arrayWithArray:subviewReferences];
        for (NSString *subviewReference in _subviewReferences)
        {
            [addedSubviewReferences removeObject:subviewReference];
        }
        
        //Update property
        _subviewReferences = subviewReferences;
        
        subviews = [self fetchSubviewInstancesForIds:addedSubviewReferences];
        [self addWisperSubviews:subviews];
        
        self.isUpdatingChildren = NO;
    }
}

-(void)setOpacity:(NSNumber *)opacity
{
    if (_opacity != opacity)
    {
        _opacity = opacity;
        self.view.layer.opacity = [_opacity floatValue];
    }
}

-(NSDictionary *)absolutePosition
{
    if (!self.view || !self.view.superview)
    {
        return @{@"x" : @0, @"y" : @0};
    }
    
    CGPoint windowPosition = [self.view.superview convertPoint:self.view.frame.origin toView:nil];
    
    return @{@"x" : @(windowPosition.x), @"y" : @(windowPosition.y)};
}


#pragma mark - Private Actions

-(NSArray *)fetchSubviewInstancesForIds:(NSArray *)ids
{
    //Loop through _subviewReferences and fetch each real instance from the RPCController.
    NSMutableArray *subviews = [NSMutableArray array];
    for (NSString *subviewReference in ids)
    {
        NSObject<WSPRClassProtocol> *wisperView = [[WSPRInstanceRegistry instanceWithId:subviewReference underRootRoute:[self.classRouter rootRouter]] instance];
        if (wisperView)
        {
            [subviews addObject:wisperView];
        }
    }
    return [NSArray arrayWithArray:subviews];
}

-(void)removeWisperSubviews:(NSArray *)wisperViews
{
    for (WSPRView *view in wisperViews)
    {
        view.parent = nil;
        [view.view removeFromSuperview];
    }
}

-(void)addWisperSubviews:(NSArray *)wisperViews
{
    for (WSPRView *view in wisperViews)
    {
        view.parent = self;
        [_view addSubview:view.view];
    }
}

-(NSDictionary *)base64ScreenshotWithQuality:(NSNumber *)quality andScale:(NSNumber *)scale
{
    if (!quality)
        quality = @(1.0);
    if (!scale)
        scale = @(0.0);
    
    // Create base64 encoded string from Data
    NSData *imageData = nil;
    if ([quality floatValue] == 1.0)
    {
        imageData = UIImagePNGRepresentation([self screenshotWithScale:[scale floatValue]]);
    }
    else
    {
        imageData = UIImageJPEGRepresentation([self screenshotWithScale:[scale floatValue]], [quality floatValue]);
    }
    
    NSString *imageString = [imageData base64EncodedStringWithOptions:0];
    
    return @{
             @"type" : [quality floatValue] == 1.0 ? @"image/png" : @"image/jpeg",
             @"encoding" : @"base64",
             @"data" : imageString
             };
}

-(UIImage *)screenshotWithScale:(CGFloat)scale
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, [[UIScreen mainScreen] scale] * scale);
    if ([self.view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        //iOS 7
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    }
    else
    {
        //Legacy (not very well with 3D transforms...)
        [self.view.layer.presentationLayer drawInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


#pragma mark - WSPRViewParentProtocol

-(void)view:(WSPRView *)view willChangeToParent:(WSPRRootView *)parent
{
    if (self.isUpdatingChildren)
        return;
    
    WSPRClassInstance *viewInstance = [WSPRInstanceRegistry instanceModelForInstance:view underRootRoute:[self.classRouter rootRouter]];
    if (parent != self && [_subviewReferences containsObject:viewInstance.instanceIdentifier])
    {
        //Remove from compiled views
        NSMutableArray *subviewReferences = [NSMutableArray arrayWithArray:_subviewReferences];
        [subviewReferences removeObject:viewInstance.instanceIdentifier];
        self.subviewReferences = [NSArray arrayWithArray:subviewReferences];
    }
}


#pragma mark - Helpers

+(CGRect)rectFromRectDictionary:(NSDictionary *)rectDictionary
{
    return CGRectMake(
                      [rectDictionary[@"x"] floatValue],
                      [rectDictionary[@"y"] floatValue],
                      [rectDictionary[@"width"] floatValue],
                      [rectDictionary[@"height"] floatValue]
                      );
}

+(NSDictionary *)rectDictionaryFromRect:(CGRect)rect
{
    return @{
             @"x" : @(rect.origin.x),
             @"y" : @(rect.origin.y),
             @"width" : @(rect.size.width),
             @"height" : @(rect.size.height)
             };
}

+(CGAffineTransform)transformFromTransformDictionary:(NSDictionary *)transformDictionary
{
    return CGAffineTransformMake([transformDictionary[@"scaleX"] floatValue],
                                 [transformDictionary[@"skewY"] floatValue],
                                 [transformDictionary[@"skewX"] floatValue],
                                 [transformDictionary[@"scaleY"] floatValue],
                                 [transformDictionary[@"translateX"] floatValue],
                                 [transformDictionary[@"translateY"] floatValue]);
}

+(NSDictionary *)transformDictionaryFromTransform:(CGAffineTransform)transform
{
    return @{
             @"scaleX" : @(transform.a),
             @"skewY" : @(transform.b),
             @"skewX" : @(transform.c),
             @"scaleY" : @(transform.d),
             @"translateX" : @(transform.tx),
             @"translateY" : @(transform.ty)
             };
}

+(UIColor *)colorFromRGBADictionary:(NSDictionary *)rgbaDictionary
{
    return [UIColor colorWithRed:[rgbaDictionary[@"r"] floatValue]
                           green:[rgbaDictionary[@"g"] floatValue]
                            blue:[rgbaDictionary[@"b"] floatValue]
                           alpha:[rgbaDictionary[@"a"] floatValue]];
}

+(NSDictionary *)rgbaDictionaryFromColor:(UIColor *)color
{
    CGFloat r;
    CGFloat g;
    CGFloat b;
    CGFloat a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return @{
             @"r" : @(r),
             @"g" : @(g),
             @"b" : @(b),
             @"a" : @(a)
             };
}


@end
