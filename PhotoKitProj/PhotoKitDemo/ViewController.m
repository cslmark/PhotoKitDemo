//
//  ViewController.m
//  iOSPhotoKit
//
//  Created by Iansl on 2018/10/1.
//  Copyright © 2018 Iansl. All rights reserved.
//

#import "ViewController.h"
#import "CSLMediaManager.h"
#import "MyCell.h"
#import <Photos/Photos.h>
#import "QHPDownLoadCircleProgress.h"
#import "MyCollectionView.h"
#import "QHPPhotoKitHelper.h"
#import "QHPCGRectTool.h"
#import "QHPIcloudPrePlayerView.h"

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, QHOPhotoLibraryHandlerDelegate, UIGestureRecognizerDelegate, QHPPhotoKitChangeDelegate, QHPPhotoKitHelperDelegate>
{
    CGFloat _itemW;
    CGSize _itemSize;
    CGFloat progress;
}
@property (nonatomic, weak) MyCollectionView* collectionView;
@property (nonatomic, strong) NSMutableArray<PHAsset *>* videoList;
@property (nonatomic, strong) NSMutableArray<CellData *>* cellDataSource;
//@property (nonatomic, strong) PHCachingImageManager* cacheManager;
@property (nonatomic, weak) QHPDownLoadCircleProgress* progressView;
@property (nonatomic, strong) PHFetchResult<PHAsset *> *videoFetchResult;
@property (nonatomic, assign) CGRect previousPreheatRect;
@property (nonatomic, weak) QHPIcloudPrePlayerView* IclodeLayer;
@property (nonatomic, copy) NSString* currentIdentifier;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat itemW = (self.view.bounds.size.width - 50)/3;
    _itemW = itemW;
    [self setupUI];
    _itemSize = CGSizeMake(_itemW * 2, 120 * 2);
    
    QHPIcloudPrePlayerView* IclodeLayer = [[QHPIcloudPrePlayerView alloc] initWithFrame:CGRectMake(0, 64, 200, 200)];
    self.IclodeLayer = IclodeLayer;
    [self.view addSubview:IclodeLayer];
//    QHPDownLoadCircleProgress* progressView = [[QHPDownLoadCircleProgress alloc] initWithFrame:CGRectMake(0, 64, 200, 200)];
//    self.progressView = progressView;
//    [self.view addSubview:progressView];
    
    [[QHPPhotoKitHelper shareInstance] reloadData];
    _videoFetchResult = [[QHPPhotoKitHelper shareInstance] videoFetchResult];
    [QHPPhotoKitHelper shareInstance].delegate = self;
    [QHPPhotoKitHelper shareInstance].changeDelegate = self;
    
    
    [self setupDataSource];
    self.previousPreheatRect = CGRectZero;
    
    _itemSize = CGSizeMake(_itemW * 2, 120 * 2);
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    progress += 0.1;
    if(progress > 1){
        progress = 0;
    }
    self.progressView.progress = progress;
}

-(void) setupUI{
    self.title = @"相册视频选择";
    self.view.backgroundColor = [UIColor greenColor];
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(_itemW, 120);
    flowLayout.minimumInteritemSpacing = 10;
    flowLayout.minimumLineSpacing = 10;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.headerReferenceSize = CGSizeMake(self.view.bounds.size.width, 0);
    flowLayout.footerReferenceSize = CGSizeMake(self.view.bounds.size.width, 0);
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    MyCollectionView* collectionView = [[MyCollectionView alloc] initWithFrame:CGRectMake(0, 110, self.view.bounds.size.width, self.view.bounds.size.height-110) collectionViewLayout:flowLayout];
    
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    [collectionView registerClass:[MyCell class] forCellWithReuseIdentifier:@"cslcell"];
}


-(NSMutableArray *)videoList{
    if(_videoList == nil) {
        _videoList = [NSMutableArray arrayWithCapacity:1];
    }
    return _videoList;
}

-(void) setupDataSource{
    [self.videoList removeAllObjects];
    for(NSInteger i = 0; i < self.videoFetchResult.count; i++) {
        PHAsset* asset = self.videoFetchResult[i];
        [self.videoList addObject:asset];
    }
    
    [self updateDataSource];
    [self resetCachedAssets];
    [self updateCachedAssets];
}


