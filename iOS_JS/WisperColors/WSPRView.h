//
//  WSPRView.h
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 04/12/15.
//  Copyright © 2015 Widespace . All rights reserved.
//

#import "WSPRRootView.h"
#import "WSPRViewParentProtocol.h"

@interface WSPRView : WSPRRootView

@property (nonatomic, weak) WSPRRootView<WSPRViewParentProtocol> *parent;

@end
