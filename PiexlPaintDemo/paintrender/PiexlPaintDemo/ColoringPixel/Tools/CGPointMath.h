//
//  CGPointMath.h
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/21.
//  Copyright © 2020 PointOne. All rights reserved.
//

#ifndef CGPointMath_h
#define CGPointMath_h


/// 判断Point是否为Nan
CG_INLINE BOOL
CGPointIsNaN(CGPoint point) {
    return isnan(point.x) || isnan(point.y);
}

/**
 Returns point multiplied by given factor. 乘以指定倍数
*/
CG_INLINE CGPoint
CGPointApplyScale(CGPoint point, CGFloat scale) {
    return CGPointMake(point.x * scale, point.y * scale);
}

/**
 Returns opposite of point. 取反值
 */
CG_INLINE CGPoint
CGPointNeg(CGPoint point) {
    return CGPointMake(-point.x, -point.y);
}

/**
 Calculates sum of two points. 两点相加
 */
CG_INLINE CGPoint
CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

/**
 Calculates difference of two points.两点相减，
 */
CG_INLINE CGPoint
CGPointSub(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x - point2.x, point1.y - point2.y);
}

/**
 Calculates midpoint between two points. 取两点的中间点
 */
CG_INLINE CGPoint
CGPointMidpoint(CGPoint v1, CGPoint v2) {
    return CGPointApplyScale(CGPointAdd(v1, v2), 0.5f);
}

/**
 Calculates dot product of two points. 求点积
 */
CG_INLINE CGFloat
CGPointDot(CGPoint v1, CGPoint v2) {
    return v1.x*v2.x + v1.y*v2.y;
}

/**
 Calculates cross product of two points. 求差积
 */
CG_INLINE CGFloat
CGPointCross(CGPoint v1, CGPoint v2) {
    return v1.x*v2.y - v1.y*v2.x;
}

/** Calculates perpendicular of v, rotated 90 degrees counter-clockwise -- cross(v, perp(v)) >= 0
 */
CG_INLINE CGPoint
CGPointPerp(CGPoint v) {
    return CGPointMake(-v.y, v.x);
}

/** Calculates perpendicular of v, rotated 90 degrees clockwise -- cross(v, rperp(v)) <= 0
 @return CGPoint
 */
CG_INLINE CGPoint
CGPointRPerp(CGPoint v) {
    return CGPointMake(v.y, -v.x);
}

/** Calculates the projection of v1 over v2.
 @return CGPoint
 */
CG_INLINE CGPoint
CGPointProject(CGPoint v1, CGPoint v2) {
    return CGPointApplyScale(v2, CGPointDot(v1, v2)/CGPointDot(v2, v2));
}

/** Rotates two points.
 @return CGPoint
 */
CG_INLINE CGPoint
CGPointRotate(CGPoint v1, CGPoint v2) {
    return CGPointMake(v1.x*v2.x - v1.y*v2.y, v1.x*v2.y + v1.y*v2.x);
}

/** Unrotates two points.
 @return CGPoint
 */
CG_INLINE CGPoint
CGPointUnrotate(CGPoint v1, CGPoint v2) {
    return CGPointMake(v1.x*v2.x + v1.y*v2.y, v1.y*v2.x - v1.x*v2.y);
}

/** Calculates the square length of a CGPoint (not calling sqrt() )
 @return CGFloat
 */
CG_INLINE CGFloat
CGPointLengthSQ(CGPoint v) {
    return CGPointDot(v, v);
}

/** Calculates the square distance between two points (not calling sqrt() )
 @return CGFloat
*/
CG_INLINE CGFloat
CGPointDistanceSQ(CGPoint p1, CGPoint p2) {
    return CGPointLengthSQ(CGPointSub(p1, p2));
}

/** Calculates distance between point an origin
 @return CGFloat
 */
CG_INLINE CGFloat
CGPointLength(CGPoint v) {
    return (CGFloat)sqrt(CGPointLengthSQ(v));
}

/** Calculates the distance between two points
 @return CGFloat
 */
CG_INLINE CGFloat
CGPointDistance(CGPoint v1, CGPoint v2) {
    return CGPointLength(CGPointSub(v1, v2));
}

/** Returns point multiplied to a length of 1. 归一化
 @return CGPoint
 */
CG_INLINE CGPoint
CGPointNormalize(CGPoint v) {
    return CGPointApplyScale(v, 1.0f/CGPointLength(v));
}

/** Converts radians to a normalized vector.
 @return CGPoint
 */
CG_INLINE CGPoint
CGPointForAngle(CGFloat a) {
    return CGPointMake((CGFloat)cos(a), (CGFloat)sin(a));
}

/** Converts a vector to radians.
 @return CGFloat
 */
CG_INLINE CGFloat
CGPointToAngle(CGPoint v) {
    return (CGFloat)atan2(v.y, v.x);
}

/** Quickly convert CGSize to a CGPoint
*/
CG_INLINE CGPoint
CGPointFromSize(CGSize size) {
    return CGPointMake(size.width, size.height);
}

/** Linear Interpolation between two points a and b
 @returns
    alpha == 0 ? a
    alpha == 1 ? b
    otherwise a value between a..b
 */
CG_INLINE CGPoint
CGPointLerp(CGPoint a, CGPoint b, float alpha) {
    return CGPointAdd(CGPointApplyScale(a, 1.f - alpha), CGPointApplyScale(b, alpha));
}

#endif /* CGPointMath_h */
