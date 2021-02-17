//
//  Service.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 02/02/2021.
//

import Firebase
import GeoFire

//MARK: - Database Refs
let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")
let REF_TRIPS = DB_REF.child("trips")


//MARK: - SharedService

struct SharedService {
    static let shared = SharedService()

    func fetchUserDate(uid: String, completion: @escaping (User)-> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let user = User(uid: uid, dictionary: dictionary)
            completion(user)
        }
    }
}
