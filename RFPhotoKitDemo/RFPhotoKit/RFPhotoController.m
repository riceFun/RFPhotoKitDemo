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
#define rfCollectionViewCellReusedKey @"rfCollectionViewCellReusedKey"
#define rfTableViewCellReusedKey @"rfTableViewCellReusedKey"

@interface RFPhotoController ()<UICollectionViewDataSource,UICollectionViewDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)UIButton *albumSelectBtn;
@property (nonatomic,strong)UICollectionView *photoCollectView;
@property (nonatomic,strong)UITableView *albumlistView;

@property (nonatomic,strong)NSArray<PHAssetCollection *> *allAlbum;//所有相册
@property (nonatomic,strong)NSString *currentAssetCollectionLocalIdentifier;//用于判断当前是在哪个相册中
@property (nonatomic,strong)PHFetchResult<PHAsset *> *currentAlbum;//当前相册
@property (nonatomic,strong)NSMutableArray *selectedAssets;//选中的Asset

@end

@implementation RFPhotoController

#pragma mark lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self setupUI];    
}

#pragma mark public
- (void)rfPhotoKitSelectedBlock:(RFPhotoResultBlock)photoResultBlock{
    objc_setAssociatedObject(self, rfPhotoKitkey, photoResultBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark privite
- (void)initData{
    NSArray *pAllAlbum = [RFPHOTOKIT_INSTANCE rf_queryAllAlbums];
    NSMutableArray *tempAllAlbum = [[NSMutableArray alloc] initWithCapacity:5];
    for (PHAssetCollection *sub in pAllAlbum) {
        PHFetchResult *result = [RFPHOTOKIT_INSTANCE rf_queryFetchResultWithAssetCollection:sub mediaType:(PHAssetMediaTypeImage) ascend:NO];
        //去掉内容为空的相册
        if (result.count > 0) {
            [tempAllAlbum addObject:sub];
        }
    }
    
    self.allAlbum = [tempAllAlbum copy];
    self.currentAssetCollectionLocalIdentifier = self.allAlbum.firstObject.localIdentifier;
    self.currentAlbum = [RFPHOTOKIT_INSTANCE rf_queryFetchResultWithAssetCollection:self.allAlbum.firstObject mediaType:(PHAssetMediaTypeImage) ascend:NO];

}

- (void)setupUI{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finishSelected)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(finishBack)];
    self.navigationItem.titleView = self.albumSelectBtn;
    [self.view addSubview:self.photoCollectView];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1]];
}

- (void)finishBack{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)finishSelected{
    __weak __typeof(self)weakSelf = self;
    [RFPHOTOKIT_INSTANCE rf_getImagesForAssets:self.selectedAssets progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
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

- (void)addAssetToSelectedAssetsWithIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.currentAlbum[indexPath.item];
    if (![self.selectedAssets containsObject:asset]) {
        [self.selectedAssets addObject:asset];
    }
}

- (void)removeAssetToSelectedAssetsWithIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.currentAlbum[indexPath.item];
    if ([self.selectedAssets containsObject:asset]) {
        [self.selectedAssets removeObject:asset];
    }
}

#pragma mark -UICollectionViewDataSource,UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.currentAlbum.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    RFPhotoCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:rfCollectionViewCellReusedKey forIndexPath:indexPath];
       
    PHAsset *asset = self.currentAlbum[indexPath.item];
    //设置选中按钮图片
    cell.selectedBtn.selected = NO;
    for (PHAsset *pAsset in self.selectedAssets) {
        if ([asset.localIdentifier isEqualToString:pAsset.localIdentifier]) {
            cell.selectedBtn.selected = YES;
        }
    }
    
    #pragma mark 单个图片资源
    //请求低质量的小图
    [RFPHOTOKIT_INSTANCE rf_getImageLowQualityForAsset:asset targetSize:cell.frame.size resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            cell.image = result;
        }
    }];
    
    #pragma mark 选择按钮点击事件处理
    __weak __typeof(self)weakSelf = self;
    [cell setBtnClickBlock:^(UIButton *button){
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (button.selected) {
            if (weakSelf.selectedAssets.count >= self.permitPicCount) {
                button.selected = NO;
                NSString *title = [NSString stringWithFormat:@"最多选择%ld张照片",(long)self.permitPicCount];
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:(UIAlertControllerStyleAlert)];
                [alertVC addAction:[UIAlertAction actionWithTitle:@"知道了" style:(UIAlertActionStyleCancel) handler:nil]];
                [strongSelf.navigationController presentViewController:alertVC animated:YES completion:nil];
                return;
            }
            [strongSelf addAssetToSelectedAssetsWithIndexPath:indexPath];
        }else{
            [strongSelf removeAssetToSelectedAssetsWithIndexPath:indexPath];
        }
    }];
    
    return cell;
}

