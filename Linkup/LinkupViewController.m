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
#import "LinkupUserLocation.h"
#import "ZSPinAnnotation.h"
#import "ZSAnnotation.h"

@interface LinkupViewController () <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate>

@property (nonatomic, strong) FriendFinderMapViewController *mapvc;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray* allFriends;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) FBProfilePictureView *profilePictureView;

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
                     PFQuery *queryForUserLocationForCurrentUser = [LinkupUserLocation query];
                     [queryForUserLocationForCurrentUser whereKey:FBID_KEY equalTo:user.id];
                     [queryForUserLocationForCurrentUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                         if (!error){
                             NSLog(@"querying returned %i objects with fbid %@", objects.count, user.id);
                             if (objects.count > 0) {
                                 
                                 int countInOrderToRemoveDuplicates = 0;
                                 // found UserLocation(s) so update it (them)
                                 for (LinkupUserLocation *oneUserLocation in objects) {
                                     
                                     if (countInOrderToRemoveDuplicates == 0) {
                                         // update it
                                         LinkupUserLocation *newUserLocation = [LinkupUserLocation object];
                                         newUserLocation.FBID = user.id;
                                         newUserLocation.userName = user.name;
                                         newUserLocation.currentLocation = userLocation;
                                         
                                         [newUserLocation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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
                                 LinkupUserLocation *newUserLocation = [LinkupUserLocation object];
                                 newUserLocation.currentLocation = userLocation;
                                 newUserLocation.userName = user.name;
                                 newUserLocation.FBID = user.id;
                                 
                                 [newUserLocation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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
    
    LinkupUserLocation *UserLocation = [self.allFriends objectAtIndex:indexPath.row];
    
    NSString *latitudeAsString =  [NSString stringWithFormat:@"%f", UserLocation.coordinate.latitude];
    NSString *longitudeAsString = [NSString stringWithFormat:@"%f", UserLocation.coordinate.longitude];
    
    cell.textLabel.text = UserLocation.userName;
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
            PFQuery *queryForUserLocationsOfFBFriends = [LinkupUserLocation query];
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
                    for (LinkupUserLocation *oneUserLocation in friendUserLocations) {
                        NSLog(@"Found one UserLocation for friend %@ with FBID %@", oneUserLocation.userName, oneUserLocation.FBID);
                    }
                }
            }];
        }
    }];

}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    self.mapView.delegate = self;
    [self updateMapViewAnnotations];
}

// remove all existing annotations from the map
// and add all of our photosByPhotographer to the map
// zoom the map to show them all
- (void)updateMapViewAnnotations
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    NSMutableArray *zsAnnotations = [[NSMutableArray alloc] init];
    ZSAnnotation *annotation = nil;
    for (LinkupUserLocation *location in self.allFriends) {
        annotation = [[ZSAnnotation alloc] init];
        annotation.coordinate = location.coordinate;
        annotation.title = location.userName;
        annotation.FBID = location.FBID;
        [zsAnnotations addObject:annotation];
    }
    [self.mapView addAnnotations:zsAnnotations];
    [self.mapView showAnnotations:zsAnnotations animated:YES];

}

#pragma mark - MKMapViewDelegate

