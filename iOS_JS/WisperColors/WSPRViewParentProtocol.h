//
//  WSPRParentViewProtocol.h
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 03/03/16.
//  Copyright © 2016 Widespace . All rights reserved.
//

@class WSPRView;
@class WSPRRootView;

@protocol WSPRViewParentProtocol <NSObject>

-(void)view:(WSPRView *)view willChangeToParent:(WSPRRootView *)parent;

@end
