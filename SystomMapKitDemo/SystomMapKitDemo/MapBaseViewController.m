//
//  MapBaseViewController.m
//  SystomMapKitDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "MapBaseViewController.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "RandomTool.h"
#import "CustomMapAnnotation.h"

static NSString * const kMapId = @"duohuanMapId";

@interface MapBaseViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, assign) BOOL testOnce;

@end

@implementation MapBaseViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
  
  [self checkDeviceSupportLocation];
 
  [self mapView];
  
  [self locationManager];
}

- (void)dealloc {
  NSLog(@"---map Vc dealloc---");
}

#pragma mark - UI

- (void)setupUI {
  
  UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
  [resetBtn addTarget:self action:@selector(onResetLocationTouch) forControlEvents:UIControlEventTouchUpInside];
  
  UIBarButtonItem *resetItem = [[UIBarButtonItem alloc] initWithCustomView:resetBtn];
  
  self.navigationItem.rightBarButtonItem = resetItem;
}

#pragma mark - Lazy Methods

- (MKMapView *)mapView {
  if (!_mapView) {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGRect frame = CGRectMake(0, posY, screenSize.width, screenSize.height - posY);
    
    _mapView = [[MKMapView alloc] initWithFrame:frame];
    [self.view addSubview:_mapView];
    //设置用户的跟踪模式
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
    //设置标准地图
    _mapView.mapType = MKMapTypeStandard;
    // 不显示罗盘和比例尺
    if (@available(iOS 9.0, *)) {
      _mapView.showsCompass = NO;
      _mapView.showsScale = NO;
    }
    // 开启定位
    _mapView.showsUserLocation = YES;
    _mapView.delegate = self;
    //初始位置及显示范围
    MKCoordinateSpan span = MKCoordinateSpanMake(0.021251, 0.016093);
    [_mapView setRegion:MKCoordinateRegionMake(self.mapView.userLocation.coordinate, span) animated:YES];
  }
  return _mapView;
}

- (CLLocationManager *)locationManager {
  if (!_locationManager) {
    //判断定位功能是否打开
    if ([CLLocationManager locationServicesEnabled]) {
      _locationManager = [[CLLocationManager alloc] init];
      _locationManager.delegate = self;
      [_locationManager requestWhenInUseAuthorization];
      
      //设置寻址精度
      _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
      _locationManager.distanceFilter = 10.0;
      [_locationManager startUpdatingLocation];
    }
  }
  return _locationManager;
}

#pragma mark - Action

- (void)onResetLocationTouch {
  // 定位到我的位置
  [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate
                           animated:YES];
}

#pragma mark - Private Methods

- (void)checkDeviceSupportLocation {
  if (![CLLocationManager locationServicesEnabled]) {
  
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"你的设备不支持定位服务" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertController addAction:sureAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    return;
  }
  
  
  if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无法定位" message:@"您的设备目前未开启定位服务，如欲开启定位服务，请开启定位服务功能" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"去开启" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
      } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
      }
    }];
    [alertController addAction:sureAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
  }
}

/**
 根据当前的用户定位获取周边的设备位置信息

 @param latitude 纬度
 @param longitude 经度
 @param handler 返回的设备位置
 */
- (void)getDeviceLocationInfoWithLatitude:(double)latitude longitude:(CLLocationDegrees)longitude callBack:(void(^)(BOOL success, NSArray <NSDictionary *> *results ))handler {
  
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //
    sleep(1.0);
    
    NSMutableArray <NSDictionary *>*infos = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
      
      CGFloat randomLatitude = [RandomTool randomFloatWithMin:0.01 max:0.02] - 0.015  + latitude;
      CGFloat randomLongitude = [RandomTool randomFloatWithMin:0.01 max:0.02] - 0.015 + longitude;
      NSDictionary *location = @{
                                 @"latitude" : [NSNumber numberWithFloat:randomLatitude],
                                 @"longitude" : [NSNumber numberWithFloat:randomLongitude]
                                 };
      [infos addObject:location];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (handler) {
        handler(YES, infos);
      }
    });
  });
}

- (void)addPointAnnotationWithLatitude:(double)latitude longitude:(double)longitude {
  CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
  
  CustomMapAnnotation *item = [[CustomMapAnnotation alloc] init];
  
  item.coordinate = coordinate;
  item.title = @"多幻";
  
  CLGeocoder *geocoder = [[CLGeocoder alloc] init];
  CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
  
  [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray * _Nullable placemarks, NSError * _Nullable error) {
    if (!error && placemarks.count > 0) {
      
      CLPlacemark *mark = placemarks.firstObject;
      item.subtitle = mark.thoroughfare;
    } else {
      NSLog(@"[map Error] : %@", error.description);
    }
  }];
  
  [_mapView addAnnotation:item];
  
//  MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinate radius:50];
//  [self.mapView addOverlay:circle];
}

#pragma mark - MKMapViewDelegate
// 将要改变region时调用。如果scroll则会调用很多次
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
}
// region改变后调用。如果scroll则会调用很多次
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
  
}

- (void)mapViewDidChangeVisibleRegion:(MKMapView *)mapView {
  
}
// 开始下载地图块（map tiles）时候调用
- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
}
// 地图块下载完成时调用
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
}
// 地图块下载失败
- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
  
}

- (void)mapViewWillStartRenderingMap:(MKMapView *)mapView {
  
}

