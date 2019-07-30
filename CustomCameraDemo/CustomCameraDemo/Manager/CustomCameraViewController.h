//
//  CustomCameraViewController.h
//
//  Created by Rock on 2018/9/28.
//  Copyright © 2018 Yiqux. All rights reserved.
//

#import "YiquxViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CustomCameraViewControllerDelegate <NSObject>

- (void)CustomCameraViewControllerDidTakePhoto:(UIImage *)image;

@end

@interface CustomCameraViewController : YiquxViewController

@property(nonatomic, weak) id<CustomCameraViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
