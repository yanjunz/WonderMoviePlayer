//
//  ViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "ViewController.h"
#import "WonderMPMovieViewController.h"
#import "TestWebViewController.h"
#import "WonderAVMovieViewController.h"
#import "Test2ViewController.h"
#import "TVDramaManager.h"
#import "FakeTVDramaWebSource.h"
#import "TestTableViewController.h"
#import "FakeMovieDownloader.h"
#import "Reachability.h"
#import "FakeBatMovieDownloader.h"
#import "WonderMovieDownloadController.h"
#import "FakeMovieInfoObtainer.h"

#ifdef MTT_FEATURE_WONDER_MPMOVIE_PLAYER
#define WonderMovieViewController WonderMPMovieViewController
#else
#define WonderMovieViewController WonderAVMovieViewController
#endif

@interface ViewController () {
    NSString *_testString;
    Reachability *_reach;
}
@property (nonatomic, strong) WonderMovieViewController *player;
@property (nonatomic, strong) NSString *testString;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIView *testView;
@property (strong, nonatomic) IBOutlet UIButton *tableButton;

@end

@implementation ViewController
@synthesize testString=_testString;

// for debug
//- (id)retain
//{
//    id r = [super retain];
//    NSLog(@"retain %d", [self retainCount]);
//    return r;
//}
//
//- (oneway void)release
//{
//    NSLog(@"release %d", [self retainCount]);
//    [super release];
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.slider addTarget:self action:@selector(onSliderChanged:) forControlEvents:UIControlEventValueChanged];
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI / 180 * 360);
    rotationAnimation.duration = 1.0f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [self.loadingIndicator.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(volumeChanged:)
//                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
//                                               object:nil];
 
    self.testView.layer.shadowRadius = 4;
    self.testView.layer.shadowOffset = CGSizeMake(-2, 0);
    self.testView.layer.shadowColor = [UIColor blueColor].CGColor;
    self.testView.layer.shadowOpacity = 0.5;
    
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    [reach startNotifier];
    _reach = reach;
}

- (void)testTableButton
{

}

