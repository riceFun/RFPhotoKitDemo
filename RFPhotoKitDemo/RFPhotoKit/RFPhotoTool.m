//
//  RFPhotoKitManager.m
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/2.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import "RFPhotoTool.h"
#import <UIKit/UIKit.h>

@interface RFPhotoTool ()

@end

@implementation RFPhotoTool

//查询相册访问权限
+ (void)rf_checkPhotoAlbumAuthorizationHandler:(void(^)(BOOL isAuthorized))handler{
    if (handler) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    handler(YES);
                }else{
                    handler(NO);
                }
            });
        }];
    }
}

//查询相机访问权限
+ (void)rf_checkCameraAuthorizationHandler:(void(^)(BOOL isAuthorized))handler{
    if (handler) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            handler(granted);
        }];
    }
}



//获取所有的子相册,包含空的相册
+ (NSArray<PHAssetCollection *> *)rf_queryAllAlbums {
    NSMutableArray *fetchResult = [NSMutableArray array];
    //获取智能相册
    PHFetchResult *smartAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    for (PHAssetCollection *sub in smartAlbum) {
        [fetchResult addObject:sub];
    }
    //用户创建的相册
    PHFetchResult *userAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *sub in userAlbum) {
        [fetchResult addObject:sub];
    }
    return [fetchResult copy];
}

/** 从某个子相册中根据查询类型获取具体的结果集<PHAsset>
 assetCollection 被查询的相册
 ascend 升降序
 mediaType 媒体类型
 */
+ (PHFetchResult<PHAsset *> *) rf_queryFetchResultWithAssetCollection:(PHAssetCollection *)assetCollection mediaType:(PHAssetMediaType)mediaType ascend:(BOOL)ascend {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    //时间排序
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascend]];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i",mediaType];
    return  [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
}

//根据某种媒体类型获取某种媒体的结果集
+ (PHFetchResult<PHAsset *> *)rf_getFetchResultWithMediaType:(PHAssetMediaType)mediaType ascend:(BOOL)ascend{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    if (@available(iOS 9.0, *)) {
        options.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
    }
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascend]];
    return  [PHAsset fetchAssetsWithMediaType:mediaType options:options];
}

+ (PHFetchResult<PHAsset *> *)rf_getCameraRollFetchResulWithAscerf_nd:(BOOL)ascend{
    //获取系统相册CameraRoll 的结果集
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc]init];
    if (@available(iOS 9.0, *)) {
        fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
    }
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascend]];
    PHFetchResult *smartAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    PHFetchResult *fetch = [PHAsset fetchAssetsInAssetCollection:[smartAlbumsFetchResult objectAtIndex:0] options:fetchOptions];
    return fetch;
}

//获取低质量的图片
+ (void)rf_getImageLowQualityForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler{
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result && resultHandler) {
            resultHandler(result,info);
        }
    }];
}

//获取高质量的图片
+ (void)rf_getImageHighQualityForAsset:(PHAsset *)asset progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler resultHandler:(void (^)(UIImage* result, NSDictionary * info))resultHandler{
    
    CGSize imageSize = [RFPhotoTool rf_imageSizeForAsset:asset];
    PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
    //设置该模式，若本地无高清图会立即返回缩略图，需要从iCloud下载高清，会再次调用resultHandler返回下载后的高清图
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
        
        if (progressHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressHandler(progress,error,stop,info);
            });
        }
    };
    
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        //判断高清图
        //   BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (result && resultHandler) {
            resultHandler(result,info);
        }
    }];
}

//同时获取多张图片(高清)
+ (void)rf_getImagesForAssets:(NSArray<PHAsset *> *)assets progressHandler:(void(^)(double progress, NSError * error, BOOL *stop, NSDictionary * info))progressHandler resultHandler:(void (^)(NSArray<NSDictionary *> *))resultHandler{
    
    NSMutableArray * callBackPhotos = [NSMutableArray array];    //此处在子线程中执行requestImageForAsset原因：options.synchronous设为同步时,options.progressHandler获取主队列会死锁
    NSOperationQueue * queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    
    for (PHAsset * asset in assets) {
        CGSize imageSize = [RFPhotoTool rf_imageSizeForAsset:asset];
        PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
        //        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.networkAccessAllowed = YES;
        //同步保证取出图片顺序和选择的相同，deliveryMode默认为PHImageRequestOptionsDeliveryModeHighQualityFormat
        options.synchronous = YES;
        
        options.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
            dispatch_async(dispatch_get_main_queue(), ^{
                progressHandler(progress,error,stop,info);
            });
        };
        
        NSBlockOperation * op = [NSBlockOperation blockOperationWithBlock:^{
            [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                //resultHandler默认在主线程，requestImageForAsset在子线程执行后resultHandler变为在子线程
                if (result) {
                    [callBackPhotos addObject:result];
                    if (resultHandler && callBackPhotos.count == assets.count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            resultHandler(callBackPhotos);
                        });
                    }
                }
            }];
        }];
        [queue addOperation:op];
    }
}

//获取智能相册中文名字
+ (NSString *)rf_albumChineseNameWithAssetCollection:(PHAssetCollection *)assetCollection {
    
    //如果是智能相册，那么要获取对应的中文名字
    if (assetCollection.assetCollectionType == PHAssetCollectionTypeSmartAlbum) {
        if ([RFPhotoTool isChinese:assetCollection.localizedTitle]) {//如果是中文，说明已经做了本地化处理，直接返回相册名称
            return assetCollection.localizedTitle;
        }
        NSDictionary *nameMatchDic = @{
            @"Bursts":@"连拍快照",
            @"Screenshots":@"截屏",
            @"Panoramas":@"全景照片",
            @"Hidden":@"隐藏",
            @"Long Exposure":@"长曝光",
            @"Animated":@"动图",
            @"Recents":@"最近项目",
            @"Slo-mo":@"慢动作",
            @"Portrait":@"人像",
            @"Time-lapse":@"延时",
            @"Videos":@"视频",
            @"Live Photos":@"实况照片",
            @"Selfies":@"自拍",
            @"Favorites":@"个人收藏",
        };
        
        NSString *albumChineseName = nameMatchDic[assetCollection.localizedTitle];
        return albumChineseName ? albumChineseName : @"未知相册";
    } else {
        return assetCollection.localizedTitle ? assetCollection.localizedTitle : @"未知相册";
    }
}

#pragma mark private method
+ (CGSize)rf_imageSizeForAsset:(PHAsset *)asset{
    CGFloat photoWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat multiple = [UIScreen mainScreen].scale;
    CGFloat aspectRatio = asset.pixelWidth / (CGFloat)asset.pixelHeight;
    CGFloat pixelWidth = photoWidth * multiple;
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    return  CGSizeMake(pixelWidth, pixelHeight);
}

+ (BOOL)isChinese:(NSString *)string{
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:string];
}

@end
