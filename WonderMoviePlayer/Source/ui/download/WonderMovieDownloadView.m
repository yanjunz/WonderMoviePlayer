//
//  WonderMovieDownloadView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderMovieDownloadView.h"
#import "WonderMoviePlayerConstants.h"
#import "UIView+Sizes.h"
#import "NSObject+Block.h"
#import "Video.h"
#import "VideoGroup+Additions.h"
#import "WonderMovieDownloadGridCell.h"
#import "WonderMovieDownloadListCell.h"

#define kDramaHeaderViewHeight      0
#define kDramaFooterViewHeight      0
#define kNavButtonWidth             60
#define kDownloadViewGridMaxRow     3

@interface WonderMovieDownloadView () <WonderMovieDownloadGridCellDelegate>
@property (nonatomic, strong) VideoGroup *videoGroup;
@property (nonatomic, strong) NSArray *sortedVideos;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) NSMutableArray *selectedSetNums;
@property (nonatomic, strong) NSMutableArray *downloadedSetNums; // include downloading & downloaded

@end

@implementation WonderMovieDownloadView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor grayColor];
        self.selectedSetNums = [NSMutableArray array];
        self.downloadedSetNums = [NSMutableArray array];
        
        DramaTableView *tableView = [[DramaTableView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight - kDramaFooterViewHeight) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = QQColor(videoplayer_download_tableview_bg_color);
        tableView.separatorColor = [UIColor clearColor];
        [self addSubview:tableView];
        self.tableView = tableView;
        if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        
        self.supportBatchDownload = YES;
    }
    return self;
}

- (void)reloadData
{
    if (self.videoGroup == nil) {
        self.loadingView.frame = CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight);
        [self addSubview:self.loadingView];
        [self bringSubviewToFront:self.loadingView];
        [self loadCurrentSection];
    }
    else {
        if (self.videoGroup.showType.intValue != VideoGroupShowTypeGrid) {
            if (self.tableView.tableHeaderView == nil) {
                self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 12)];
            }
        }
        
        [self.videoGroup checkDownloadedVideosExist];
        NSArray *downloadedVideos = [self.videoGroup downloadedVideos];
        [downloadedVideos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Video *video = obj;
            if (![self.downloadedSetNums containsObject:video.setNum]) {
                [self.downloadedSetNums addObject:video.setNum];
            }
        }];
        [self.tableView reloadData];
    }
}


- (UIView *)loadingView
{
    if (_loadingView == nil) {
        UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight)];
        loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        loadingView.backgroundColor = [UIColor clearColor];
        UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        loadingIndicator.hidesWhenStopped = YES;
        loadingIndicator.center = CGPointMake(CGRectGetMidX(loadingView.bounds), CGRectGetMidY(loadingView.bounds));
        loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [loadingView addSubview:loadingIndicator];
        [loadingIndicator startAnimating];
        _loadingView = loadingView;
    }
    return _loadingView;
}

- (UIView *)errorView
{
    if (_errorView == nil) {
        UIView *errorView = [[UIView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight)];
        errorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        errorView.backgroundColor = [UIColor clearColor];
        UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        retryButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [retryButton setTitle:NSLocalizedString(@"无法获取，请重试", nil) forState:UIControlStateNormal];
        [retryButton addTarget:self action:@selector(onClickRetry:) forControlEvents:UIControlEventTouchUpInside];
        retryButton.frame = errorView.bounds;
        [errorView addSubview:retryButton];
        _errorView = errorView;
    }
    return _errorView;
}

- (void)loadCurrentSection
{
    if (self.tvDramaManager.videoGroup != nil) {
        [self updateVideoGroupData];
        [self finishCurrentSectionLoad];
    }
    else {
        [self.tvDramaManager getDramaInfo:TVDramaRequestTypeCurrent completionBlock:^(BOOL success) {
            // make sure to invoke UI related code in main thread
            [self performBlockInMainThread:^{
                [self updateVideoGroupData];
                if (success) {
                    [self finishCurrentSectionLoad];
                }
                else {
                    [self showErrorView];
                }
            } afterDelay:0];
        }];
    }
}

- (void)loadPreviousSection
{
    TVDramaRequestType requestType = self.videoGroup.showType.intValue == VideoGroupShowTypeList ? TVDramaRequestTypeNext : TVDramaRequestTypePrevious;
    [self.tvDramaManager getDramaInfo:requestType completionBlock:^(BOOL success) {
        [self performBlockInMainThread:^{
            if (success) {
                [self updateVideoGroupData];
                [self finishPreviousSectionLoad];
            }
            else {
                [self.tableView failLoadMoreHeader];
            }
        } afterDelay:0];
    }];
}

- (void)loadNextSection
{
    TVDramaRequestType requestType = self.videoGroup.showType.intValue == VideoGroupShowTypeList ? TVDramaRequestTypeNext : TVDramaRequestTypePrevious;
    [self.tvDramaManager getDramaInfo:requestType completionBlock:^(BOOL success) {
        [self performBlockInMainThread:^{
            if (success) {
                [self updateVideoGroupData];
                [self finishNextSectionLoad];
            }
            else {
                [self.tableView failLoadMoreFooter];
            }
        } afterDelay:0];
    }];
}

