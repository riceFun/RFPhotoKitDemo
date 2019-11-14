//
//  RFPhotoTool.h
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/2.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface RFPhotoTool : NSObject

//查询相册访问权限
+ (void)rf_checkPhotoAlbumAuthorizationHandler:(void(^)(BOOL isAuthorized))handler;

//查询相机访问权限
+ (void)rf_checkCameraAuthorizationHandler:(void(^)(BOOL isAuthorized))handler;

//获取所有的子相册,包含空的相册
+ (NSArray<PHAssetCollection *> *)rf_queryAllAlbums;

/** 从某个子相册中根据查询类型获取具体的结果集<PHAsset>
 assetCollection 被查询的相册
 ascend 升降序
 mediaType 媒体类型
 */
+ (PHFetchResult<PHAsset *> *) rf_queryFetchResultWithAssetCollection:(PHAssetCollection *)assetCollection mediaType:(PHAssetMediaType)mediaType ascend:(BOOL)ascend;

//根据某种媒体类型获取某种媒体的结果集
+ (PHFetchResult<PHAsset *> *)rf_getFetchResultWithMediaType:(PHAssetMediaType)mediaType ascend:(BOOL)ascend;

+ (PHFetchResult<PHAsset *> *)rf_getCameraRollFetchResulWithAscerf_nd:(BOOL)ascend;

//获取低质量的图片
+ (void)rf_getImageLowQualityForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler;

//获取高质量的图片
+ (void)rf_getImageHighQualityForAsset:(PHAsset *)asset progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler;
//同时获取多张图片(高清)
+ (void)rf_getImagesForAssets:(NSArray<PHAsset *> *)assets progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler resultHandler:(void (^)(NSArray<NSDictionary *> *))resultHandler;

//获取智能相册中文名字
+ (NSString *)rf_albumChineseNameWithAssetCollection:(PHAssetCollection *)assetCollection;

@end