#pragma mark - QHOPhotoLibraryHandlerDelegate
- (void)handlerDidUpdate:(CSLMediaManager *)handler{
    [self.videoList removeAllObjects];
    for (NSInteger sectionindex = 0;sectionindex<handler.sections.count;sectionindex++) {
        QHOVideoSection *curVideoSection = [handler.sections objectAtIndex:sectionindex];
        for (NSInteger rowindex = 0;rowindex<curVideoSection.videoResults.count;rowindex++) {
            PHAsset *asset = [curVideoSection.videoResults objectAtIndex:rowindex];
            [self.videoList addObject:asset];
        }
    }
    
    [[QHPPhotoKitHelper shareInstance] startCachingImagesForAssets:self.videoList targetSize:_itemSize];
    
    // Updata DataSource
    [self updateDataSource];
    [self.collectionView reloadData];
}

- (void)handlerDidUpdateIcloudItems:(NSSet *)icloudIdentifiers{
    
}

#pragma mark - private Method
-(void) updateDataSource{
    if(self.cellDataSource == nil) {
        self.cellDataSource = [[NSMutableArray alloc] init];
    }
    NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:1];
    for(NSInteger i = 0; i < self.videoList.count; i++) {
        PHAsset* tempAsset = self.videoList[i];
        CellData* cellData = [self getCellDataWithPHAsset:tempAsset];
        if(cellData) {
            cellData.asset = tempAsset;
            cellData.cellType = PHAssetCellTypeUnKnown;
        } else {
            cellData = [[CellData alloc] initWithPHAsset:tempAsset];
        }
        [tempArray addObject:cellData];
    }
    self.cellDataSource = tempArray;
}


-(CellData *) getCellDataWithPHAsset:(PHAsset *) asset{
    for(NSInteger i = 0; i < self.cellDataSource.count; i++) {
        CellData* tempData = self.cellDataSource[i];
        if([tempData.localIdentifier isEqualToString:asset.localIdentifier]){
            return tempData;
        }
    }
    return nil;
}

#pragma mark - UICollectionViewDataSource Mothods
//谁知多少个section
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.cellDataSource.count;
}

#pragma mark - 添加tap手势处理
-(void) tapClick:(UITapGestureRecognizer *) tap{
    if(tap.view == self.collectionView) {
        NSLog(@"tap 被点击了");
    } else {
        NSLog(@"不需要管。。。。。。。");
    }
}

#pragma mark - 设置每个item上面显示的内容
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cslcell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[MyCell alloc]init];
    }
    cell.tag = indexPath.row;
    
    CellData* data = self.cellDataSource[indexPath.row];
    cell.data = data;
    PHAsset* asset = data.asset;
    
    cell.backgroundColor = [UIColor redColor];
    __typeof(&*self) __weak weakSelf = self;
    
//    if(data.cellType == PHAssetCellTypeUnKnown) {
//        AVAsset* avAsset = [[QHPPhotoKitHelper shareInstance] requestAVAssetWithLocalIdentifier:asset.localIdentifier];
//        if(avAsset) {
//            CellData* data = weakSelf.cellDataSource[indexPath.row];
//            data.avAsset = avAsset;
//            data.cellType = PHAssetCellTypeLocal;
//        } else {
//            data.cellType = PHAssetCellTypeIcloud;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
//            });
//        }
////        [self.cacheManager requestAVAssetForVideo:asset options:videoOption resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
////            if(avAsset) {
////                CellData* data = weakSelf.cellDataSource[indexPath.row];
////                data.avAsset = avAsset;
////                data.cellType = PHAssetCellTypeLocal;
////            } else {
////                data.cellType = PHAssetCellTypeIcloud;
////                dispatch_async(dispatch_get_main_queue(), ^{
////                    [weakSelf.collectionView reloadItemsAtIndexPaths:@[indexPath]];
////                });
////            }
////        }];
//    }
    
    if(data.coverImage == nil) {
        [[QHPPhotoKitHelper shareInstance] requestImageWithPHAsset:asset targetSize:_itemSize resultHandler:^(UIImage *image, NSDictionary *info) {
            if(image){
                cell.image = image;
//                if([info valueForKey:PHImageResultIsDegradedKey]) {
//                    CellData* data = weakSelf.cellDataSource[indexPath.row];
//                    data.coverImage = image;
//                } else {
//                    data.thumbnail = image;
//                }
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    MyCell *cell = (MyCell *)[weakSelf.collectionView cellForItemAtIndexPath:indexPath];
//                    cell.data = data;
////                    [weakSelf.collectionView reloadItemsAtIndexPaths:@[indexPath]];
//                });
            }
        }];
    }
    return cell;
}