- (void)volumeChanged:(id)n
{
    NSLog(@"volumeChanged %@", n);
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSliderChanged:(UISlider *)sender
{
    NSLog(@"onSliderChanged %f", sender.value);
}
- (IBAction)changeSlider:(id)sender {
    self.slider.value += 0.2;
    self.loadingIndicator.hidden = !self.loadingIndicator.hidden;
}

- (IBAction)onClickPlay:(id)sender {
    @autoreleasepool {
        WonderAVMovieViewController *controller = [[WonderAVMovieViewController alloc] init];
        DefineWeakVarBeforeBlock(controller);
//        self.player = controller;
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        [controller setCrossScreenBlock:^{
            DefineStrongVarInBlock(controller);
            [controller.controlSource setTitle:@"我叫MT" subtitle:@"(来源: 爱奇艺)"];
            if ([controller.controlSource resolutions].count > 0) {
                [controller.controlSource setResolutions:nil];
            }
            else {
                [controller.controlSource setResolutions:@[@"高清", @"流畅", @"标清"]];
            }
        }];
        
        if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
            [self presentViewController:controller animated:YES completion:nil];
        }
        else {
            [self presentModalViewController:controller animated:YES];
        }
        
        TVDramaManager *tvDramaManager = [[TVDramaManager alloc] init];
        tvDramaManager.webURL = @"http://www.iqiyi.com/dongman/20130414/8d6929ed7ac9a7b8.html";
        FakeTVDramaWebSource *fakeDramaWebSource = [[FakeTVDramaWebSource alloc] init];
        tvDramaManager.requestHandler = [ResponsibilityChainTVDramaRequestHandler handlerWithActualHandler:fakeDramaWebSource nextHandler:nil];
        [controller.controlSource setTvDramaManager:tvDramaManager];

        
        [controller setExitBlock:^{
            _testString = @"Hello";
//            self.testString = @"YEs";
//            self.player = nil;
            DefineStrongVarInBlock(controller);
            if ([controller respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
                [controller dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [controller dismissModalViewControllerAnimated:YES];
            }
        }];
        
        NSLog(@"start to play av");
//        [controller playMovieStream:[[NSBundle mainBundle] URLForResource:@"Movie" withExtension:@"m4v"] fromProgress:0];
        [controller playWithMovieObtainer:[[FakeMovieInfoObtainer alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"Movie" withExtension:@"m4v"]]];
    }
}

- (IBAction)onClickPlayRemote:(id)sender {

//    DefineBlockVar(WonderAVMovieViewController *, controller, [[[WonderAVMovieViewController alloc] init] autorelease]);
    WonderAVMovieViewController *controller = [[WonderAVMovieViewController alloc] init];
    DefineWeakVarBeforeBlock(controller);
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    TVDramaManager *tvDramaManager = [[TVDramaManager alloc] init];
    tvDramaManager.webURL = @"http://www.iqiyi.com/dongman/20130414/8d6929ed7ac9a7b8.html"; // the second one
    FakeTVDramaWebSource *fakeDramaWebSource = [[FakeTVDramaWebSource alloc] init];
    tvDramaManager.requestHandler = [ResponsibilityChainTVDramaRequestHandler handlerWithActualHandler:fakeDramaWebSource nextHandler:nil];
    

    
#ifdef MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    controller.batMovieDownloader = [[FakeBatMovieDownloader alloc] init];
#endif // MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    controller.movieDownloader = [[FakeMovieDownloader alloc] init];
#else
    [controller setDownloadBlock:^{
        DefineStrongVarInBlock(controller);
        WonderMovieDownloadController *viewController = [[WonderMovieDownloadController alloc]
                                                         //                                                         initWithURL:@"http://v.qq.com/cover/i/ihubkoevort5cp3.html?vid=g0013vc3y2m"];
                                                         initWithTVDramaManager:tvDramaManager batMovieDownloader:controller.batMovieDownloader];
//        viewController.downloadViewDelegate = controller;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [controller presentViewController:navController animated:YES completion:nil];
        
    }];
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    
    [controller setMyVideoBlock:^{
        DefineStrongVarInBlock(controller);
        ViewController *viewController = [[ViewController alloc] init];
        [controller presentViewController:viewController animated:YES completion:nil];
    }];
    
    [controller setCrossScreenBlock:^{
        NSLog(@"cross screen");
    }];
    
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [self presentViewController:controller animated:YES completion:nil];
    }
    else {
        [self presentModalViewController:controller animated:YES];
    }

    
    [controller.controlSource setTitle:@"我叫MTMTMTMMTMTMTMTMMTMTMTMMTMTMMTMTMMTMMTMTMTMMTTMMTMTMMT" subtitle:@""];
    
    [controller.controlSource setTvDramaManager:tvDramaManager];
    [controller.controlSource setResolutions:@[@"高清", @"流畅", @"标清"]];
    
//    static int alertCount = 0;
//    [controller.controlSource setAlertCopyrightInsteadOfDownload:++alertCount % 2];
    
    [controller setExitBlock:^{
        DefineStrongVarInBlock(controller);
        [UIApplication sharedApplication].statusBarHidden = NO;
        [controller dismissViewControllerAnimated:YES completion:nil];
    }];
    [controller setErrorBlock:^{
        DefineStrongVarInBlock(controller);
        [UIApplication sharedApplication].statusBarHidden = NO;
        [controller dismissViewControllerAnimated:YES completion:nil];
    }];
    
        NSLog(@"start to play av");
        [controller playWithMovieObtainer:[[FakeMovieInfoObtainer alloc] initWithURL:[NSURL URLWithString:
//                                     @"http://hot.vrs.sohu.com/ipad1259067_4587696266952_4460388.m3u8?plat=null"
//                                     @"http://hot.vrs.sohu.com/ipad1319252_4580514014865_4520573.m3u8"
                                     @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"
//                                     @"http://60.217.237.167/39/46/75/letv-uts/6832899-AVC-250149-AAC-31999-2705333-96164792-89fb45dba4f12a8999ddf90b4a8e998c-1378719409675.m3u8?crypt=9aa7f2e94&b=284&nlh=3072&bf=27&gn=750&p2p=1&video_type=mp4&opck=1&check=0&tm=1379221200&key=0f3dc586b05e2b82e5df292c6a3074ee&proxy=1020915110&cips=61.135.172.70&geo=CN-1-9-2&lgn=letv&mmsid=3111163&platid=3&splatid=304&playid=0&tss=ios&retry=1"
//                                     @"http://v.youku.com/player/getM3U8/vid/148104913/type/flv/ts/1376293704/useKeyFrame/0/v.m3u8"
//                                     @"http://v.youku.com/player/getM3U8/vid/148703242/type/flv/ts/1376296533/useKeyFrame/0/v.m3u8"
//                                     @"http://v.youku.com/player/getRealM3U8/vid/XNDUwNjc4MzA4/type/video.m3u8"
//                                     @"http://jq.v.ismartv.tv/cdn/1/81/95e68bbdce46b5b8963b504bf73d1b/normal/slice/index.m3u8"
//                                     @"http://att.livem3u8.na.itv.cn/live/97acb1b2cbed4a4281a68356f8c2bd00.m3u8"
                                                                                      ]]];
    

}

- (IBAction)onClickWebView:(id)sender {
    [self.navigationController pushViewController:[[TestWebViewController alloc] init] animated:YES];
}
- (IBAction)onClickTable:(id)sender {
    [self.navigationController pushViewController:[[TestTableViewController alloc] init] animated:YES];
}
- (IBAction)onClickBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)onClickDownload:(id)sender {
//    WonderMovieDownloadController *controller = [[WonderMovieDownloadController alloc] initWithURL:@"http://v.qq.com/cover/i/ihubkoevort5cp3.html?vid=g0013vc3y2m"];
//    
//    FakeTVDramaWebSource *fakeDramaWebSource = [[FakeTVDramaWebSource alloc] init];
//    controller.tvDramaManager.requestHandler = [ResponsibilityChainTVDramaRequestHandler handlerWithActualHandler:fakeDramaWebSource nextHandler:nil];
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
//    [self presentViewController:navController animated:YES completion:nil];
}

- (void)viewDidUnload {
    [self setSlider:nil];
    [self setProgressView:nil];
    [self setLoadingIndicator:nil];
    [self setTestView:nil];
    [self setTableButton:nil];
    [super viewDidUnload];
}
- (IBAction)onClickTest2:(id)sender {
    Test2ViewController *controller = [[Test2ViewController alloc] init];
    [self presentViewController:controller animated:YES completion:nil];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    /* Return YES for supported orientations. */
    return interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL)shouldAutorotate{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (!UIInterfaceOrientationIsLandscape(orientation)) {
        return orientation;
    }
    else {
        return UIInterfaceOrientationPortrait;
    }
}



@end
