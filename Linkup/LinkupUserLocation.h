//
//  LinkupUserLocation.h
//  Linkup
//
//  Created by Jesse Clayburgh on 11/16/13.
//  Copyright (c) 2013 j&d. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LinkupUserLocation : PFObject<PFSubclassing, MKAnnotation>

@property (retain) NSString *FBID;

@property (retain) NSString *userName;

@property (retain) PFGeoPoint *currentLocation;

+ (NSString *)parseClassName;

@end