#pragma mark 处理点击事件
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"%@被点击了",indexPath);
    CellData* data = self.cellDataSource[indexPath.row];
    if(data.avAsset) {
        NSLog(@"已经获取到了，不需要重复获取");
        return;
    }
    self.currentIdentifier = data.localIdentifier;
    
    [self beforeDownLoadwith:data];
    [[QHPPhotoKitHelper shareInstance] requestAVAssetForVideoWith:data.asset.localIdentifier];
}

-(void) beforeDownLoadwith:(CellData *) data{
    data.downLoading = YES;
    data.progress = 0.1;
    [self dealWithCellUpdate:data];
}

#pragma mark -- 设置每个item的大小
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(_itemW, 120);
}

#pragma mark - Ges
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    NSLog(@"gestureRecognizer ===>> %@    otherGestureRecognizer =====>> %@", [gestureRecognizer.view class], [otherGestureRecognizer.view class]);
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"MyCell"]) {
        return NO;
    }
    return  YES;
}

#pragma mark ================   根据identifier获取对应的Data和Cell    ================
-(CellData *) getCellDataWith:(NSString *) identifier{
    for(CellData* data in self.cellDataSource){
        if([data.localIdentifier isEqualToString:identifier]){
            return data;
        }
    }
    return nil;
}

-(void) dealWithCellUpdate:(CellData *) data{
    NSInteger index = [self.cellDataSource indexOfObject:data];
    if(index == NSNotFound) {
        return;
    } else {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        MyCell* cell = (MyCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        NSArray* visibleCells = [self.collectionView visibleCells];
        if([visibleCells containsObject:cell]){
            cell.data = data;
        }
    }
}

#pragma mark ================   代理部分处理    ================
#pragma mark  QHPPhotoKitHelperDelegate
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper progressWithIdentifier:(NSString*) indentifier progress:(double) progress info:(NSDictionary *) info{
    NSLog(@"progressWithIndentifier = %@  (progress: %lf) ", indentifier, progress);
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        CellData* data = [self getCellDataWith:indentifier];
        if(data){
            if(progress >= 0.1) {
                data.progress = progress;
                if(data != nil) {
                    [self dealWithCellUpdate:data];
                }
            }
            if([data.localIdentifier isEqualToString:self.currentIdentifier]) {
                [self.IclodeLayer icloudType:IcloudDownLoad progress:progress];
            }
        }
    }];
}

-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper failWithIdentifier:(NSString*) indentifier error:(NSError *) error info:(NSDictionary *) info{
    NSLog(@"failWithIdentifier = %@  (info: %@) ", indentifier, info);
    NSLog(@"progressWithIndentifier = %@  (progress: %lf) ", indentifier, progress);
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        CellData* data = [self getCellDataWith:indentifier];
        if(data){
            data.downLoading = NO;
            if(data != nil) {
                [self dealWithCellUpdate:data];
            }
        }
    }];
}

-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper cancelWithIdentifier:(NSString*) indentifier error:(NSError *) error{
    NSLog(@"cancelWithIdentifier = %@  (error: %@) ", indentifier, error);
    NSLog(@"progressWithIndentifier = %@  (progress: %lf) ", indentifier, progress);
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        CellData* data = [self getCellDataWith:indentifier];
        if(data){
            data.downLoading = NO;
            if(data != nil) {
                [self dealWithCellUpdate:data];
            }
        }
    }];
}

-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper completeWithIdentifier:(NSString*) indentifier aVAsset:(AVAsset *) aVAsset avAudioMix:(AVAudioMix *) audioMix info:(NSDictionary *) info{
    NSLog(@"completeWithIdentifier = %@  (info: %@) ", indentifier, info);
    NSLog(@"progressWithIndentifier = %@  (progress: %lf) ", indentifier, progress);
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        CellData* data = [self getCellDataWith:indentifier];
        if(data){
            data.downLoading = NO;
            data.cellType = PHAssetCellTypeLocal;
            data.avAsset = aVAsset;
            if(data != nil) {
                [self dealWithCellUpdate:data];
            }
        }
    }];
}

#pragma mark - 当视频状态发生改变的采取清空
-(void) dealWithIcloudWith:(NSIndexSet *) changeSet{
    [changeSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        if(idx < self.cellDataSource.count) {
            CellData* data = self.cellDataSource[idx];
            data.cellType = PHAssetCellTypeUnKnown;
        }
    }];
}

