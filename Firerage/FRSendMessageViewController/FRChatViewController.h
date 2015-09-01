//
//  FRSendMessageTableViewController.h
//  FirerageKit
//
//  Created by Aidian.Tang on 14-5-21.
//  Copyright (c) 2014年 Illidan.Firerage. All rights reserved.
//

#import "FRSendMessageViewController.h"
#import "UIBubbleTableView.h"

@protocol FRChatViewControllerDelegate;

@interface FRChatViewController : FRSendMessageViewController

@property (nonatomic, weak) IBOutlet id<FRChatViewControllerDelegate> delegate;
@property (strong, nonatomic, readonly) UIBubbleTableView *bubbleTable;
@property (nonatomic, strong) NSArray *bubbleDatas;

@end

@protocol FRChatViewControllerDelegate <NSObject>

@optional
- (void)chatViewController:(FRChatViewController *)chatViewController didSentMessage:(NSString *)message;

@end