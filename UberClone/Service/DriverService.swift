//
//  DriverService.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 14/02/2021.
//

import Foundation
import Firebase
import GeoFire

//MARK: - DriverService

struct DriverService {
    static let shared = DriverService()
    
    func observeTrips(completion: @escaping (Trip) -> Void) {
        REF_TRIPS.observe(.childAdded) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping (Error?, DatabaseReference)->Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values: [String: Any] = ["driverUid": uid,
                      "state": TripState.accepted.rawValue]
        REF_TRIPS.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    func observeTripCanceld(trip: Trip, completion: @escaping () -> Void) {
        REF_TRIPS.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { _ in
            completion()
        }
    }
    
    func updateTripState(trip: Trip, state: TripState, completion: @escaping (Error?, DatabaseReference) -> Void) {
        REF_TRIPS.child(trip.passengerUid).child("state").setValue(state.rawValue, withCompletionBlock: completion)
        
        if trip.state == .completed {
            REF_TRIPS.child(trip.passengerUid).removeAllObservers()
        }
    }
    
    func updateDriverLocation(location: CLLocation) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        geofire.setLocation(location, forKey: uid)
    }
    
}


