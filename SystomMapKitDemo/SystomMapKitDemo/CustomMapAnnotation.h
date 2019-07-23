//
//  CustomMapAnnotation.h
//  SystomMapKitDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

// Title and subtitle for use by selection UI.
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *subtitle;

// Called as a result of dragging an annotation view.
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate NS_AVAILABLE(10_9, 4_0);
@end

NS_ASSUME_NONNULL_END
