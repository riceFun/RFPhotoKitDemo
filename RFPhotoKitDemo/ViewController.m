//
//  ViewController.m
//  RFPhotoKitDemo
//
//  Created by riceFun on 2018/12/5.
//  Copyright © 2018 riceFun. All rights reserved.
//

#import "ViewController.h"
#import "RFPhotoController.h"


@interface ViewController ()
@property (nonatomic,strong) UITextView *textView;

@end

@implementation ViewController

-(UITextView *)textView{
    if (!_textView) {
        _textView = [[UITextView alloc]initWithFrame:CGRectMake(0, 64, RFSCREEN_WIDTH, RFSCREEN_HEIGHT - 64)];
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;
    }
    return _textView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.textView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(enterPhotoAlbum:)];
}


-(void)enterPhotoAlbum:(UIBarButtonItem *)item{
    //相册权限
    [RFPHOTOKIT_INSTANCE rf_checkPhotoAlbumAuthorizationHandler:^(BOOL isAuthorized) {
        if (isAuthorized) {//已授权
            //打开相册
            RFPhotoController *vc = [[RFPhotoController alloc]init];
            vc.permitPicCount = 6;
            [vc rfPhotoKitSelectedBlock:^(NSArray<NSDictionary *> *result) {
                [self setTextViewWithPhotos:result];
                NSLog(@"dddd");
            }];
            UINavigationController *navi = [[UINavigationController alloc]initWithRootViewController:vc];
            [self.navigationController presentViewController:navi animated:YES completion:nil];
        }else{//未授权
            UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"您没赋予本程序相机权限" message:@"是否去设置" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }];
            UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"不去" style:UIAlertActionStyleCancel handler:nil];
            [alertVC addAction:cancel];
            [alertVC addAction:ok];
            [self presentViewController:alertVC animated:NO completion:NULL];
            
        }
    }];
}

-(void)setTextViewWithPhotos:(NSArray*)photos{
    for (NSDictionary * dic in photos) {
        UIImage * image = dic[RFPhotoImage];
        NSUInteger location = self.textView.selectedRange.location ;
        NSTextAttachment * attachMent = [[NSTextAttachment alloc] init];
        attachMent.image = image;
        CGSize size = [self displaySizeWithImage:image];
        attachMent.bounds = CGRectMake(0, 0, size.width,size.height);
        NSAttributedString * attStr = [NSAttributedString attributedStringWithAttachment:attachMent];
        NSMutableAttributedString *textViewString = [self.textView.attributedText mutableCopy];
        [textViewString insertAttributedString:attStr atIndex:location];
        
        [textViewString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:19] range:NSMakeRange(0, textViewString.length)];
        self.textView.attributedText = textViewString;
        self.textView.selectedRange = NSMakeRange(location + 1,0);
    }
}


//显示图片的大小 （全屏）
- (CGSize)displaySizeWithImage:(UIImage *)image {
    CGSize displaySize;
    if (image.size.width !=0 ) {
        CGFloat _widthRadio = RFSCREEN_WIDTH / image.size.width;
        CGFloat _imageHeight = image.size.height * _widthRadio;
        displaySize = CGSizeMake(RFSCREEN_WIDTH, _imageHeight);
    }else{
        displaySize = CGSizeZero;
    }
    return displaySize;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
