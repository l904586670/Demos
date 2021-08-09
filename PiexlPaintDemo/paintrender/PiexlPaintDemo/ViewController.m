//
//  ViewController.m
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/19.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "ViewController.h"
#import "EditorView.h"
#import "PiexlDataManager.h"

@interface ViewController ()
@property (strong, nonatomic) EditorView *editView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat width = 350.0f;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGRect frameResult = CGRectMake(10, 80 + width, width, width);
    UIImageView *imageResultView = [[UIImageView alloc] initWithFrame:frameResult];
    imageResultView.layer.borderColor = UIColor.redColor.CGColor;
    imageResultView.layer.borderWidth = 1;
    [self.view addSubview:imageResultView];
    
    
    CGRect frame = CGRectMake(10, 70, width, width);
    self.editView = [[EditorView alloc] initWithFrame:frame];
    self.editView.clickCallback = ^(PixelMatrix * _Nullable matrix, UIColor *editColor) {
        UIImage *resultImage = [[PiexlDataManager sharedInstance] smoothImageFromPiexl:matrix editColor:editColor];
        imageResultView.image = resultImage;
    };
    self.editView.cleanCallback = ^(PixelMatrix * _Nullable matrix) {
        UIImage *resultImage = [[PiexlDataManager sharedInstance] smoothImageFromPiexl:matrix editColor:[UIColor clearColor]];
        imageResultView.image = resultImage;
    };
    [self.view addSubview:self.editView];
    
    UIButton *cleanBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, screenSize.height - 70, 55, 45)];
    [cleanBtn setTitle:@"Clear" forState:UIControlStateNormal];
    [cleanBtn setBackgroundColor:UIColor.blueColor];
    [cleanBtn addTarget:self action:@selector(onCleanClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cleanBtn];

    CGRect firstColorRect = CGRectMake( 100, screenSize.height - 70, 55, 45);
    NSArray <NSString *>*colorNames = @[ @"red", @"green", @"blue" ];
    NSArray <UIColor *>*bgColors = @[ [UIColor colorWithRed:232.0/255.0f green:39.0/255.0f blue:41.0/255.0f alpha:1.0f], [UIColor colorWithRed:121.0/255.0f green:233/255.0f blue:43.0/255.0f alpha:1.0f], [UIColor colorWithRed:48/255.0f green:147/255.0f blue:219/255.0f alpha:1.0f] ];
    for (NSInteger i = 0; i < colorNames.count; i++) {
        UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        colorBtn.frame = CGRectOffset(firstColorRect, i * 60, 0);
        [colorBtn setTitle:colorNames[i] forState:UIControlStateNormal];
        [colorBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [colorBtn setBackgroundColor:bgColors[i]];
        [colorBtn addTarget:self action:@selector(onColorClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:colorBtn];
    }
    
    UIButton *brushBtn = [[UIButton alloc] initWithFrame:CGRectMake(screenSize.width - 55, screenSize.height - 70, 55, 45)];
    [brushBtn setTitle:@"油漆" forState:UIControlStateNormal];
    [brushBtn setBackgroundColor:UIColor.blueColor];
    [brushBtn addTarget:self action:@selector(onBrushClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:brushBtn];

    [self.editView setPaintColor:bgColors[0]];
}

- (void)onCleanClick {
    [self.editView cleanView];
}

- (void)onColorClick:(UIButton *)sender {
    UIColor *selectedColor = sender.backgroundColor;
    [self.editView setPaintColor:selectedColor];
}

- (void)onBrushClick:(UIButton *)brush {
    [self.editView updateBrushColor:UIColor.blackColor];
}

@end
