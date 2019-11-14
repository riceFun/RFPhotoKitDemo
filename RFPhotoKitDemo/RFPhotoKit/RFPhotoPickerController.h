//
//  RFPhotoPickerController.h
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/3.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFPhotoTool.h"

typedef  void(^RFPhotoResultBlock)(NSArray *result);

@interface RFPhotoPickerController : UIViewController
@property (nonatomic,assign) NSInteger permitPicCount;

-(void)rf_photoPickerSelectedBlock:(RFPhotoResultBlock)photoResultBlock;

@end
