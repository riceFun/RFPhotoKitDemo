//
//  RFPhotoControl.m
//  RFPhotoKitDemo
//
//  Created by riceFun on 2019/11/14.
//  Copyright © 2019 riceFun. All rights reserved.
//

#import "RFPhotoManager.h"
#import "RFPhotoTool.h"
#import "RFPhotoPickerController.h"

@interface RFPhotoManager ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic,copy) RFPhotoManagerCallBack callBack;

@end

@implementation RFPhotoManager
+ (RFPhotoManager *)sharedInstance{
    static RFPhotoManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RFPhotoManager alloc]init];
    });
    return instance;
}

//拍照获取图片
- (void)rf_PhotoWithTakePhoto_targetVC:(UIViewController *)targetVC callBack:(RFPhotoManagerCallBack)callBack {
    self.callBack = callBack;
    __weak __typeof(self)weakSelf = self;
    [RFPhotoTool rf_checkCameraAuthorizationHandler:^(BOOL isAuthorized) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (isAuthorized) {
            [strongSelf rf_launchCameraWithTargetVC:targetVC];
        } else {
            //未授权
            UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"您没赋予本程序使用相册权限" message:@"是否去设置" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }];
            UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"不去" style:UIAlertActionStyleCancel handler:nil];
            [alertVC addAction:cancel];
            [alertVC addAction:ok];
            [targetVC presentViewController:alertVC animated:NO completion:NULL];
        }
    }];
}

//相册获取图片
- (void)rf_PhotoWithAlbum_targetVC:(UIViewController *)targetVC maxCount:(NSUInteger)maxCount callBack:(RFPhotoManagerCallBack)callBack {
    self.callBack = callBack;
    __weak __typeof(self)weakSelf = self;
    //相册权限
    [RFPhotoTool rf_checkPhotoAlbumAuthorizationHandler:^(BOOL isAuthorized) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (isAuthorized) {//已授权
            //打开相册
            RFPhotoPickerController *vc = [[RFPhotoPickerController alloc]init];
            vc.permitPicCount = maxCount;
            [vc rf_photoPickerSelectedBlock:^(NSArray *result) {
                if (result) {
                    strongSelf.callBack(result);
                }
            }];
            UINavigationController *navi = [[UINavigationController alloc]initWithRootViewController:vc];
            navi.modalPresentationStyle = UIModalPresentationFullScreen;//iOS13适配
            [targetVC presentViewController:navi animated:YES completion:nil];
        }else{//未授权
            UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"您没赋予本程序访问相册权限" message:@"是否去设置" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }];
            UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"不去" style:UIAlertActionStyleCancel handler:nil];
            [alertVC addAction:cancel];
            [alertVC addAction:ok];
            [targetVC presentViewController:alertVC animated:NO completion:NULL];
        }
    }];
}

#pragma mark privite
//打开拍照功能
- (void)rf_launchCameraWithTargetVC:(UIViewController *)targetVC {
    //判断是否支持摄像
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImagePickerController *picker = [[UIImagePickerController alloc]init];//PS:UIImagePickerController一般会显示英文界面，改为中文界面请参考 https://www.jianshu.com/p/6ce6e293b268
            picker.delegate = self;
            picker.sourceType = sourceType;
            picker.allowsEditing = YES;
            [targetVC presentViewController:picker animated:YES completion:nil];
        });
    } else {
        //不支持
        UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"本设备不支持该功能" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:cancel];
        [targetVC presentViewController:alertVC animated:YES completion:NULL];
    }
}

#pragma mark UIImagePickerControllerDelegate
//获取照片
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    /*字典info中key的含义
     UIImagePickerControllerCropRect // 编辑裁剪区域
     UIImagePickerControllerEditedImage // 编辑后的UIImage
     UIImagePickerControllerMediaType // 返回媒体的媒体类型
     UIImagePickerControllerOriginalImage  // 原始的UIImage
     UIImagePickerControllerReferenceURL // 图片地址
     */
    __unused NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    //这里选择使用原始图片
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.callBack(@[image]);
}

// 取消图片选择调用此方法
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
