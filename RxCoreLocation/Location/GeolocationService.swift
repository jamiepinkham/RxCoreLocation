//
//  GeolocationService.swift
//  SnagFoundation
//
//  Created by Casey Liss on 19/2/16.
//  Copyright © 2016 Snagajob. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

/**
 Defintes a service that provides the user's location.
*/
public protocol GeolocationServiceProtocol {

    /**
     Updates the user's location.
     
     - Returns: An `Observable` of `CLLocationCoordinate2D` objects
                that give the user's current location.
    */
    func updateLocations() -> Observable<CLLocationCoordinate2D>

    /** Gets the user's current location
    - Returns: An `Observable of `CLLocationCoordinate2D` that is the 
    user's current location or nil if the user hasn't authorized location services
    */
    func currentLocation() -> Observable<CLLocationCoordinate2D?>

    /**
     Gets an `Observable` that indicates whether or not the app
     is permitted to get the user's location.
    */
    var authorized: Observable<Bool> { get }

    /**
    Gets the current authorization status
    */
    var currentAuthorization: CLAuthorizationStatus { get }

    /** 
     Request location services permission
     
     - Param: `always` should we request always permission
     - Returns: - Returns: `CLAuthorizationStatus` in an `Observable`.
    */
    func requestAuthorization(always: Bool) -> Observable<CLAuthorizationStatus>

    /**
     Gets the authentication status as an `Observable`.
     
     - Returns: `CLAuthorizationStatus` in an `Observable`.
    */
    var authStatus: Observable<CLAuthorizationStatus> { get }

}


/**
 A service that can provide the user's location.
*/
public class GeolocationService: GeolocationServiceProtocol {

    /**
     The shared instance of this class.
    */
    public static let instance = GeolocationService()

    /**
     Gets an `Observable` flag indicating whether or not
     the user has permitted location access.
    */
    public fileprivate (set) var authorized: Observable<Bool>
    public private (set) var authStatus: Observable<CLAuthorizationStatus>
    fileprivate let disposeBag = DisposeBag()

    fileprivate let locationManager = CLLocationManager()

    fileprivate init() {
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers

        authStatus = Observable.deferred { [weak locationManager] in
            let status = CLLocationManager.authorizationStatus()
            guard let locationManager = locationManager else {
                return Observable.just(status)
            }
            return locationManager
                .rx.didChangeAuthorizationStatus
                .startWith(status)
            }
        
        authorized = authStatus.map({ (status) -> Bool in
            switch status {
            case .authorizedAlways:
                return true
            default:
                return false
            }
        })
    }

    public func requestAuthorization(always: Bool = false) -> Observable<CLAuthorizationStatus> {

        if always {
            self.locationManager.requestAlwaysAuthorization()
        } else {
            self.locationManager.requestWhenInUseAuthorization()
        }
        return self.authStatus
    }

    public func currentLocation() -> Observable<CLLocationCoordinate2D?> {

        return Observable.create { [weak self] (observer) in

            // this guard is commented out in order to produce the error
//            guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
//                 CLLocationManager.authorizationStatus() == .authorizedAlways,
             guard let manager = self?.locationManager else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            let location = manager.rx.didUpdateLocations
                .map { $0.last?.coordinate }
                .subscribe(observer)

            self?.locationManager.requestLocation()

            let cancel = Disposables.create(with: {
                self?.locationManager.stopUpdatingLocation()
            })

            return CompositeDisposable(cancel, location)

        }

    }

    /**
     Gets an `Observable` with the user's current location. This
     `Observable` should not terminate.
    */
    public func updateLocations() -> Observable<CLLocationCoordinate2D> {
        let observable = locationManager.rx.didUpdateLocations
            .filter { $0.count > 0 }
            .map { $0.last!.coordinate }

        locationManager.startUpdatingLocation()
        return observable
    }

    public var currentAuthorization: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

}
