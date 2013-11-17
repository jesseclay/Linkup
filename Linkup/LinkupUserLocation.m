//
//  LinkupUserLocation.m
//  Linkup
//
//  Created by Jesse Clayburgh on 11/16/13.
//  Copyright (c) 2013 j&d. All rights reserved.
//

#import "LinkupUserLocation.h"
#import <Parse/PFObject+Subclass.h>

@implementation LinkupUserLocation

+ (NSString *)parseClassName {
    return @"UserLocation";
}

@dynamic FBID;
@dynamic userName;
@dynamic currentLocation;


// This is for the MKAnnotation delegate
- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    
    coordinate.latitude = [self.currentLocation latitude];
    coordinate.longitude = [self.currentLocation longitude];
    
    return coordinate;
}

- (NSString *)title
{
    return self.userName;
}

- (NSString *)subtitle
{
    // return a string here for pin subtitle
    return nil;
}

@end
