//
//  RFPhotoController.h
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/3.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFPhotoKitManager.h"
#import "RFPhotoKitConstant.h"

typedef  void(^RFPhotoResultBlock)(NSArray *result);

@interface RFPhotoController : UIViewController
@property (nonatomic,assign) NSInteger permitPicCount;

-(void)rfPhotoKitSelectedBlock:(RFPhotoResultBlock)photoResultBlock;

@end
