//
//  LinkupViewController.m
//  Linkup
//
//  Created by Jesse Clayburgh on 11/14/13.
//  Copyright (c) 2013 j&d. All rights reserved.
//

#import "LinkupViewController.h"
#import "FriendFinderMapViewController.h"
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>

@interface LinkupViewController () <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate>

@property (nonatomic, strong) FriendFinderMapViewController *mapvc;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray* allFriends;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation LinkupViewController

#define USER_LOCATION_KEY @"UserLocation"
#define CURRENT_LOCATION_KEY @"currentLocation"
#define USERNAME_KEY @"userName"
#define FBID_KEY @"FBID"


@synthesize tableView = _tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    PFGeoPoint *userLocation =
    [PFGeoPoint geoPointWithLatitude:locationManager.location.coordinate.latitude
                           longitude:locationManager.location.coordinate.longitude];
    
    
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *user,
           NSError *error) {
             if (!error) {
                 
                 // first check to see if a location object exists for this user
                 NSLog(@"querying to see if this person already has a UserLocation entry on Parse!");
                 if ([PFUser currentUser]) {
                     PFQuery *queryForUserLocationForCurrentUser = [PFQuery queryWithClassName:USER_LOCATION_KEY];
                     [queryForUserLocationForCurrentUser whereKey:FBID_KEY equalTo:user.id];
                     [queryForUserLocationForCurrentUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                         if (!error){
                             NSLog(@"querying returned %i objects with fbid %@", objects.count, user.id);
                             if (objects.count > 0) {
                                 
                                 int countInOrderToRemoveDuplicates = 0;
                                 // found UserLocation(s) so update it (them)
                                 for (PFObject *oneUserLocation in objects) {
                                     
                                     if (countInOrderToRemoveDuplicates == 0) {
                                         // update it
                                         PFObject *PFUserLocation = oneUserLocation;
                                         [PFUserLocation setObject:userLocation forKey:CURRENT_LOCATION_KEY];
                                         [PFUserLocation setObject:user.name forKey:USERNAME_KEY];
                                         [PFUserLocation setObject:user.id forKey:FBID_KEY];
                                         [PFUserLocation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                             if (!error) {
                                                 // The Person saved successfully. Good.
                                                 NSLog(@"Success -- updated UserLocation with FBID %@!", user.id);
                                             } else {
                                                 NSLog(@"Failure -- could not update UserLocation with FBID %@", user.id);
                                             }
                                         }];
                                         countInOrderToRemoveDuplicates = 1;
                                     } else if (countInOrderToRemoveDuplicates == 1) {
                                         // these are duplicates -- delete them
                                         [oneUserLocation deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                             if (!error) {
                                                 // The Person saved successfully. Good.
                                                 NSLog(@"REMOVED duplicate UserLocation with FBID %@!", user.id);
                                             } else {
                                                 NSLog(@"FAILED TO REMOVE -- could not update UserLocation with FBID %@", user.id);
                                             }
                                         }];
                                         
                                     }
                                 }
                             } else {
                                 // no UserLocation found, so create one and push it to Parse
                                 PFObject *PFUserLocation = [PFObject objectWithClassName:USER_LOCATION_KEY];
                                 [PFUserLocation setObject:userLocation forKey:CURRENT_LOCATION_KEY];
                                 [PFUserLocation setObject:user.name forKey:USERNAME_KEY];
                                 [PFUserLocation setObject:user.id forKey:FBID_KEY];
                                 [PFUserLocation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                     if (!error) {
                                         // The Person saved successfully. Good.
                                         NSLog(@"Success -- updated UserLocation with FBID %@!", user.id);
                                     } else {
                                         NSLog(@"Failure -- could not create UserLocation with FBID %@", user.id);
                                     }
                                 }];

                             }
                             
                         
                         }
                         
                     }];
                     
                 }

                 // if yes, just update it
                 
                 
                 
                 
                 [self returnAllFacebookFriendsOnParse];
             }
         }];
    }
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allFriends count];
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//	return @"Friends";
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Facebook Friend"];
    
    PFObject *UserLocation = [self.allFriends objectAtIndex:indexPath.row];
    
    PFGeoPoint *aGeoPoint = UserLocation[CURRENT_LOCATION_KEY];
    NSString *latitudeAsString =  [NSString stringWithFormat:@"%f", aGeoPoint.latitude];
    NSString *longitudeAsString = [NSString stringWithFormat:@"%f", aGeoPoint.longitude];
    
    cell.textLabel.text = UserLocation[USERNAME_KEY];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Latitude: %@| Longitude: %@", latitudeAsString, longitudeAsString];
