//
//  WonderMovieDownloadController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 2/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderMovieDownloadController.h"
#import "TVDramaManager.h"
#import "Video.h"
#import "VideoGroup+Additions.h"
#import "UIView+Sizes.h"

@interface WonderMovieDownloadController ()
@end

@implementation WonderMovieDownloadController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithURL:(NSString *)URL
{
    TVDramaManager *tvDramaManager = [[TVDramaManager alloc] init];
    tvDramaManager.webURL = URL;
    return [self initWithTVDramaManager:tvDramaManager];
}

- (id)initWithTVDramaManager:(TVDramaManager *)tvDramaManager
{
    if (self = [super init]) {
        self.tvDramaManager = tvDramaManager;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = @"离线";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(onClickCancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(onClickDownload:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    CGFloat footerHeight = 44;
    WonderMovieDownloadView *downloadView = [[WonderMovieDownloadView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - footerHeight)];
    downloadView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    downloadView.tvDramaManager = self.tvDramaManager;
    downloadView.delegate = self;
    self.downloadView = downloadView;
    [self.view addSubview:downloadView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, downloadView.bottom, self.view.width, footerHeight)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    footerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1]; // FIXME
    footerView.clipsToBounds = YES;
    [self.view addSubview:footerView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, footerView.width - 10, footerView.height)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor grayColor];
    label.textAlignment = UITextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:13];
    label.text = @"可用空间0G";
    self.availableSpaceLabel = label;
    [footerView addSubview:label];
    
    [self.downloadView reloadData];
    [self updateAvailableSpace];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.downloadView.tableView beginUpdates];
    [self.downloadView.tableView reloadRowsAtIndexPaths:self.downloadView.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.downloadView.tableView endUpdates];
}

#pragma mark WonderMovieDownloadViewDelegate
- (void)wonderMovieDownloadViewDidCancel:(WonderMovieDownloadView *)downloadView
{
		
}

- (void)wonderMovieDownloadView:(WonderMovieDownloadView *)downloadView didDownloadVideos:(NSArray *)videos
{
    [self startBatDownload:videos];
}

- (void)wonderMovieDownloadView:(WonderMovieDownloadView *)downloadView didChangeSelectedVideos:(NSArray *)videos
{
    self.navigationItem.rightBarButtonItem.enabled = videos.count > 0;
}

#pragma mark Action
- (IBAction)onClickCancel:(id)sender
{
    [self.downloadView cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClickDownload:(id)sender
{
    [self.downloadView confirm];
    [self dismissViewControllerAnimated:YES completion:nil];    
}

- (void)startBatDownload:(NSArray *)videos
{
    NSMutableArray *downloadURLs = [NSMutableArray array];
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    for (NSNumber *setNum in videos) {
        Video *video = [videoGroup videoAtSetNum:setNum];
        [downloadURLs addObject:video.url];
    }

    [self.batMovieDownloader batchDownloadURLs:downloadURLs];
}

#pragma mark Utils
- (void)updateAvailableSpace
{
    uint64_t space = [self getFreeDiskspace];
    if (space < 1024 * 1024 * 1024) {
        self.availableSpaceLabel.text = [NSString stringWithFormat:@"可用空间%.1fM", space / 1024. / 1024];
    }
    else {
        self.availableSpaceLabel.text = [NSString stringWithFormat:@"可用空间%.1fG", space / 1024. / 1024 / 1024];
    }
}

- (uint64_t)getFreeDiskspace
{
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %d", [error domain], [error code]);
    }
    return totalFreeSpace;
}

@end