-(void) ClearAllIcloudFlag{
    [self.cellDataSource enumerateObjectsUsingBlock:^(CellData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.cellType = PHAssetCellTypeUnKnown;
    }];
}

#pragma mark QHPPhotoKitChangeDelegate
-(void) qhpPhotoKitHelper:(QHPPhotoKitHelper *) helper phChangeDetail:(PHFetchResultChangeDetails *)changes{
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        self.videoFetchResult = helper.videoFetchResult;
        [self setupDataSource];
        if(changes.hasIncrementalChanges) {
            [self.collectionView performBatchUpdates:^{
                NSIndexSet* removed = changes.removedIndexes;
                if(removed.count){
                    NSArray* removedArray = [self indexPathsWithset:removed];
                    [self.collectionView deleteItemsAtIndexPaths:removedArray];
                }
                NSIndexSet* inserted = changes.insertedIndexes;
                if(inserted.count){
                    NSArray* insertedArray = [self indexPathsWithset:inserted];
                    [self.collectionView insertItemsAtIndexPaths:insertedArray];
                }
                NSIndexSet* changed = changes.changedIndexes;
                if(changed.count){
                    NSArray* changeArray = [self indexPathsWithset:changed];
                    [self.collectionView reloadItemsAtIndexPaths:changeArray];
                }
                [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                    NSIndexPath* from = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                    NSIndexPath* to = [NSIndexPath indexPathForItem:toIndex inSection:0];
                    [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
                }];
            } completion:^(BOOL finished) {
                if(finished == NO){
                    [self.collectionView reloadData];
                }
            }];
        } else {
            [self.collectionView reloadData];
        }
    }];
}

-(NSArray<NSIndexPath *> *) indexPathsWithset:(NSIndexSet*) set{
    NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:1];
    [set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
        [tempArray addObject:indexPath];
    }];
    return tempArray;
}

