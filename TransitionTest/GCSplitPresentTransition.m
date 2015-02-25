//
//  GCSplitPresentTransition.m
//  TransitionTest
//
//  Created by Graham Connolly on 16/02/2015.
//  Copyright (c) 2015 Graham Connolly. All rights reserved.
//

#import "GCSplitPresentTransition.h"

@implementation GCSplitPresentTransition


-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{

    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *inView = [transitionContext containerView];
    UIView *masterView =  fromVC.view;
    UIView *detailView = toVC.view;
    
   
    detailView.frame = [transitionContext finalFrameForViewController:toVC];
    
    
    // add the to VC's view to the intermediate view (where it has to be at the
    // end of the transition anyway). We'll hide it during the transition with
    // a blank view. This ensures that renderInContext of the 'To' view will
    // always render correctly
    [inView addSubview:toVC.view];
    
    // if the detail view is a UIScrollView (eg a UITableView) then
    // get its content offset so we get the snapshot correctly
    CGPoint detailContentOffset = CGPointMake(.0, .0);
    if ([detailView isKindOfClass:[UIScrollView class]]) {
        detailContentOffset = ((UIScrollView *)detailView).contentOffset;
    }
    
    // if the master view is a UIScrollView (eg a UITableView) then
    // get its content offset so we get the snapshot correctly and
    // so we can correctly calculate the split point for the zoom effect
    CGPoint masterContentOffset = CGPointMake(.0, .0);
    if ([masterView isKindOfClass:[UIScrollView class]]) {
        masterContentOffset = ((UIScrollView *) masterView).contentOffset;
    }
    
    // Take a snapshot of the detail view
    // use renderInContext: instead of the new iOS7 snapshot API as that
    // only works for views that are currently visible in the view hierarchy
    UIGraphicsBeginImageContextWithOptions(detailView.bounds.size, detailView.opaque, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0, -detailContentOffset.y);
    [detailView.layer renderInContext:ctx];
    UIImage *detailSnapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // take a snapshot of the master view
    // use renderInContext: instead of the new iOS7 snapshot API as that
    // only works for views that are currently visible in the view hierarchy
    UIGraphicsBeginImageContextWithOptions(masterView.bounds.size, masterView.opaque, 0);
    ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0, -masterContentOffset.y);
    [masterView.layer renderInContext:ctx];
    UIImage *masterSnapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // get the rect of the source cell in the coords of the from view
    CGRect sourceRect = [masterView convertRect:self.sourceView.bounds fromView:self.sourceView];
    CGFloat splitPoint = sourceRect.origin.y + sourceRect.size.height - masterContentOffset.y;
    CGFloat scale = [UIScreen mainScreen].scale;
    
    // split the master view snapshot into two parts, splitting
    // below the master view (usually a UITableViewCell) that originated the transition
    CGImageRef masterImgRef = masterSnapshot.CGImage;
    CGImageRef topImgRef = CGImageCreateWithImageInRect(masterImgRef, CGRectMake(0, 0, masterSnapshot.size.width * scale, splitPoint * scale));
    UIImage *topImage = [UIImage imageWithCGImage:topImgRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(topImgRef);
    
    CGImageRef bottomImgRef = CGImageCreateWithImageInRect(masterImgRef, CGRectMake(0, splitPoint * scale,  masterSnapshot.size.width * scale, (masterSnapshot.size.height - splitPoint) * scale));
    UIImage *bottomImage = [UIImage imageWithCGImage:bottomImgRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(bottomImgRef);
    
    // create views for the top and bottom parts of the master view
    UIImageView *masterTopView = [[UIImageView alloc] initWithImage:topImage];
    UIImageView *masterBottomView = [[UIImageView alloc] initWithImage:bottomImage];
    CGRect bottomFrame = masterBottomView.frame;
    bottomFrame.origin.y = splitPoint;
    masterBottomView.frame = bottomFrame;
    
    // setup the inital and final frames for the master view top and bottom
    // views depending on whether we're doing a push or a pop transition
    CGRect masterTopEndFrame = masterTopView.frame;
    CGRect masterBottomEndFrame = masterBottomView.frame;
   
        masterTopEndFrame.origin.y = -(masterTopEndFrame.size.height - sourceRect.size.height);
        masterBottomEndFrame.origin.y += masterBottomEndFrame.size.height;
       
    CGFloat initialAlpha =  1.0;
    CGFloat finalAlpha =  1.0;
    
    // create views to cover the master top and bottom views so that
    // we can fade them in / out
    UIView *masterTopFadeView = [[UIView alloc] initWithFrame:masterTopView.frame];
    masterTopFadeView.backgroundColor = masterView.backgroundColor;
    masterTopFadeView.alpha = initialAlpha;
    
    UIView *masterBottomFadeView = [[UIView alloc] initWithFrame:masterBottomView.frame];
    masterBottomFadeView.backgroundColor = masterView.backgroundColor;
    masterBottomFadeView.alpha = initialAlpha;
    
    // create snapshot view of the to view
    UIImageView *detailSmokeScreenView = [[UIImageView alloc] initWithImage:detailSnapshot];
    // for a push transition, make the detail view small, to be zoomed in
    // for a pop transition, the detail view will be zoomed out, so it starts without
    // a transform
  
    
    // create a background view so that we don't see the actual VC
    // views anywhere - start with a blank canvas.
    UIView *backgroundView = [[UIView alloc] initWithFrame:inView.frame];
    //backgroundView.backgroundColor = self.transitionBackgroundColor;
    
    // add all the views to the transition view
    [inView addSubview:backgroundView];
    [inView addSubview:detailSmokeScreenView];
    [inView addSubview:masterTopView];
    [inView addSubview:masterTopFadeView];
    [inView addSubview:masterBottomView];
    [inView addSubview:masterBottomFadeView];
    
    NSTimeInterval totalDuration = [self transitionDuration:transitionContext];
    
    [UIView animateKeyframesWithDuration:totalDuration
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionCalculationModeLinear
                              animations:^{
                                  // move the master view top and bottom views (and their
                                  // respective fade views) to where we wna them to end up
                                  masterTopView.frame = masterTopEndFrame;
                                  masterTopFadeView.frame = masterTopEndFrame;
                                  masterBottomView.frame = masterBottomEndFrame;
                                  masterBottomFadeView.frame = masterBottomEndFrame;
                                  // zoom the detail view in or out, depending on whether we're doing a push
                                  // or pop transition
                                
                                      detailSmokeScreenView.layer.transform = CATransform3DMakeAffineTransform(CGAffineTransformIdentity);
                                  
                                  
                                  // fade out (or in) the master view top and bottom views
                                  // want the fade out animation to happen near the end of the transition
                                  // and the fade in animation to happen at the start of the transition
                                  CGFloat fadeStartTime = .5 ;
                                  [UIView addKeyframeWithRelativeStartTime:fadeStartTime relativeDuration:.5 animations:^{
                                      masterTopFadeView.alpha = finalAlpha;
                                      masterBottomFadeView.alpha = finalAlpha;
                                  }];
                              }
                              completion:^(BOOL finished) {
                                  // remove all the intermediate views from the heirarchy
                                  [backgroundView removeFromSuperview];
                                  [detailSmokeScreenView removeFromSuperview];
                                  [masterTopView removeFromSuperview];
                                  [masterTopFadeView removeFromSuperview];
                                  [masterBottomView removeFromSuperview];
                                  [masterBottomFadeView removeFromSuperview];
                                  
                                  if ([transitionContext transitionWasCancelled]) {
                                      // we added this at the start, so we have to remove it
                                      // if the transition is canccelled
                                      [toVC.view removeFromSuperview];
                                      [transitionContext completeTransition:NO];
                                  } else {
                                      [fromVC.view removeFromSuperview];
                                      [transitionContext completeTransition:YES];
                                  }
                              }];

}

-(NSTimeInterval) transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    return 0.3;
}

@end
