//
//  RFPhotoController.m
//  RFPhotoKitTest
//
//  Created by riceFun on 2018/5/3.
//  Copyright © 2018年 riceFun. All rights reserved.
//

#import "RFPhotoController.h"
#import "RFPhotoCell.h"

#import <objc/runtime.h>
#import <SVProgressHUD/SVProgressHUD.h>



const void * _Nonnull rfPhotoKitkey;

@interface RFPhotoController ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic,strong)UICollectionView *photoCollectView;

@property (nonatomic,strong)PHFetchResult *allPhotos;
@property (nonatomic,strong)NSMutableArray *selectedArr;

@end

@implementation RFPhotoController

#pragma mark -lazyLoad
-(UICollectionView *)photoCollectView{
    if (!_photoCollectView) {
        UICollectionViewFlowLayout * flowLayout = [[UICollectionViewFlowLayout alloc]init];
        flowLayout.minimumLineSpacing = MARGIN;
        flowLayout.minimumInteritemSpacing = MARGIN;
        CGFloat itemWidth = (RFSCREEN_WIDTH - 5*MARGIN)/4;
//        CGSize ImageSize = CGSizeMake(itemWidth*1.5, itemWidth*1.5);
        flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);;
        flowLayout.sectionInset = UIEdgeInsetsMake(0, MARGIN,0, MARGIN);
        _photoCollectView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 64, RFSCREEN_WIDTH, RFSCREEN_HEIGHT - 64) collectionViewLayout:flowLayout];
        _photoCollectView.delegate = self;
        _photoCollectView.dataSource = self;
        _photoCollectView.backgroundColor = [UIColor whiteColor];
    }
    return _photoCollectView;
}

-(NSMutableArray *)selectedArr{
    if (!_selectedArr) {
        _selectedArr = [NSMutableArray arrayWithCapacity:0];
    }
    return _selectedArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self setupUI];    
}

-(void)setupUI{
    self.title = @"所有图片";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finishSelected)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(finishBack)];
    [self.photoCollectView registerNib:[UINib nibWithNibName:@"RFPhotoCell" bundle:nil] forCellWithReuseIdentifier:@"iiiiiiii"];
    [self.view addSubview:self.photoCollectView];
}

-(void)finishBack{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)finishSelected{
    NSMutableArray * assets = [NSMutableArray array];
    __weak __typeof(self)weakSelf = self;
    for (NSIndexPath * indexPath in self.selectedArr) {
        PHAsset * asset = self.allPhotos[indexPath.item];
        [assets addObject:asset];
    }
        
    [RFPHOTOKIT_INSTANCE rf_getImagesForAssets:assets progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if (error) {
            NSLog(@"iClound error:  %@ ",error);
            [SVProgressHUD dismiss];
            return ;
        }
        [SVProgressHUD showWithStatus:@"同步iCloud中"];
    } resultHandler:^(NSArray<NSDictionary *> *result) {
        [SVProgressHUD dismiss];
        [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
        RFPhotoResultBlock photoResultBlock = objc_getAssociatedObject(self, rfPhotoKitkey);
        if (photoResultBlock) {
            photoResultBlock(result);
        }
    }];
}

-(void)initData{
    self.allPhotos = [RFPHOTOKIT_INSTANCE rf_getFetchResultWithMediaType:(PHAssetMediaTypeImage) ascend:YES];
}

#pragma mark -UICollectionViewDataSource,UICollectionViewDelegate
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.allPhotos.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    RFPhotoCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"iiiiiiii" forIndexPath:indexPath];
    cell.selectedBtn.selected = NO;
    for (NSIndexPath *selectedIndexPath in self.selectedArr) {
        if ([selectedIndexPath isEqual:indexPath]) {
             cell.selectedBtn.selected = YES;
        }
    }
    
#pragma mark 选择按钮点击事件处理
    __weak __typeof(self)weakSelf = self;
    [cell setBtnClickBlock:^(UIButton *button){
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (button.selected) {
            if (weakSelf.selectedArr.count >= self.permitPicCount) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"最多选择%ld张照片",(long)self.permitPicCount]];
                button.selected = NO;
                return ;
            }
            [strongSelf.selectedArr addObject:indexPath];
        }else{
            [strongSelf.selectedArr removeObject:indexPath];
        }
    }];
    
#pragma mark 单个图片资源
    PHAsset *asset = self.allPhotos[indexPath.item];
    [RFPHOTOKIT_INSTANCE rf_getImageLowQualityForAsset:asset targetSize:cell.frame.size resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            cell.image = result;
        }
    }];
    
    return cell;
}

-(void)rfPhotoKitSelectedBlock:(RFPhotoResultBlock)photoResultBlock{
    objc_setAssociatedObject(self, rfPhotoKitkey, photoResultBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


@end
