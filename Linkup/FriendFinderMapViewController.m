//
//  FriendFinderMapViewController.m
//  Linkup
//
//  Created by Jesse Clayburgh on 11/14/13.
//  Copyright (c) 2013 j&d. All rights reserved.
//

#import "FriendFinderMapViewController.h"
#import <MapKit/MapKit.h>



#define CURRENT_LOCATION_KEY @"currentLocation"


@interface FriendFinderMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation FriendFinderMapViewController
//
//- (void)setAllFriends:(NSArray *)allFriends
//{
//    _allFriends = [[NSArray alloc] initWithArray:allFriends];
////    self.title = photographer.name;
////    self.photosByPhotographer = nil;
//    [self updateMapViewAnnotations];
//}


@end
