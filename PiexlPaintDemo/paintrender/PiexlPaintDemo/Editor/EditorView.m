//
//  EditorView.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/26.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "EditorView.h"

@interface EditorView()
@property (nonatomic, strong) PixelMatrix* matrix;
@property (nonatomic, assign) NSInteger btnCount;
@property (nonatomic, strong) NSMutableArray<UIButton *>* btnArray;

@property (nonatomic, strong) UIColor *paintColor;

@end

@implementation EditorView {
    NSInteger _colorComponents[4]; // r g b a [0 ~ 255]
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.btnCount = 20;
        self.btnArray = [NSMutableArray array];
        self.paintColor = [UIColor blackColor];
        
        [self createMatrix];
        [self createButtonUI:frame];
    }
    return self;
}

- (void)createMatrix {
    self.matrix = [[PixelMatrix alloc] initWithRow:self.btnCount col:self.btnCount];
    for (NSInteger r = 0; r < self.matrix.row; ++r) {
        for (NSInteger c = 0; c < self.matrix.col; ++c) {
            PixelModel *model = [[PixelModel alloc] init];
            [self.matrix setValue:model row:r col:c];
        }
    }
}

- (void)createButtonUI:(CGRect)frame {
    CGFloat width = frame.size.width;
    CGFloat height = frame.size.height;
    CGFloat btnWidth = width/self.btnCount;
    CGFloat btnHeight = height/self.btnCount;
    
    for (int i = 0; i < self.btnCount; i++) {
        for (int j = 0; j < self.btnCount; j++) {
            CGRect btnFrame = CGRectMake(i*btnWidth, j*btnWidth, btnWidth, btnHeight);
            UIButton *button = [[UIButton alloc] initWithFrame:btnFrame];
            button.layer.borderColor = UIColor.lightGrayColor.CGColor;
            button.layer.borderWidth = 0.5f;
            button.tag = i * self.btnCount + j;
            [button addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            [self.btnArray addObject:button];
        }
    }
}

- (void)onButtonClick:(UIButton* )btn {
    NSInteger tag = btn.tag;
    NSInteger col = (NSInteger)(tag / self.btnCount);
    NSInteger row = tag % self.btnCount;
    PixelModel *model = [self.matrix valueAtRow:row col:col];
    model.alpha = model.alpha == 0 ? 255 : 0;
    
    if (CGColorEqualToColor(btn.backgroundColor.CGColor, _paintColor.CGColor)) {
        //
        [model setClearColor];
        [btn setBackgroundColor:[UIColor clearColor]];
    } else {
        model.red = _colorComponents[0];
        model.green = _colorComponents[1];
        model.blue = _colorComponents[2];
        model.alpha = _colorComponents[3];
        [btn setBackgroundColor:_paintColor];
    }
    [self.matrix setValue:model row:row col:col];

    if (self.clickCallback != nil) {
        self.clickCallback(self.matrix, self.paintColor);
    }
}

-(void)cleanView {
    for (UIButton *btn in self.btnArray) {
        [btn setBackgroundColor:[[UIColor alloc] initWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
    }
    for (NSInteger r = 0; r < self.matrix.row; ++r) {
        for (NSInteger c = 0; c < self.matrix.col; ++c) {
            PixelModel *model = [self.matrix valueAtRow:r col:c];
            model.alpha = 0;
        }
    }
    if (self.cleanCallback != nil) {
        self.cleanCallback(self.matrix);
    }
}

- (void)setPaintColor:(UIColor *)color {
    if (!color) {
        return;
    }
    _paintColor = color;
    
    CGFloat r = 0.0;
    CGFloat g = 0.0;
    CGFloat b = 0.0;
    CGFloat a = 0.0;
    BOOL result = [color getRed:&r green:&g blue:&b alpha:&a];
    if (result) {
        NSInteger red = floor(r * 255);
        NSInteger green = floor(g * 255);
        NSInteger blue = floor(b * 255);
        NSInteger alpha = floor(a * 255);
        
        _colorComponents[0] = red;
        _colorComponents[1] = green;
        _colorComponents[2] = blue;
        _colorComponents[3] = alpha;
    }
}

- (void)updateBrushColor:(UIColor *)color {
    if (!color) {
        return;
    }
    
    _paintColor = color;
    
    CGFloat r = 0.0;
    CGFloat g = 0.0;
    CGFloat b = 0.0;
    CGFloat a = 0.0;
    BOOL result = [color getRed:&r green:&g blue:&b alpha:&a];
    if (result) {
        NSInteger red = floor(r * 255);
        NSInteger green = floor(g * 255);
        NSInteger blue = floor(b * 255);
        NSInteger alpha = floor(a * 255);
        
        _colorComponents[0] = red;
        _colorComponents[1] = green;
        _colorComponents[2] = blue;
        _colorComponents[3] = alpha;
    }
    
    for (NSInteger r = 0; r < self.matrix.row; ++r) {
        for (NSInteger c = 0; c < self.matrix.col; ++c) {
            PixelModel *model = [self.matrix valueAtRow:r col:c];
            model.red = _colorComponents[0];
            model.green = _colorComponents[1];
            model.blue = _colorComponents[2];
            model.alpha = _colorComponents[3];
        }
    }
    
    if (self.clickCallback != nil) {
        self.clickCallback(self.matrix, self.paintColor);
    }
}

@end
