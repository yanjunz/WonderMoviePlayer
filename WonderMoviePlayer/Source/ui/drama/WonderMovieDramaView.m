//
//  WonderMovieDramaView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/14/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "WonderMovieDramaView.h"
#import "UIView+Sizes.h"
#import "NSObject+Block.h"
#import "Video.h"
#import "VideoGroup+VideoDetailSet.h"
#import "WonderMovieDramaGridCell.h"

#define kDramaHeaderViewHeight  44
#define kVideoCountPerSection   9

@interface WonderMovieDramaView () <WonderMovieDramaGridCellDelegate>
@property (nonatomic, copy) NSArray *videos;
@end

@implementation WonderMovieDramaView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
        
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, label.bottom, headerView.width, 1)];
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        separatorView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        [headerView addSubview:separatorView];
        [separatorView release];
        
        [self addSubview:headerView];
        [label release];
        [headerView release];
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorStyle = UITableViewCellSelectionStyleNone;
        [self addSubview:self.tableView];
        self.tableView = tableView;
        [tableView release];
    }
    return self;
}

- (void)dealloc
{
    self.tvDramaManager = nil;
    self.tableView = nil;
    self.errorView = nil;
    self.loadingView = nil;
    self.videos = nil;
    [super dealloc];
}

- (void)reloadData
{
    if (self.tvDramaManager.videoGroup == nil) {
        [self.tableView removeFromSuperview];
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
    [self performBlockInBackground:^{
        BOOL ret = [self.tvDramaManager getDramaInfo:TVDramaRequestTypeCurrent];
        NSLog(@"loaded %@", self.tvDramaManager.videoGroup.videos);
        [self performBlock:^{
            self.videos = [self.tvDramaManager.videoGroup.videos array];
            if (ret) {
                [self finishCurrentSectionLoad];
            }
            else {
                [self showErrorView];
            }
        } afterDelay:0];
    }];
}

- (void)finishCurrentSectionLoad
{
    [self.loadingView removeFromSuperview];
    [self addSubview:self.tableView];
//    self.tableView.frame = CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight);
    [self.tableView reloadData];
}

- (void)showErrorView
{
    [self.loadingView removeFromSuperview];
    [self addSubview:self.errorView];
    [self bringSubviewToFront:self.errorView];
}


#pragma mark - UIAction
- (IBAction)onClickRetry:(id)sender
{
    [self.errorView removeFromSuperview];
    [self addSubview:self.loadingView];
    [self bringSubviewToFront:self.loadingView];
    [self loadCurrentSection];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int showType = self.tvDramaManager.videoGroup.showType.intValue;
    int videoCount = self.videos.count;
    if (showType == VideoGroupShowTypeGrid) {
        return (videoCount + kVideoCountPerSection - 1) / kVideoCountPerSection;
    }
    else {
        return videoCount;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int showType = self.tvDramaManager.videoGroup.showType.intValue;
    int videoCount = self.videos.count;
    static NSString *kGridCellID = @"WonderMovieDramaGridCell";
    
    if (showType == VideoGroupShowTypeGrid) {
        WonderMovieDramaGridCell *cell = [tableView dequeueReusableCellWithIdentifier:kGridCellID];
        if (cell == nil) {
            cell = [[[WonderMovieDramaGridCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGridCellID] autorelease];
            cell.delegate = self;
        }
        Video *minVideo = self.videos[indexPath.row * kVideoCountPerSection];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * kVideoCountPerSection >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * kVideoCountPerSection - 1) :
        (minVideoSetNum + kVideoCountPerSection - 1);
        
        [cell playWithSetNum:self.playingSetNum];
        [cell configureCellWithMinVideoSetNum:minVideoSetNum maxVideoSetNum:maxVideoSetNum];
        
        return cell;
    }
    else {
         return nil;
    }
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int showType = self.tvDramaManager.videoGroup.showType.intValue;
    int videoCount = self.videos.count;
    
    if (showType == VideoGroupShowTypeGrid) {
        Video *minVideo = self.videos[indexPath.row * kVideoCountPerSection];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * kVideoCountPerSection >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * kVideoCountPerSection - 1) :
        (minVideoSetNum + kVideoCountPerSection - 1);
        
        return [WonderMovieDramaGridCell cellHeightWithMinVideoSetNum:minVideoSetNum maxVideoSetNum:maxVideoSetNum];
    }
    else {
        return 0;
    }
}

#pragma mark WonderMovieDramaGridCellDelegate
- (void)wonderMovieDramaGridCell:(WonderMovieDramaGridCell *)cell didClickAtSetNum:(int)setNum
{
    NSLog(@"click At setNum %d", setNum);
    _playingSetNum = setNum;
    [self.tableView reloadData];
}

@end
