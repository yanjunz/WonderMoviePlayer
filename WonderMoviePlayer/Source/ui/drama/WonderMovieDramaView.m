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

#define kDramaHeaderViewHeight  44
#define kVideoCountPerSection   9

@interface WonderMovieDramaView () <WonderMovieDramaGridCellDelegate>
@property (nonatomic, retain) VideoGroup *videoGroup;
@property (nonatomic, retain) NSArray *sortedVideos;
@end

@implementation WonderMovieDramaView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
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
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight) style:UITableViewStylePlain];
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
        
        UIImageView *leftShadow = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"drama_left_shadow")];
        leftShadow.frame = CGRectMake(-leftShadow.size.width, 0, leftShadow.size.width, self.width);
        leftShadow.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:leftShadow];
        [leftShadow release];
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

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(context, CGSizeMake(-20, 0), 5, [UIColor blueColor].CGColor);
    
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
//    [self performBlockInBackground:^{
//        BOOL ret = [self.tvDramaManager getDramaInfo:TVDramaRequestTypeCurrent];
//        [self performBlock:^{
//            self.videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
//            self.sortedVideos = [self.videoGroup sortedVideos];
//            NSLog(@"videos : %@", self.sortedVideos);
//            if (ret) {
//                [self finishCurrentSectionLoad];
//            }
//            else {
//                [self showErrorView];
//            }
//        } afterDelay:0];
//    }];
    
    [self.tvDramaManager getDramaInfo:TVDramaRequestTypeCurrent completionBlock:^(BOOL success) {
        // make sure to invoke UI related code in main thread
        [self performBlock:^{
            self.videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
            self.sortedVideos = [self.videoGroup sortedVideos];
            if (success) {
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
    Video *video = [self.videoGroup videoAtURL:self.tvDramaManager.webURL];
    if (video) {
        _playingSetNum = video.setNum.intValue;
    }
    
    [_loadingView removeFromSuperview];
    [self bringSubviewToFront:self.tableView];
    [self.tableView reloadData];
    
//    int showType = self.videoGroup.showType.intValue;
//    if (showType == VideoGroupShowTypeList) {
//        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//        self.tableView.separatorColor = [UIColor colorWithPatternImage:QQVideoPlayerImage(@"separator_line")];
//    }
//    else {
//        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//        self.tableView.separatorColor = [UIColor clearColor];
//    }
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
        return (videoCount + kVideoCountPerSection - 1) / kVideoCountPerSection;
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
        Video *minVideo = self.sortedVideos[indexPath.row * kVideoCountPerSection];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * kVideoCountPerSection >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * kVideoCountPerSection - 1) :
        (minVideoSetNum + kVideoCountPerSection - 1);
        
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
        
        return cell;
    }
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int showType = self.videoGroup.showType.intValue;
    int videoCount = self.sortedVideos.count;
    
    if (showType == VideoGroupShowTypeGrid) {
        Video *minVideo = self.sortedVideos[indexPath.row * kVideoCountPerSection];
        int minVideoSetNum = minVideo.setNum.intValue;
        int maxVideoSetNum = (indexPath.row + 1) * kVideoCountPerSection >= videoCount ?
        (minVideoSetNum + videoCount - indexPath.row * kVideoCountPerSection - 1) :
        (minVideoSetNum + kVideoCountPerSection - 1);
        
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


@end