// enhances our callout to have left (UIImageView) and right (UIButton) accessory views
// only does this if we are going to need to segue to a different VC to show a photo
//  (because, if not (i.e. self.imageViewController is not nil), the photo will already be on screen
//   so there is no reason to show its thumbnail or make the user click again on disclosure button)

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *reuseId = @"FriendPinOnMap";
    
    // Don't mess with user location if not of type ZSAnnotation
	if(![annotation isKindOfClass:[ZSAnnotation class]])
        return nil;
    
    // Create the ZSPinAnnotation object and reuse it
    ZSPinAnnotation *pinView = (ZSPinAnnotation *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (pinView == nil){
        pinView = [[ZSPinAnnotation alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
        pinView.leftCalloutAccessoryView = imageView;
        //THIS CODE SETS SOMETHING ON THE RIGHT SIDE OF THE ANNOTATION VIEW (in this case an image named disclosure)
        // CURERNTLY NOT USING THIS BUT WE COULD IMPLEMENT TO SEND A MESSAGE, SHOW MORE INFO ON USER, ETC...
        //        UIButton *disclosureButton = [[UIButton alloc] init];
        //        [disclosureButton setBackgroundImage:[UIImage imageNamed:@"disclosure"] forState:UIControlStateNormal];
        //        [disclosureButton sizeToFit];
        //        view.rightCalloutAccessoryView = disclosureButton;
    }
    
    pinView.annotation = annotation;
    
    // Set the type of pin to draw and the color
    pinView.annotationType = ZSPinAnnotationTypeDisc;
    pinView.annotationColor = [self randomColor];
    pinView.canShowCallout = YES;
    
    return pinView;
}

// called when the MKAnnotationView (the pin) is clicked on
// either updates the left callout accessory (UIImageView)
// or shows the Photo annotation in self.imageViewController (if available)

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
//    if (self.imageViewController) {
//        [self prepareViewController:self.imageViewController
//                           forSegue:nil
//                   toShowAnnotation:view.annotation];
//    } else {
        [self updateLeftCalloutAccessoryViewInAnnotationView:view];
//    }
}

// checks to be sure that the annotationView's left callout is a UIImageView
// if it is and if the annotation is a Photo, then shows the thumbnail
// this should do that fetch in another thread
// but when the thumbnail image came back, it would need to double check the annotationView
// to be sure it is still displaying the annotation for which we fetched
// (because MKAnnotationViews, like UITableViewCells, are reused)
//
- (void)updateLeftCalloutAccessoryViewInAnnotationView:(MKAnnotationView *)annotationView
{
    UIImageView *imageView = nil;
    if ([annotationView.leftCalloutAccessoryView isKindOfClass:[UIImageView class]]) {
        imageView = (UIImageView *)annotationView.leftCalloutAccessoryView;
    }
    if (imageView) {
        ZSAnnotation *location = nil;
        if ([annotationView.annotation isKindOfClass:[ZSAnnotation class]]) {
            location = (ZSAnnotation *)annotationView.annotation;
        }
        if (location) {
            self.profilePictureView = [[FBProfilePictureView alloc] init];
            // Set the size
            self.profilePictureView.frame = CGRectMake(0.0, 0.0, 46.0, 46.0);
            // Show the profile picture for a user
            self.profilePictureView.profileID = location.FBID;
            // Add the profile picture view to the main view
            [imageView addSubview:self.profilePictureView];
        }
    }
}

// Just return a random color for the pin. At this point I chose 4 colors, could add or remove as one sees fit.
- (UIColor *)randomColor
{
    int randomColor = arc4random() % 5;
    switch (randomColor) {
        case 0:
            return [UIColor redColor];
        case 1:
            return [UIColor blueColor];
        case 2:
            return [UIColor greenColor];
        case 3:
            return [UIColor orangeColor];
        case 4:
            return [UIColor purpleColor];
        default:
            return [UIColor blackColor];
    }
}

// Originially started typing this before I found FBProfilePicture View
//- (void)downloadFacebookThumbnail:(LinkupUserLocation*)user stringURLToFacebookProfile:(NSString *)stringUrl
//{
//    // create a (non-main) queue to do fetch on
//    dispatch_queue_t fetchQ = dispatch_queue_create("get Facebook thumbnail", NULL);
//    // put a block to do the fetch onto that queue
//    dispatch_async(fetchQ, ^{
//        if (FBSession.activeSession.isOpen) {
//            [[FBRequest requestForMe] startWithCompletionHandler:
//             ^(FBRequestConnection *connection,
//               NSDictionary<FBGraphUser> *user,
//               NSError *error) {
//                 if (!error) {
////                     FBProfilePictureView *view =
////                     UIView *fbProfilePic = [UIView alloc] init
//                 }
//             }];
//        }
//    });
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//    });
//}

// called when the right callout accessory view is tapped
// (it is the only accessory view we have that inherits from UIControl)
// will crash the program if this View Controller does not have a @"Show Photo" segue
// in the storyboard

//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
//{
//    [self performSegueWithIdentifier:@"Show Photo" sender:view];
//}

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
