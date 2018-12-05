//
//  RFPhotoCell.h
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/3.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFPhotoCell : UICollectionViewCell
@property (nonatomic,strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIButton *selectedBtn;
@property (nonatomic,copy) void (^(btnClickBlock))(UIButton *button);

@end
