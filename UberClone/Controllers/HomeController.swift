//
//  HomeController.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 01/02/2021.
//

import UIKit
import Firebase
import MapKit


private enum ActionButtonConfiguration {
    case showMenu
    case dismissActonView
    
    init() {
        self = .showMenu
    }
}

private enum AnnotationType: String {
    case pickup
    case destination
}

protocol HomeControllerDelegate: class {
    func handleMenuToggle()
}


class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    
    private let locationManager = LocationHandler.shared.locationManager
    
    private let inputActivationView = LocationInputActivationView()
    
    private let rideActionView = RideActionView()
    
    private let locationInputView = LocationInputView()
    
    private let tableView = UITableView()
    
    private final let locationInputViewHeight: CGFloat = 200
    
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    
    private var searchResult = [MKPlacemark]()
    private var savedLocations = [MKPlacemark]()
    
    weak var delegate: HomeControllerDelegate?
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            locationInputView.user = user
            
            if user.accountType == .passenger {
                fetchDrivers()
                configureInputActivationView()
                print("before configure saved location: \(user)")
                configureSavedUserLocations()
            } else {
                driverObserveTrips()
            }
        }
    }
    
    
    private var trip: Trip? {
        didSet {
            guard let user = user else { return }
            guard let trip = trip else { return }
            if user.accountType == .driver {
                let pickupVC = PickupController(trip: trip)
                pickupVC.delegate = self
                pickupVC.modalPresentationStyle = .fullScreen
                present(pickupVC, animated: true, completion: nil)
            }
        }
    }
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        enableLocationServices()
        configureUI()
        print("Home user: \(user)")
    }
    
    //MARK: - Selectors
    
    @objc func actionButtonPressed() {
        switch actionButtonConfig {
        case .showMenu:
            delegate?.handleMenuToggle()
            
        case .dismissActonView:
            removeAnnotationsAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
        }
    }
    
    
    //MARK: - Passenger API
    
    func fetchDrivers() {
        guard let userLocation = locationManager?.location else { return }
        PassengerService.shared.fetchDrivers(aroundLocation: userLocation) { driver in
            guard let driverCoordinate = driver.location?.coordinate else { return }
            let newAnnotation = DriverAnnotation(uid: driver.uid, coordinate: driverCoordinate)
            
            var driverIsVisible: Bool {
                return self.mapView.annotations.contains { annotation -> Bool in
                    guard let currentAnno = annotation as? DriverAnnotation else { return false}
                    if currentAnno.uid == driver.uid {
                        // update driver position here
                        currentAnno.updateAnnotationPosition(withCoordinate: driverCoordinate)
                        self.zoomForActivTrip(withDriverUid: driver.uid)
                        return true
                    }
                    return false
                }
            }
            if !driverIsVisible {
                self.mapView.addAnnotation(newAnnotation)
            }
        }
    }
    
    func startTrip() {
        guard let trip = trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .inProgress) { (error, ref) in
            self.rideActionView.rideActionConfig = .tripInProgress
            self.removeAnnotationsAndOverlays()
            self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            
            let destinationPlaceMark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let destinationItem = MKMapItem(placemark: destinationPlaceMark)
            self.generatePolyline(toDestination: destinationItem)
            
            self.setCustomRegion(withType: .destination, coordinates: trip.destinationCoordinates)
            
            //self.mapView.zoomToFit(annotations: self.mapView.annotations)
        }
    }
    
    func observeCurrentTripForUser() {
        PassengerService.shared.observeCurrentTrip { (trip) in
            self.trip = trip
            guard let tripStateUserSide = trip.state else { return }
            
            switch tripStateUserSide {
            case .requested:
                break
                
            case .denied:
                self.shouldPresentLoadingView(false)
                self.presentAlertController(withTitle: "Oops", message: "It looks like we couldn't find you a driver. Please try again..")
                PassengerService.shared.deleteTrip { (error, ref) in
                    self.removeAnnotationsAndOverlays()
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.inputActivationView.alpha = 1
                }
                
            case .accepted:
                guard let driverUid = trip.driverUid else { return }
                self.shouldPresentLoadingView(false)
                self.removeAnnotationsAndOverlays()
                self.zoomForActivTrip(withDriverUid: driverUid)
                SharedService.shared.fetchUserDate(uid: driverUid) { (driver) in
                    self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
                
            case .driverArrived:
                self.rideActionView.rideActionConfig = .driverArrived
                
            case .inProgress:
                self.rideActionView.rideActionConfig = .tripInProgress
                
            case .arrivedDestination:
                self.rideActionView.rideActionConfig = .endTrip
                
            case .completed:
                PassengerService.shared.deleteTrip { (error, ref) in
                    self.animateRideActionView(shouldShow: false)
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    UIView.animate(withDuration: 0.3) {
                        self.inputActivationView.alpha = 1
                    }
                    self.presentAlertController(withTitle: "Trip Completed", message: "We hope you enjoyed your trip")
                }
            }
        }
    }
    
    
    //MARK: - Driver API
    
    func driverObserveTripCancelled(trip: Trip) {
        DriverService.shared.observeTripCanceld(trip: trip) {
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationsAndOverlays()
            self.presentAlertController(withTitle: "Oops!", message: "The Passenger has decide to cancel this ride. Press OK to continue")
        }
    }
    
    
    func driverObserveTrips() {
        DriverService.shared.observeTrips { (trip) in
            self.trip = trip
        }
    }
 
    
    // MARK: - Helper Functions
    
    func configureUI() {
        configureMapView()
        addActionButton()
        configureTableView()
        configureRideActionView()
    }
    
    func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height * 0.33)
    }
    
    func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil,
                               config: RideActionViewConfiguration? = nil, user: User? = nil) {
        
        let height = shouldShow ? self.view.frame.height * 0.67 : self.view.frame.height
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = height
        }
        if shouldShow {
            if let destination = destination {
                rideActionView.destination = destination
            }
            if let user = user {
                rideActionView.user = user
            }
            guard let config = config else { return }
            rideActionView.rideActionConfig = config
        }
    }
    
    
    func addActionButton() {
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
    }
    
    
    fileprivate func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        case .dismissActonView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        }
        actionButtonConfig = config
    }
    
    
    func configureInputActivationView() {
        
        view.addSubview(inputActivationView)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32,
                                   width: view.frame.width - 64, height: 50)
        inputActivationView.centerX(inView: view)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 0.7) {
            self.inputActivationView.alpha = 1
        }
    }
    
    
    func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.frame
        // show user location and tracking
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    
    func configureLocationInputView() {
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0
        locationInputView.delegate = self
        
        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        } completion: { (_) in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.cellId)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        view.addSubview(tableView)
    }
    
    func removeAnnotationsAndOverlays() {
        // Remove Annotation from map
        mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        // Remove PolyLine
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    func configureSavedUserLocations() {
        guard let user = user else { return }
        print("User: \(user)")
        savedLocations.removeAll()
        if let homeLocation = user.homeLocation {
            print("homeLocation: \(homeLocation)")
            geocodeAddressString(address: homeLocation)
        }
        
        if let workLocation = user.workLocation {
            print("workLocation: \(workLocation)")
            geocodeAddressString(address: workLocation)
        }
        print("Saved Locations final \(savedLocations)")
    }
    
    func geocodeAddressString(address: String) {
        print("Address: \(address)")
        let geoCoder = CLGeocoder()

        geoCoder.geocodeAddressString(address) { (clPlacemarks, error) in
            guard let clPlacemark = clPlacemarks?.first else { return }
            let placemark = MKPlacemark(placemark: clPlacemark)
            print("PlaceMark: \(placemark.title)")
            self.savedLocations.append(placemark)
            self.tableView.reloadData()
        }
    }
}


