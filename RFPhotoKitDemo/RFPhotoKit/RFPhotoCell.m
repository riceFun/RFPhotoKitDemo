//
//  RFPhotoCell.m
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/3.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import "RFPhotoCell.h"
@interface RFPhotoCell()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation RFPhotoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor whiteColor];
    
    [self.selectedBtn setImage:[UIImage imageNamed:@"normal.png"] forState:UIControlStateNormal];
    [self.selectedBtn setImage:[UIImage imageNamed:@"selected.png"] forState:UIControlStateSelected];
    [self.selectedBtn addTarget:self action:@selector(changeBtnStatus:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)setImage:(UIImage *)image{
    _image = image;
    _imageView.image = image;
}

-(void)changeBtnStatus:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (self.btnClickBlock){
        self.btnClickBlock(btn);
    }
}


@end
