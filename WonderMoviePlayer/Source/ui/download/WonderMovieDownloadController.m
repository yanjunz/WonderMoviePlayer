//
//  WonderMovieDownloadController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 2/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderMovieDownloadController.h"
#import "TVDramaManager.h"

@interface WonderMovieDownloadController ()
@property (nonatomic, strong) TVDramaManager *tvDramaManager;

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
    WonderMovieDownloadView *downloadView = [[WonderMovieDownloadView alloc] initWithFrame:self.view.bounds];
    downloadView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    downloadView.tvDramaManager = self.tvDramaManager;
    downloadView.delegate = self;
    self.downloadView = downloadView;
    [self.view addSubview:downloadView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(onClickCancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(onClickDownload:)];
    
    [self.downloadView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark WonderMovieDownloadViewDelegate
- (void)wonderMovieDownloadViewDidCancel:(WonderMovieDownloadView *)downloadView
{
    if ([self.downloadViewDelegate respondsToSelector:@selector(wonderMovieDownloadViewDidCancel:)]) {
        [self.downloadViewDelegate wonderMovieDownloadViewDidCancel:downloadView];
    }
}

- (void)wonderMovieDownloadView:(WonderMovieDownloadView *)downloadView didDownloadVideos:(NSArray *)videos
{
    if ([self.downloadViewDelegate respondsToSelector:@selector(wonderMovieDownloadView:didDownloadVideos:)]) {
        [self.downloadViewDelegate wonderMovieDownloadView:downloadView didDownloadVideos:videos];
    }
}

#pragma mark Action
- (IBAction)onClickCancel:(id)sender
{
    [self.downloadView onClickCancel:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClickDownload:(id)sender
{
    [self.downloadView onClickDownload:nil];
    [self dismissViewControllerAnimated:YES completion:nil];    
}

@end
