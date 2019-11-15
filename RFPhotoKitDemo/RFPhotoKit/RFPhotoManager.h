//
//  RFPhotoManager.h
//  RFPhotoKitDemo
//
//  Created by riceFun on 2019/11/14.
//  Copyright © 2019 riceFun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^RFPhotoManagerCallBack)(NSArray *photos);
@interface RFPhotoManager : NSObject
+ (RFPhotoManager *)sharedInstance;
//拍照获取图片
- (void)rf_PhotoWithTakePhoto_targetVC:(UIViewController *)targetVC callBack:(RFPhotoManagerCallBack)callBack;
//相册获取图片
- (void)rf_PhotoWithAlbum_targetVC:(UIViewController *)targetVC maxCount:(NSUInteger)maxCount callBack:(RFPhotoManagerCallBack)callBack;

@end

NS_ASSUME_NONNULL_END
