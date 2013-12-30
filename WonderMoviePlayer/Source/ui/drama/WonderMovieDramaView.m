//
//  WonderMovieDramaView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/14/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WonderMovieDramaView.h"
#import "UIView+Sizes.h"
#import "NSObject+Block.h"
#import "Video.h"
#import "VideoGroup+VideoDetailSet.h"
#import "WonderMovieDramaGridCell.h"
#import "WonderMovieDramaListCell.h"
#import "WonderMoviePlayerConstants.h"

#define kDramaHeaderViewHeight      44
#define kMaxVideoCountPerGridCell   9

@interface WonderMovieDramaView () <WonderMovieDramaGridCellDelegate>;
@property (nonatomic, retain) VideoGroup *videoGroup;
@property (nonatomic, retain) NSArray *sortedVideos;
@end

@implementation WonderMovieDramaView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, kDramaHeaderViewHeight)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        headerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1]; // FIXME
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, headerView.width - 20, headerView.height)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13];
        label.text = NSLocalizedString(@"剧集列表", nil);
        [headerView addSubview:label];
        
        UIImageView *separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, label.bottom, headerView.width, 1)];
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        separatorView.image = QQVideoPlayerImage(@"separator_line");
        [headerView addSubview:separatorView];
        [separatorView release];
        
        [self addSubview:headerView];
        [label release];
        [headerView release];
        
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
        [tableView release];
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = self.bounds;
        gradientLayer.colors = @[(id)[[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor, (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor];
        gradientLayer.startPoint = CGPointMake(0.5, 0);
        gradientLayer.endPoint = CGPointMake(0.5, 0.4/3);
        [self.layer insertSublayer:gradientLayer atIndex:0];
        
//        UIImageView *leftShadow = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"drama_left_shadow")];
//        leftShadow.frame = CGRectMake(-leftShadow.size.width, 0, leftShadow.size.width, self.width);
//        leftShadow.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
//        [self addSubview:leftShadow];
//        [leftShadow release];
    }
    return self;
}

- (void)dealloc
{
    self.tvDramaManager = nil;
    self.tableView = nil;
    self.errorView = nil;
    self.loadingView = nil;
    self.videoGroup = nil;
    self.sortedVideos = nil;
    [super dealloc];
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

- (void)scrollToThePlayingOne
{
    if (self.sortedVideos.count == 0) {
        return;
    }
    
    int showType = self.videoGroup.showType.intValue;
    int index = 0;
    
    if (showType == VideoGroupShowTypeGrid) {
        Video *minVideo = self.sortedVideos[0];
        index = (self.playingSetNum - minVideo.setNum.intValue) / kMaxVideoCountPerGridCell;
    }
    else if (showType == VideoGroupShowTypeList) {
        Video *maxVideo = self.sortedVideos[0];
        index = maxVideo.setNum.intValue - self.playingSetNum;
    }
    index = MAX(0, MIN(index, ([self tableView:self.tableView numberOfRowsInSection:0] - 1)));
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
        [loadingIndicator release];
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
    static NSString *kGridCellID = @"WonderMovieDramaGridCell";
    static NSString *kListCellID = @"WonderMovieDramaListCell";
    
    if (showType == VideoGroupShowTypeGrid) {
        WonderMovieDramaGridCell *cell = [tableView dequeueReusableCellWithIdentifier:kGridCellID];
        if (cell == nil) {
            cell = [[[WonderMovieDramaGridCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGridCellID] autorelease];
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
        [cell playWithSetNum:self.playingSetNum];
        
        return cell;
    }
    else {
        WonderMovieDramaListCell *cell = [tableView dequeueReusableCellWithIdentifier:kListCellID];
        if (cell == nil) {
            cell = [[[WonderMovieDramaListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kListCellID] autorelease];
            cell.imageView.image = QQVideoPlayerImage(@"list_play");
            cell.textLabel.font = [UIFont systemFontOfSize:13];

            UIImageView *separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, cell.bottom - 1, cell.width, 1)];
            separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            separatorView.image = QQVideoPlayerImage(@"separator_line");
            [cell addSubview:separatorView];
            [separatorView release];
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
        [self playWithSetNum:video.setNum.intValue];
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

#pragma mark WonderMovieDramaGridCellDelegate
- (void)wonderMovieDramaGridCell:(WonderMovieDramaGridCell *)cell didClickAtSetNum:(int)setNum
{
    [self playWithSetNum:setNum];
    [self.tableView reloadData];
}

#pragma mark Priavte
- (void)playWithSetNum:(int)setNum
{
    _playingSetNum = setNum;
    if ([self.delegate respondsToSelector:@selector(wonderMovieDramaView:didSelectSetNum:)]) {
        [self.delegate wonderMovieDramaView:self didSelectSetNum:setNum];
    }
}

- (CGFloat)offsetOfCellAtSetNum:(int)setNum
{
    if (self.sortedVideos.count == 0) {
        return 0;
    }
    
    int showType = self.videoGroup.showType.intValue;
    int videoCountPerCell = showType == VideoGroupShowTypeGrid ? kMaxVideoCountPerGridCell : 1;
    

    Video *minVideo = self.sortedVideos[0];
    int minVideoSetNum = minVideo.setNum.intValue;
    int order = setNum - minVideoSetNum;
    int row = order / videoCountPerCell;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    return cell.top;
}

- (NSIndexPath *)indexPathAtSetNum:(int)setNum
{
    if (self.sortedVideos.count == 0) {
        return nil;
    }
    
    int showType = self.videoGroup.showType.intValue;
    int videoCountPerCell = showType == VideoGroupShowTypeGrid ? kMaxVideoCountPerGridCell : 1;
    
    
    Video *minVideo = self.sortedVideos[0];
    int minVideoSetNum = minVideo.setNum.intValue;
    int order = setNum - minVideoSetNum;
    int row = order / videoCountPerCell;
    
    return [NSIndexPath indexPathForItem:row inSection:0];
}

@end
