//
//  ViewController.m
//  RFPhotoKitDemo
//
//  Created by riceFun on 2018/12/5.
//  Copyright © 2018 riceFun. All rights reserved.
//

#import "ViewController.h"
#import "RFPhotoManager.h"

@interface ViewController ()
@property (nonatomic,strong) UITextView *textView;

@end

@implementation ViewController

-(UITextView *)textView{
    if (!_textView) {
        _textView = [[UITextView alloc]initWithFrame:self.view.bounds];
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;
    }
    return _textView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.textView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIBarButtonItem *album = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(enterPhotoAlbum:)];
    UIBarButtonItem *takePhoto = [[UIBarButtonItem alloc] initWithTitle:@"拍照" style:UIBarButtonItemStylePlain target:self action:@selector(takePhoto:)];
    self.navigationItem.rightBarButtonItems = @[album,takePhoto];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清除" style:UIBarButtonItemStylePlain target:self action:@selector(clearPhotoAlbum:)];
}

- (void)takePhoto:(UIBarButtonItem *)item {
    __weak __typeof(self)weakSelf = self;
    [[RFPhotoManager sharedInstance] rf_PhotoWithTakePhoto_targetVC:self callBack:^(NSArray * _Nonnull photos) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setTextViewWithPhotos:photos];
    }];
}

-(void)enterPhotoAlbum:(UIBarButtonItem *)item{
    __weak __typeof(self)weakSelf = self;
    [[RFPhotoManager sharedInstance] rf_PhotoWithAlbum_targetVC:self maxCount:6 callBack:^(NSArray * _Nonnull photos) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setTextViewWithPhotos:photos];
    }];
}

- (void)clearPhotoAlbum:(UIBarButtonItem *)item{
    [self.textView setText:@""];
}

-(void)setTextViewWithPhotos:(NSArray*)photos{
    for (UIImage * image in photos) {
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
        CGFloat _widthRadio = [UIScreen mainScreen].bounds.size.width / image.size.width;
        CGFloat _imageHeight = image.size.height * _widthRadio;
        displaySize = CGSizeMake([UIScreen mainScreen].bounds.size.width, _imageHeight);
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