#pragma mark UITableViewDelegate,UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allAlbum.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:rfTableViewCellReusedKey];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rfTableViewCellReusedKey];
        cell.backgroundColor = [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    PHAssetCollection *assetCollection = self.allAlbum[indexPath.row];
    PHFetchResult *result = [RFPHOTOKIT_INSTANCE rf_queryFetchResultWithAssetCollection:assetCollection mediaType:(PHAssetMediaTypeImage) ascend:NO];
    
    NSString *albumName = [RFPHOTOKIT_INSTANCE rf_albumChineseNameWithAssetCollection:assetCollection];
    
//    NSLog(@"\"%@\":\"\",",albumName);
    NSString *title = [NSString stringWithFormat:@"%@ (%lu)",albumName,(unsigned long)result.count];
    cell.textLabel.text = title;
    
    NSLog(@"indexLocalIdentifier: %@\ncurrentLocalIdentifier: %@",assetCollection.localIdentifier,self.currentAssetCollectionLocalIdentifier);
    if ([assetCollection.localIdentifier isEqualToString:self.currentAssetCollectionLocalIdentifier]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *assetCollection = self.allAlbum[indexPath.row];
    PHFetchResult *result = [RFPHOTOKIT_INSTANCE rf_queryFetchResultWithAssetCollection:assetCollection mediaType:(PHAssetMediaTypeImage) ascend:NO];
    self.currentAssetCollectionLocalIdentifier = assetCollection.localIdentifier;
    NSLog(@"localIdentifier--> %@",assetCollection.localIdentifier);
    self.currentAlbum = result;
    [self.photoCollectView reloadData];
    //关闭相册选择页面
    [self click_albumSelectBtn:self.albumSelectBtn];
}

#pragma mark userEvent
- (void)click_albumSelectBtn:(UIButton *)button {
    button.selected = !button.selected;
    if (button.selected) {//选中 显示albumlistView
        [self.view addSubview:self.albumlistView];
        [UIView animateWithDuration:0.5 animations:^{
            self.albumlistView.frame = self.view.bounds;
            [self.albumlistView reloadData];
        }];
    } else {//移除albumlistView
        [UIView animateWithDuration:0.5 animations:^{
            self.albumlistView.frame = CGRectMake(0, -self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
        } completion:^(BOOL finished) {
            [self.albumlistView removeFromSuperview];
        }];
    }
}

#pragma mark -lazyLoad
- (UIButton *)albumSelectBtn {
    if (!_albumSelectBtn) {
        _albumSelectBtn = [[UIButton alloc] init];
        [_albumSelectBtn setTitle:@" 切换相册 " forState:(UIControlStateNormal)];
        [_albumSelectBtn setBackgroundColor:[UIColor blueColor]];
        [_albumSelectBtn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [_albumSelectBtn addTarget:self action:@selector(click_albumSelectBtn:) forControlEvents:(UIControlEventTouchUpInside)];
        _albumSelectBtn.layer.cornerRadius = 5;
    }
    return _albumSelectBtn;
}

- (UITableView *)albumlistView {
    if (!_albumlistView) {
        _albumlistView = [[UITableView alloc] initWithFrame:CGRectMake(0, -self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height) style:(UITableViewStylePlain)];
        _albumlistView.delegate = self;
        _albumlistView.dataSource = self;
        _albumlistView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _albumlistView.backgroundColor = [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1];
    }
    return _albumlistView;
}

- (UICollectionView *)photoCollectView{
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
         [_photoCollectView registerNib:[UINib nibWithNibName:@"RFPhotoCell" bundle:nil] forCellWithReuseIdentifier:rfCollectionViewCellReusedKey];
        _photoCollectView.backgroundColor = [UIColor colorWithRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1];
    }
    return _photoCollectView;
}

- (NSMutableArray *)selectedAssets{
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray arrayWithCapacity:0];
    }
    return _selectedAssets;
}

@end