//MARK: - MapView Helper Functions

private extension HomeController {
    
    func searchBy(naturalLanguageQuery: String, completion: @escaping ([MKPlacemark])-> Void) {
        var result = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if let error = error {
                print("can't fetch result with error \(error)")
                return
            }
            guard let response = response else { return }
            response.mapItems.forEach { item in
                result.append(item.placemark)
            }
            completion(result)
        }
    }
    
    func dismissInputViews(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    
    func generatePolyline(toDestination destination: MKMapItem) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequset = MKDirections(request: request)
        directionRequset.calculate { (response, error) in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
            
        }
    }
    
    func centerMapOnUserLocation() {
        guard let coordinates = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
    
    func setCustomRegion(withType type: AnnotationType, coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManager?.startMonitoring(for: region)
        print("setCustom Region \(region)")
    }
    
    func zoomForActivTrip(withDriverUid uid: String) {
        var tripAnnotationsArray = [MKAnnotation]()
        mapView.annotations.forEach { (annotation) in
            if let driverAnnotation = annotation as? DriverAnnotation {
                if driverAnnotation.uid == uid {
                    tripAnnotationsArray.append(driverAnnotation)
                }
            }
            if let userLocation = annotation as? MKUserLocation {
                tripAnnotationsArray.append(userLocation)
            }
        }
        print(tripAnnotationsArray)
        //mapView.zoomToFit(annotations: tripAnnotationsArray)
    }
}


//MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: DriverAnnotation.annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(polyline: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = user else { return }
        guard user.accountType == .driver else { return }
        guard let location = userLocation.location else { return }
        DriverService.shared.updateDriverLocation(location: location)
        
    }
}



//MARK: - LocationServices

extension HomeController: CLLocationManagerDelegate {
    
    func enableLocationServices() {
        locationManager?.delegate = self
        switch locationManager?.authorizationStatus {
        case .notDetermined:
            print("Not Determined")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied, .none:
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            print("Auth always")
        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
            print("Auth when in use")
        @unknown default:
            break
        }
    }
    
    // tell delegate that a new region is being monitored
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        if region.identifier == AnnotationType.pickup.rawValue {
            print("start monitor pickup region \(region)")
        }
        else {
            print("start monitor destination region \(region)")
        }
    }
    
    // tell delegate that the user entered the specified region.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip = trip else { return }
        if region.identifier == AnnotationType.pickup.rawValue {
            print("Driver did enter pasenger region \(region)")
            DriverService.shared.updateTripState(trip: trip, state: .driverArrived) { (error, ref) in
                self.rideActionView.rideActionConfig = .pickupPassenger
            }
        }
        else {
            print("Driver did enter destination region \(region)")
            DriverService.shared.updateTripState(trip: trip, state: .arrivedDestination) { (error, ref) in
                self.rideActionView.rideActionConfig = .endTrip
            }
        }
    }
}


//MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}


//MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    
    func excuteSearch(from query: String) {
        searchBy(naturalLanguageQuery: query) { (results) in
            self.searchResult = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissInputViews { _ in
            UIView.animate(withDuration: 0.5) {
                self.inputActivationView.alpha = 1
            }
        }
    }
}


//MARK: - UITableViewDataSource, UITableViewDelegate

extension HomeController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return section == 0 ? savedLocations.count : searchResult.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.cellId) as! LocationCell
        
        if indexPath.section == 0 {
            cell.placeMark = savedLocations[indexPath.row]
            print(savedLocations[indexPath.row].title)
        }else {
            cell.placeMark = searchResult[indexPath.row]
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Saved Locations" : "Search Results"
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedPlacemark = indexPath.section == 0 ? savedLocations[indexPath.row] : searchResult[indexPath.row]
            
            configureActionButton(config: .dismissActonView)
            // Draw a PolyLine
            let destination = MKMapItem(placemark: selectedPlacemark)
            generatePolyline(toDestination: destination)
            // Dismiss Input View
            dismissInputViews { _ in
                self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
                // filter the point annotation and userLocation
                let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self)})
                self.mapView.showAnnotations(annotations, animated: true)
                //self.mapView.zoomToFit(annotations: annotations)
                self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
            }
    }
}

//MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    
    func observeUserCurrentTrip() {
        observeCurrentTripForUser()
    }
 
    
    func userUploadTrip(_ view: RideActionView) {
        guard let pickupCordinates = locationManager?.location?.coordinate else { return }
        guard let destinationCordinates = view.destination?.coordinate else { return }
        
        shouldPresentLoadingView(true, message: "Finding you a ride..")
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = self.view.frame.height
        }
        PassengerService.shared.uploadTrip(pickupCordinates, destinationCordinates) { (error, ref) in
            if let error = error {
                print("Failed to uplad trip with error : \(error)")
                return
            }
            print("User upload the trip")
        }
    }
    
    
    func userCancelTrip() {
        PassengerService.shared.deleteTrip { (error, ref) in
            if let error = error {
                print("Error deleting the trip with error \(error.localizedDescription)")
                return
            }
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationsAndOverlays()
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
            }
        }
    }
    
    func pickupPassenger() {
        startTrip()
    }
    
    
    func dropOffPassenger() {
        guard let trip = trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .completed) { (error, ref) in
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
        }
    }
}

//MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    // Driver accept the trip
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        
        setCustomRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        //mapView.zoomToFit(annotations: mapView.annotations)
        
        driverObserveTripCancelled(trip: trip)
        
        self.dismiss(animated: true) {
            guard let passengerUid = trip.passengerUid else { return }
            SharedService.shared.fetchUserDate(uid: passengerUid) { (passenger) in
                self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
}