//    cell.detailTextLabel.text = photo.subtitle;
    
    return cell;
}

- (void)returnAllFacebookFriendsOnParse
{
    
    // NOTE: This is if we want to display all UserLocations from Parse (as opposed)
    //         to just FB friends
    // CURRENTLY: OFF
//    NSLog(@"querying for all UserLocation PFObjects!");
//    if ([PFUser currentUser]) {
//        PFQuery *queryForAllUserLocationObjects = [PFQuery queryWithClassName:USER_LOCATION_KEY];
//        [queryForAllUserLocationObjects findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//            if (!error){
//                NSLog(@"querying returned %i objects", objects.count);
//                self.allFriends = [[NSArray alloc] initWithArray:objects];
//                [self.tableView reloadData];
//                [self updateMapViewAnnotations];
//            }
//            
//        }];
//
//    }
    
    // Issue a Facebook Graph API request to get your user's friend list
    NSLog(@"Going for gold");
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result will contain an array with your user's friends in the "data" key
            NSArray *friendObjects = [result objectForKey:@"data"];
            NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
            // Create a list of friends' Facebook IDs
            for (NSDictionary *friendObject in friendObjects) {
                [friendIds addObject:[friendObject objectForKey:@"id"]];
            }
            
            // Construct a  query that will find UserLocation PFObjects with matching FBIDs.
            PFQuery *queryForUserLocationsOfFBFriends = [PFQuery queryWithClassName:USER_LOCATION_KEY];
            [queryForUserLocationsOfFBFriends whereKey:FBID_KEY containedIn:friendIds];
            
            // findObjects will return a list of PFUsers that are friends
            // with the current user
            [queryForUserLocationsOfFBFriends findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    self.allFriends = [[NSArray alloc] initWithArray:objects];
                    [self.tableView reloadData];
                    [self updateMapViewAnnotations];

                    // NOTE: This is to log everyone who is a FB friend
                    // CURRENTLY: ON
                    NSArray *friendUserLocations = objects;
                    for (PFObject *oneUserLocation in friendUserLocations) {
                        NSLog(@"Found one UserLocation for friend %@ with FBID %@", oneUserLocation[USERNAME_KEY], oneUserLocation[FBID_KEY]);
                    }
                }
            }];
        }
    }];

}

//- (void)setMapView:(MKMapView *)mapView
//{
//    _mapView = mapView;
//    self.mapView.delegate = self;
//    [self updateMapViewAnnotations];
//}

// remove all existing annotations from the map
// and add all of our photosByPhotographer to the map
// zoom the map to show them all
- (void)updateMapViewAnnotations
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for (PFObject *location_object in self.allFriends) {
        PFGeoPoint *PFUserLocation = location_object[CURRENT_LOCATION_KEY];
        
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        
        CLLocationCoordinate2D aCoordinate = {PFUserLocation.latitude, PFUserLocation.longitude};
        
        point.coordinate = aCoordinate;
        
        [self.mapView addAnnotation:point];
    }
}

//
//#pragma mark segue to map
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.destinationViewController isKindOfClass:[FriendFinderMapViewController class]]) {
//        FriendFinderMapViewController *ffmvc =
//        (FriendFinderMapViewController *)segue.destinationViewController;
//        // set the embedded PhotosByPhotographerMapViewController's Model
//        ffmvc.allFriends = self.allFriends;
//        // hold onto the embedded PhotosByPhotographerMapViewController
//        // in case our Model is nil right now
//        // and then set it later when our Model gets set by the photographer property's setter
//        self.mapvc = ffmvc;
//    } else {
//        // not embedding, let our superclass do any segues it can do
//        [super prepareForSegue:segue sender:sender];
//    }
//}

@end