#pragma mark ================   缓存和其他部分    ================
-(void) resetCachedAssets{
    [[QHPPhotoKitHelper shareInstance] stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

// Notice: Only for old.height == new.height
// Others is array no a rect
void differencesBetweenRects(CGRect old, CGRect new, CGRect* addR, CGRect* removeR, int *len){
    if(CGRectIntersectsRect(old, new)) {
        CGRect addRect[2] = {CGRectZero, CGRectZero}, removeRect[2] = {CGRectZero, CGRectZero};
        if(QHPCGRectTool.maxY(new) > QHPCGRectTool.maxY(old)) {
            CGFloat d = QHPCGRectTool.maxY(new) - QHPCGRectTool.maxY(old);
            addRect[0] = CGRectMake(new.origin.x, QHPCGRectTool.maxY(old), new.size.width, d);
        }
        if(QHPCGRectTool.minY(old) > QHPCGRectTool.minY(new)){
            CGFloat d = QHPCGRectTool.minY(new) - QHPCGRectTool.minY(old);
            addRect[1] = CGRectMake(new.origin.x, old.origin.y, new.size.width, d);
        }
        if(QHPCGRectTool.maxY(new) < QHPCGRectTool.maxY(old)) {
            CGFloat d = QHPCGRectTool.maxY(old) - QHPCGRectTool.maxY(new);
            removeRect[0] = CGRectMake(new.origin.x, QHPCGRectTool.maxY(new),new.size.width, d);
        }
        if(QHPCGRectTool.minY(old) < QHPCGRectTool.minY(new)){
            CGFloat d = QHPCGRectTool.minY(new) - QHPCGRectTool.minY(old);
            removeRect[1] = CGRectMake(new.origin.x, QHPCGRectTool.maxY(new),new.size.width, d);
        }
        addR = addRect;
        removeR = removeRect;
        *len = 2;
    } else {
        CGRect addRect[1] = {CGRectZero}, removeRect[1] = {CGRectZero};
        addRect[0] = new;
        removeRect[0] = old;
        addR = addRect;
        removeR = removeRect;
        *len = 1;
    }
}

-(NSArray<NSIndexPath *> *) indexPathsInRect:(CGRect) rect{
    NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:1];
    NSArray<UICollectionViewLayoutAttributes *>* attrArray = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    for(UICollectionViewLayoutAttributes *layoutAttr in attrArray) {
        NSIndexPath* indexPath = layoutAttr.indexPath;
        [tempArray addObject:indexPath];
    }
    return tempArray;
}

-(void) updateCachedAssets{
    if(self.isViewLoaded && self.view.window != nil) {
        
    } else {
        return;
    }
    CGRect visibleRect = {self.collectionView.contentOffset, self.collectionView.bounds.size};
    CGFloat dy = 0.5 * visibleRect.size.height;
    CGRect preheatRect = CGRectMake(visibleRect.origin.x, visibleRect.origin.y - dy , visibleRect.size.width, visibleRect.size.height + 2*dy);
    CGFloat preheatMidY = QHPCGRectTool.midY(preheatRect);
    CGFloat previousMidY = QHPCGRectTool.midY(self.previousPreheatRect);
    CGFloat delta = fabs(preheatMidY - previousMidY);
    if(delta > self.collectionView.bounds.size.height / 3) {
        return;
    }
    
    CGRect* addRect = NULL, * removeRect = NULL;
    int *len = 0;
    differencesBetweenRects(self.previousPreheatRect, preheatRect, addRect, removeRect, len);
    NSMutableArray* addSet = [[NSMutableArray alloc] initWithCapacity:1];
    for(NSInteger i = 0; i < *len; i++){
        CGRect rect = addRect[i];
        NSArray* indexPathList = [self indexPathsInRect:rect];
        for(NSInteger j = 0; j < indexPathList.count; j++) {
            NSIndexPath* indexPath = indexPathList[j];
            CellData* data = self.cellDataSource[indexPath.row];
            [addSet addObject:data.asset];
        }
    }
    
    NSMutableArray* removeSet = [[NSMutableArray alloc] initWithCapacity:1];
    for(NSInteger i = 0; i < *len; i++){
        CGRect rect = removeRect[i];
        NSArray* indexPathList = [self indexPathsInRect:rect];
        for(NSInteger j = 0; j < indexPathList.count; j++) {
            NSIndexPath* indexPath = indexPathList[j];
            CellData* data = self.cellDataSource[indexPath.row];
            [removeSet addObject:data.asset];
        }
    }
    
    [[QHPPhotoKitHelper shareInstance] startCachingImagesForAssets:addSet targetSize:_itemSize];
    [[QHPPhotoKitHelper shareInstance] stopCachingImagesForAssets:removeSet targetSize:_itemSize];
}

#pragma mark - ScrollerDelegate
-(void) scrollViewDidScroll:(UIScrollView *)scrollView{
    [self updateDataSource];
}

// login内容
/*
2018-10-02 16:23:53.271531+0800 iOSPhotoKit[17987:6711568] info === {
    PHImageResultDeliveredImageFormatKey = 5003;
    PHImageResultIsDegradedKey = 0;
    PHImageResultRequestIDKey = 1;
    PHImageResultWantedImageFormatKey = 5003;
}
 
 2018-10-02 16:34:30.029220+0800 iOSPhotoKit[17991:6714537] ============内容在iCloud中===============
 2018-10-02 16:34:30.029282+0800 iOSPhotoKit[17991:6714537] info === {
 PHImageFileOrientationKey = 0;
 PHImageResultDeliveredImageFormatKey = 5003;
 PHImageResultIsDegradedKey = 0;
 PHImageResultIsInCloudKey = 1;
 PHImageResultIsPlaceholderKey = 0;
 PHImageResultRequestIDKey = 16;
 PHImageResultWantedImageFormatKey = 5003;
 }
 
 如果直接设置缓存的时候就下载icloud那么久无法获知谁知icloud的视频
 2018-10-02 16:43:34.004673+0800 iOSPhotoKit[18004:6718733] info === {
 PHImageResultDeliveredImageFormatKey = 5003;
 PHImageResultImageTypeKey = 0;
 PHImageResultIsDegradedKey = 0;
 PHImageResultRequestIDKey = 1;
 }
 
 2018-10-02 17:06:00.205475+0800 iOSPhotoKit[18081:6730183] info ==== {
 PHImageFileSandboxExtensionTokenKey = "28c11ce98c91309aed742d23c7ffa9f50dfb6993;00000000;00000000;000000000000001b;com.apple.avasset.read-only;01;01000003;000000010291ed23;/private/var/mobile/Media/PhotoData/Metadata/DCIM/102APPLE/IMG_2702.medium.MP4";
 PHImageResultDeliveredImageFormatKey = 20002;
 PHImageResultIsInCloudKey = 1;
 PHImageResultWantedImageFormatKey = 20002;
 }

*/


@end
