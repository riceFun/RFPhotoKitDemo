//
//  RFPhotoKitManager.h
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/2.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFPhotoKitConstant.h"

#define RFPHOTOKIT_INSTANCE [RFPhotoKitManager sharedInstance]

@interface RFPhotoKitManager : NSObject

+(RFPhotoKitManager *)sharedInstance;

//查询相册访问权限
-(void)rf_checkPhotoAlbumAuthorizationHandler:(void(^)(BOOL isAuthorized))handler;

//获取全部相册
-(NSMutableArray<PHAssetCollection *> *)rf_getAllAlbums;

//获取某个相册的结果集
-(PHFetchResult<PHAsset *> *)rf_getFetchResult:(PHAssetCollection *)assetCollection ascend:(BOOL)ascend;

//根据某种媒体类型获取某种媒体的结果集(按时间排序)
-(PHFetchResult<PHAsset *> *)rf_getFetchResultWithMediaType:(PHAssetMediaType)mediaType ascend:(BOOL)ascend;

//获取低质量的图片
-(void)rf_getImageLowQualityForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler;

//获取高质量的图片
-(void)rf_getImageHighQualityForAsset:(PHAsset *)asset progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler;

//同时获取多张图片(高清)
-(void)rf_getImagesForAssets:(NSArray<PHAsset *> *)assets progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler resultHandler:(void (^)(NSArray<NSDictionary *> *))resultHandler;


@end
