//
//  WonderMovieDownloadView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderMovieDownloadView.h"
#import "UIView+Sizes.h"
#import "NSObject+Block.h"
#import "Video.h"
#import "VideoGroup+Additions.h"
#import "WonderMovieDownloadGridCell.h"
#import "WonderMovieDownloadListCell.h"

#define kDramaHeaderViewHeight      44
#define kMaxVideoCountPerGridCell   9
#define kNavButtonWidth             60

@interface WonderMovieDownloadView () <WonderMovieDownloadGridCellDelegate>
@property (nonatomic, strong) VideoGroup *videoGroup;
@property (nonatomic, strong) NSArray *sortedVideos;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) NSMutableArray *selectedSetNums;

@end

@implementation WonderMovieDownloadView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor grayColor];
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, kDramaHeaderViewHeight)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        headerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1]; // FIXME
        headerView.clipsToBounds = YES;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, headerView.width, headerView.height)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:13];
        label.text = NSLocalizedString(@"选择视频", nil);
        [headerView addSubview:label];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        cancelButton.frame = CGRectMake(0, 0, kNavButtonWidth, headerView.height);
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [cancelButton addTarget:self action:@selector(onClickCancel:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:cancelButton];
        
        UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [downloadButton setTitle:@"离线" forState:UIControlStateNormal];
        downloadButton.frame = CGRectMake(headerView.width - kNavButtonWidth, 0, kNavButtonWidth, headerView.height);
        downloadButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [downloadButton addTarget:self action:@selector(onClickDownload:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:downloadButton];
        self.downloadButton = downloadButton;
        self.downloadButton.enabled = NO;
        
        UIImageView *separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, label.bottom, headerView.width, 1)];
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        separatorView.image = QQVideoPlayerImage(@"separator_line");
        [headerView addSubview:separatorView];
        
        [self addSubview:headerView];
        
        DramaTableView *tableView = [[DramaTableView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorColor = [UIColor clearColor];
        [self addSubview:tableView];
        self.tableView = tableView;
        if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [tableView setSeparatorInset:UIEdgeInsetsZero];
        }

        self.selectedSetNums = [NSMutableArray array];
    }
    return self;
}

- (void)reloadData
{
    if (self.videoGroup == nil) {
        [self addSubview:self.loadingView];
        [self bringSubviewToFront:self.loadingView];
        [self loadCurrentSection];
    }
    else {
        [self.tableView reloadData];
    }
}


- (UIView *)loadingView
{
    if (_loadingView == nil) {
        UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight)];
        loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        loadingView.backgroundColor = [UIColor clearColor];
        UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        loadingIndicator.hidesWhenStopped = YES;
        loadingIndicator.center = CGPointMake(CGRectGetMidX(loadingView.bounds), CGRectGetMidY(loadingView.bounds));
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
            [self updateVideoGroupData];
            if (success) {
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
            [self updateVideoGroupData];
            if (success) {
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
    
    [_loadingView removeFromSuperview];
    [self bringSubviewToFront:self.tableView];
    
    [self.tableView reloadData];
    [self updateTableState];
}

- (void)finishPreviousSectionLoad
{
    _playingSetNum = self.tvDramaManager.curSetNum;
    
    [self.tableView finishLoadMoreHeader];
    [self.tableView reloadData];
    [self updateTableState];
}

- (void)finishNextSectionLoad
{
    _playingSetNum = self.tvDramaManager.curSetNum;
    
    [self.tableView finishLoadMoreFooter];
    [self.tableView reloadData];
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
    [self addSubview:self.errorView];
    [self bringSubviewToFront:self.errorView];
}

#pragma mark - UIAction
- (IBAction)onClickRetry:(id)sender
{
    [_errorView removeFromSuperview];
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
        return (videoCount + kMaxVideoCountPerGridCell - 1) / kMaxVideoCountPerGridCell;
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
        Video *minVideo = self.sortedVideos[indexPath.row * kMaxVideoCountPerGridCell];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * kMaxVideoCountPerGridCell >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * kMaxVideoCountPerGridCell - 1) :
        (minVideoSetNum + kMaxVideoCountPerGridCell - 1);
        
        if (maxVideoSetNum == self.videoGroup.maxId.intValue) {
            cell.cellType = self.videoGroup.totalCount.intValue == 0 ? WonderMovieDramaGridCellTypeNewest : WonderMovieDramaGridCellTypeEnded;
        }
        else {
            cell.cellType = WonderMovieDramaGridCellTypeDefault;
        }
        [cell configureCellWithMinVideoSetNum:minVideoSetNum maxVideoSetNum:maxVideoSetNum];
//        [cell playWithSetNum:self.playingSetNum];
        
        return cell;
    }
    else {
        WonderMovieDownloadListCell *cell = [tableView dequeueReusableCellWithIdentifier:kListCellID];
        if (cell == nil) {
            cell = [[WonderMovieDownloadListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kListCellID];
            cell.imageView.image = QQVideoPlayerImage(@"list_play");
            cell.textLabel.font = [UIFont systemFontOfSize:13];
            
            UIImageView *separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, cell.bottom - 1, cell.width, 1)];
            separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            separatorView.image = QQVideoPlayerImage(@"separator_line");
            [cell addSubview:separatorView];
        }
        Video *video = self.sortedVideos[indexPath.row];
        cell.isPlaying = video.setNum.intValue == self.playingSetNum;
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
        Video *minVideo = self.sortedVideos[indexPath.row * kMaxVideoCountPerGridCell];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * kMaxVideoCountPerGridCell >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * kMaxVideoCountPerGridCell - 1) :
        (minVideoSetNum + kMaxVideoCountPerGridCell - 1);
        
        return [WonderMovieDramaGridCell cellHeightWithMinVideoSetNum:minVideoSetNum maxVideoSetNum:maxVideoSetNum];
    }
    else {
        return 42;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int showType = self.videoGroup.showType.intValue;
    if (showType != VideoGroupShowTypeGrid) {
        Video *video = self.sortedVideos[indexPath.row];
//        [self playWithSetNum:video.setNum.intValue];
        [self.tableView reloadData];
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
    
    if (self.selectedSetNums.count > 0) {
        self.downloadButton.enabled = YES;
    }
}

#pragma mark Action
- (IBAction)onClickCancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(wonderMovieDownloadViewDidCancel:)]) {
        [self.delegate wonderMovieDownloadViewDidCancel:self];
    }
}

- (IBAction)onClickDownload:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(wonderMovieDownloadView:didDownloadVideos:)]) {
        [self.delegate wonderMovieDownloadView:self didDownloadVideos:self.selectedSetNums];
    }
}

@end
