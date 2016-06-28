//
//  LKVideoPlayerDemoViewController.m
//  LKKit
//
//  Created by lingtonke on 16/6/23.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

#import "LKVideoPlayerDemoViewController.h"
#import "LKObjc.h"
#import "LKKit.h"

NSString *url1 = @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4";
NSString *url2 = @"http://v1.mukewang.com/19954d8f-e2c2-4c0a-b8c1-a4c826b5ca8b/L.mp4";

@interface LKVideoPlayerDemoViewController()

@property (nonatomic) LKVideoViewController *videoViewController;
@property (nonatomic) UISlider *slider;
@property (nonatomic) NSMutableDictionary *testDic;

@end

@implementation LKVideoPlayerDemoViewController

-(BOOL)shouldAutorotate
{
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoViewController = [[LKVideoViewController alloc] init];
    self.videoViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width*9/16);
    
    
    [self.view addSubview:self.videoViewController.view];
    self.videoViewController.videoView.mode = LKVideoViewModeSystem;
    
    [LKMMapFileCacheManager shareInstance].rootPath = [NSString stringWithFormat:@"%@/tmp/Video",NSHomeDirectory()];
    
    self.videoViewController.player = [[LKVideoPlayer alloc] init];
    [self.videoViewController.player newPlayTask:[NSURL URLWithString:url1]];
    [self.videoViewController.player play];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 500, 50, 50)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"aa" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonTouch) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width*9/16, self.view.frame.size.width, 20)];
    [self.slider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.slider];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LKOrientationManager.LKOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (UIInterfaceOrientationIsLandscape([LKOrientationManager shareInstance].currentOrientation))
        {
            if (!self.videoViewController.presentingViewController)
            {
                self.videoViewController.landscape = YES;
                [self.videoViewController presentFrom:self animated:YES completion:nil];
            }
            
        }
        else if ([LKOrientationManager shareInstance].currentOrientation == UIInterfaceOrientationPortrait)
        {
            if (self.videoViewController.presentingViewController)
            {
                [self.videoViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }];
    
    
    
    self.testDic = [NSMutableDictionary dictionary];
    
    [LKLayoutManager shareInstance];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"value"])
    {
        
    }
}

- (void)sliderChange:(UISlider*)slider
{
    [self.videoViewController.player seekTo:self.videoViewController.player.duration*self.slider.value complete:nil];
}

-(void)buttonTouch
{
    self.videoViewController.landscape = NO;
    [self.videoViewController presentFrom:self animated:YES completion:nil];
    
}

@end