//渲染结束时调用。fullyRendered：是否成功渲染
- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
}

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
  // 判断是否是用户位置
  if (annotation == self.mapView.userLocation) {
    return nil;
  }
  // 指定标注重用标识符
  MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:kMapId];
  if (!annotationView) {
    annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMapId];
  }
  
  annotationView.image = [UIImage imageNamed:@"icon_map_cateid_5"];
//  annotationView.leftCalloutAccessoryView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"userpic"]];
  annotationView.canShowCallout = YES;
  
  return annotationView;
}

// mapView:didAddAnnotationViews: is called after the annotation views have been added and positioned in the map.
// The delegate can implement this method to animate the adding of the annotations views.
// Use the current positions of the annotation views as the destinations of the animation.
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views {
  
}

#if TARGET_OS_IPHONE
// mapView:annotationView:calloutAccessoryControlTapped: is called when the user taps on left & right callout accessory UIControls.
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
  
}
#endif

// 点击标注时调用
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
  NSLog(@"mapView: %s", __func__);
  
  if (view.annotation == mapView.userLocation) {
    return;
  }
  
  UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:nil message:@"到这去" preferredStyle:UIAlertControllerStyleActionSheet];
  
  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"导航" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    MKMapItem *myLocation = [MKMapItem mapItemForCurrentLocation];
    
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:view.annotation.coordinate addressDictionary:@{}];
    
    MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:placemark];
    NSArray *items = @[myLocation,toLocation];
    
    NSDictionary *options = @{ MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeWalking, MKLaunchOptionsMapTypeKey: [NSNumber numberWithInteger:MKMapTypeStandard], MKLaunchOptionsShowsTrafficKey:@YES };
    [MKMapItem openMapsWithItems:items launchOptions:options];
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
  [alertSheet addAction:sureAction];
  [alertSheet addAction:cancelAction];
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    UIPopoverPresentationController *popover = alertSheet.popoverPresentationController;
    
    popover.sourceView = self.view;
    popover.sourceRect = self.view.bounds;
  }
  [self presentViewController:alertSheet animated:YES completion:nil];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
  NSLog(@"mapView: %s", __func__);
}

// 将要获取用户位置。showsUserLocation设为YES后调用
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView {
  NSLog(@"mapView: %s", __func__);
}

// showsUserLocation设为NO后调用
- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView {
  NSLog(@"mapView: %s", __func__);
}

// 用户位置更新或者Head更新时调用。后台运行不会调用
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
  [self.locationManager stopUpdatingHeading];
  
  CLLocation *location = userLocation.location;
  //跨度
  MKCoordinateSpan span = MKCoordinateSpanMake(0.013, 0.013);
  
  //区域
  MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, span);
  
  //让地图显示设置的区域
  [mapView setRegion:region];
  
  CLGeocoder *geocoder = [[CLGeocoder alloc] init];
  
  __weak typeof(self) weakSelf = self;
  
  [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray * _Nullable placemarks, NSError * _Nullable error) {
    if (!error && placemarks.count > 0) {
      CLPlacemark *mark = placemarks.firstObject;
      userLocation.title = mark.locality;
      userLocation.subtitle = mark.thoroughfare;
      NSLog(@"user local : %@/%@", mark.locality, mark.thoroughfare);
      
      if (!weakSelf.testOnce) {
        [self getDeviceLocationInfoWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude callBack:^(BOOL success, NSArray<NSDictionary *> *results) {
          if (success) {
            for (NSDictionary *info in results) {
              
              [self addPointAnnotationWithLatitude:[info[@"latitude"] doubleValue] longitude:[info[@"longitude"] doubleValue]];
            }
          }
          
#warning To Do ..
        }];
        weakSelf.testOnce = YES;
      }
   
    } else {
      NSLog(@"[map Error] : %@", error.description);
    }
  }];
}

// 尝试锁定用户位置失败
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState
   fromOldState:(MKAnnotationViewDragState)oldState {
  
}

#if TARGET_OS_IPHONE
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
}
#endif

// 添加圆形扩散区域
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
  // 创建圆形区域渲染对象
  if ([overlay isKindOfClass:[MKCircle class]]) {
    MKCircleRenderer *circleRender = [[MKCircleRenderer alloc] initWithOverlay:overlay];
    circleRender.fillColor = [UIColor cyanColor];
    circleRender.alpha = 0.3;
    return circleRender;
  }
  
  return nil;
}
- (void)mapView:(MKMapView *)mapView didAddOverlayRenderers:(NSArray<MKOverlayRenderer *> *)renderers {
}

#if TARGET_OS_IPHONE
// Prefer -mapView:rendererForOverlay:
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{
  
  return nil;
}
// Called after the provided overlay views have been added and positioned in the map.
// Prefer -mapView:didAddOverlayRenderers:
- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews {
  
}
#endif

// Return nil for default MKClusterAnnotation, it is illegal to return a cluster annotation not containing the identical array of member annotations given.
- (MKClusterAnnotation *)mapView:(MKMapView *)mapView clusterAnnotationForMemberAnnotations:(NSArray<id<MKAnnotation>>*)memberAnnotations API_AVAILABLE(ios(11.0)) {
  return nil;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading {
  NSLog(@"[LocationManager] %s", __func__);
  
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(nonnull NSError *)error {
   NSLog(@"[LocationManager] fail : %@", error);
}

@end