- (void)updateVideoGroupData
{
    self.videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    self.sortedVideos = [self.videoGroup sortedVideos:self.videoGroup.showType.intValue != VideoGroupShowTypeList];
}

- (void)finishCurrentSectionLoad
{
    _playingSetNum = self.tvDramaManager.curSetNum;
    
    _loadingView.frame = CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight);
    [_loadingView removeFromSuperview];
    [self bringSubviewToFront:self.tableView];
    
    [self reloadData];
    [self updateTableState];
}

- (void)finishPreviousSectionLoad
{
    _playingSetNum = self.tvDramaManager.curSetNum;
    
    [self.tableView finishLoadMoreHeader];
    [self reloadData];
    [self updateTableState];
}

- (void)finishNextSectionLoad
{
    _playingSetNum = self.tvDramaManager.curSetNum;
    
    [self.tableView finishLoadMoreFooter];
    [self reloadData];
    [self updateTableState];
}

- (void)updateTableState
{
    if (self.sortedVideos.count == 0) {
        self.tableView.headerLoadingEnabled = NO;
        self.tableView.footerLoadingEnabled = NO;
    }
    else {
        if (self.videoGroup.showType.intValue != VideoGroupShowTypeList) {
            // ascend
            Video *minVideo = self.sortedVideos[0];
            if (minVideo.setNum.intValue > 1) {
                self.tableView.headerLoadingEnabled = YES;
            }
            else {
                self.tableView.headerLoadingEnabled = NO;
            }
            
            Video *maxVideo = [self.sortedVideos lastObject];
            if (self.videoGroup.maxId.intValue > 0 &&
                maxVideo.setNum.intValue < self.videoGroup.maxId.intValue) {
                self.tableView.footerLoadingEnabled = YES;
            }
            else {
                self.tableView.footerLoadingEnabled = NO;
            }
        }
        else {
            // descend
            Video *minVideo = [self.sortedVideos lastObject];
            if (minVideo.setNum.intValue > 1) {
                self.tableView.footerLoadingEnabled = YES;
            }
            else {
                self.tableView.footerLoadingEnabled = NO;
            }
            
            Video *maxVideo = self.sortedVideos[0];
            if (self.videoGroup.maxId.intValue > 0 &&
                maxVideo.setNum.intValue < self.videoGroup.maxId.intValue) {
                self.tableView.headerLoadingEnabled = YES;
            }
            else {
                self.tableView.headerLoadingEnabled = NO;
            }
        }
    }
}

- (void)showErrorView
{
    [_loadingView removeFromSuperview];
    self.errorView.frame = CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight);
    [self addSubview:self.errorView];
    [self bringSubviewToFront:self.errorView];
}

