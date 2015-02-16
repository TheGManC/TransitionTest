//
//  DetailViewController.h
//  TransitionTest
//
//  Created by Graham Connolly on 16/02/2015.
//  Copyright (c) 2015 Graham Connolly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

