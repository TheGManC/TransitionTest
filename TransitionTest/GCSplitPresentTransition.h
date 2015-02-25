//
//  GCSplitPresentTransition.h
//  TransitionTest
//
//  Created by Graham Connolly on 16/02/2015.
//  Copyright (c) 2015 Graham Connolly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GCSplitPresentTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic)  UIView * sourceView;
@end
