//
//  DriverAnnotation.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 03/02/2021.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    
    static let annotationIdentifier = "DriverAnnotation"
    
    dynamic var coordinate: CLLocationCoordinate2D
    
    var uid: String
    
    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updateAnnotationPosition(withCoordinate coordinate: CLLocationCoordinate2D) {
        UIView.animate(withDuration: 0.2) {
            self.coordinate = coordinate
        }
    }
    
}