#pragma mark - UIAction
- (IBAction)onClickRetry:(id)sender
{
    [_errorView removeFromSuperview];
    self.loadingView.frame = CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight);
    [self addSubview:self.loadingView];
    [self bringSubviewToFront:self.loadingView];
    [self loadCurrentSection];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int showType = self.videoGroup.showType.intValue;
    int videoCount = self.sortedVideos.count;
    if (showType == VideoGroupShowTypeGrid) {
        int countPerRow = 0;
        [WonderMovieDownloadGridCell getPreferredCountPerRow:&countPerRow buttonWidth:NULL forMaxWidth:tableView.width];
        int maxVideoCountPerCell = countPerRow * kDownloadViewGridMaxRow;
        return (videoCount + maxVideoCountPerCell - 1) / maxVideoCountPerCell;
    }
    else {
        return videoCount;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int showType = self.videoGroup.showType.intValue;
    int videoCount = self.sortedVideos.count;
    static NSString *kGridCellID = @"WonderMovieDownloadGridCell";
    static NSString *kListCellID = @"WonderMovieDownloadListCell";
    
    if (showType == VideoGroupShowTypeGrid) {
        WonderMovieDownloadGridCell *cell = [tableView dequeueReusableCellWithIdentifier:kGridCellID];
        if (cell == nil) {
            cell = [[WonderMovieDownloadGridCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGridCellID];
            cell.delegate = self;
        }
        
        int countPerRow = 0;
        [WonderMovieDownloadGridCell getPreferredCountPerRow:&countPerRow buttonWidth:NULL forMaxWidth:tableView.width];
        int maxVideoCountPerCell = countPerRow * kDownloadViewGridMaxRow;
        
        Video *minVideo = self.sortedVideos[indexPath.row * maxVideoCountPerCell];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * maxVideoCountPerCell >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * maxVideoCountPerCell - 1) :
        (minVideoSetNum + maxVideoCountPerCell - 1);
        
        if (maxVideoSetNum == self.videoGroup.maxId.intValue) {
            cell.cellType = self.videoGroup.totalCount.intValue == 0 ? WonderMovieDramaGridCellTypeNewest : WonderMovieDramaGridCellTypeEnded;
        }
        else {
            cell.cellType = WonderMovieDramaGridCellTypeDefault;
        }
        
        [cell configureCellWithMinVideoSetNum:minVideoSetNum maxVideoSetNum:maxVideoSetNum forWidth:tableView.width];
        
        [cell selectSetNums:self.selectedSetNums];
        if (self.supportBatchDownload) {
            // If support batch download, only disable the downloaded video
            [cell disbaleSetNums:self.downloadedSetNums];
        }
        else {
            // Otherwise only enable the current playing one
            [cell enableSetNums:@[@(self.playingSetNum)]];
        }
        return cell;
    }
    else {
        WonderMovieDownloadListCell *cell = [tableView dequeueReusableCellWithIdentifier:kListCellID];
        if (cell == nil) {
            cell = [[WonderMovieDownloadListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kListCellID];
        }
        int index = indexPath.row;
        Video *video = self.sortedVideos[index];
        
        if (self.supportBatchDownload) {
            cell.disableForDownload = [self.downloadedSetNums containsObject:video.setNum];
        }
        else {
            cell.disableForDownload = video.setNum.intValue != self.playingSetNum;
        }
        
        cell.selectedForDownload = [self.selectedSetNums containsObject:video.setNum];
        cell.textLabel.text = video.brief;
        
        if (video.setNum.intValue == self.videoGroup.maxId.intValue) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)", video.brief,
                                   self.videoGroup.totalCount.intValue == 0 ? @"新" : @"终"];
        }
        else {
            cell.textLabel.text = video.brief;
        }
        
        return cell;
    }
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int showType = self.videoGroup.showType.intValue;
    int videoCount = self.sortedVideos.count;
    
    if (showType == VideoGroupShowTypeGrid) {
        int countPerRow = 0;
        [WonderMovieDownloadGridCell getPreferredCountPerRow:&countPerRow buttonWidth:NULL forMaxWidth:tableView.width];
        int maxVideoCountPerCell = countPerRow * kDownloadViewGridMaxRow;
        
        Video *minVideo = self.sortedVideos[indexPath.row * maxVideoCountPerCell];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * maxVideoCountPerCell >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * maxVideoCountPerCell - 1) :
        (minVideoSetNum + maxVideoCountPerCell - 1);
        
        return [WonderMovieDownloadGridCell cellHeightWithMinVideoSetNum:minVideoSetNum maxVideoSetNum:maxVideoSetNum countPerRow:countPerRow];
    }
    else {
        return 44 + 10;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int showType = self.videoGroup.showType.intValue;
    if (showType != VideoGroupShowTypeGrid) {
        Video *video = self.sortedVideos[indexPath.row];
        
        if ([self.downloadedSetNums containsObject:video.setNum]) {
            return;
        }
        
        if ([self.selectedSetNums containsObject:video.setNum]) {
            [self.selectedSetNums removeObject:video.setNum];
        }
        else {
            [self.selectedSetNums addObject:video.setNum];
        }
        
        [self notifySelectSetNumsChanged];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark UISrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.tableView scrollViewDidScroll:scrollView];
}

#pragma mark DramaTableViewDelegate
- (void)dramaTableViewDidTriggerLoadMoreHeader:(DramaTableView *)tableView
{
    [self loadPreviousSection];
}

- (void)dramaTableViewDidTriggerLoadMoreFooter:(DramaTableView *)tableView
{
    [self loadNextSection];
}

#pragma mark WonderMovieDownloadGridCellDelegate
- (void)wonderMovieDownloadGridCell:(WonderMovieDownloadGridCell *)cell didSelect:(BOOL)select withSetNum:(int)setNum
{
    if (!select) {
        [self.selectedSetNums removeObject:@(setNum)];
    }
    else {
        if (![self.selectedSetNums containsObject:@(setNum)]) {
            [self.selectedSetNums addObject:@(setNum)];
        }
    }
    
    [self notifySelectSetNumsChanged];
}

- (void)notifySelectSetNumsChanged
{
    self.downloadButton.enabled = self.selectedSetNums.count > 0;
    
    if ([self.delegate respondsToSelector:@selector(wonderMovieDownloadView:didChangeSelectedVideos:)]) {
        [self.delegate wonderMovieDownloadView:self didChangeSelectedVideos:self.selectedSetNums];
    }
}

#pragma mark Action
- (void)cancel
{
    if ([self.delegate respondsToSelector:@selector(wonderMovieDownloadViewDidCancel:)]) {
        [self.delegate wonderMovieDownloadViewDidCancel:self];
    }
}

- (void)confirm
{
    if ([self.delegate respondsToSelector:@selector(wonderMovieDownloadView:didDownloadVideos:)]) {
        [self.delegate wonderMovieDownloadView:self didDownloadVideos:self.selectedSetNums];
    }
}

@end
