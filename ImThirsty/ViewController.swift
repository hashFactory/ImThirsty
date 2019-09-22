//
//  ViewController.swift
//  ImThirsty
//
//  Created by Tristan Charpentier on 18/09/2019.
//  Copyright © 2019 Tristan Charpentier. All rights reserved.


import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let locationManager = CLLocationManager()
    var timer = Timer()
    var data = DataInput();
    
    var results = [DataInput.DataPoint]()
    var previousHeadings = [Double]()
    
    /*private func loadResults() {
        
        // guard let result1 =
    }*/
    
    @IBOutlet weak var myLocationDisplay: UITextView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.refreshButton.addTarget(self, action: Selector(("refreshLocation")), for: .touchUpInside)
        
        self.locationManager.requestWhenInUseAuthorization()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        data.readFile(name: "water2");
        
        if CLLocationManager.locationServicesEnabled() {
            // locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
            scheduledTimerWithTimeInterval()
            // self.view.addSubview(label)
            
            refreshLocation()
        }
        
        myLocationDisplay.textContainer.maximumNumberOfLines = 10
        myLocationDisplay.textContainer.lineBreakMode = .byTruncatingTail
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: Selector(("refreshLocation")), userInfo: nil, repeats: true)
    }
    
    @objc func refreshLocation() {

        guard let locationLatLong = locationManager.location else {
            return
        }
        
        guard let locationHeading = locationManager.heading else {
            return
        }
        
        let locationString = "Latitude:\t\t\(locationLatLong.coordinate.latitude)°N\nLongitude:\t\(locationLatLong.coordinate.longitude)°E\nBearing:\t\t\(locationHeading.magneticHeading)°"
        
        myLocationDisplay.text = locationString
        
        results = data.quickFind(lat: locationLatLong.coordinate.latitude, long: locationLatLong.coordinate.longitude, heading: locationHeading.magneticHeading, num: 10)
        
        self.tableView.reloadData()
        
        print("Horizontal: \(locationLatLong.horizontalAccuracy)\nVertical: \(locationLatLong.verticalAccuracy)")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "ResultTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ResultTableViewCell else {
            fatalError("Couldn't instantiate cell")
        }
        
        let result = results[indexPath.row]
        var savedPrevious: Double = 0.0
        
        if previousHeadings.count < results.count {
            self.previousHeadings.append(self.results[indexPath.row].heading)
        }
        else {
            savedPrevious = self.previousHeadings[indexPath.row]
            self.previousHeadings[indexPath.row] = self.results[indexPath.row].heading
        }
        
        cell.distanceLabel.text = String(round(result.dist)) + " m"
        
        // TODO: ************ Implement image generation
        cell.distanceDirection.transform = .identity
        cell.distanceDirection.image = UIImage(named: "arrow")
        cell.distanceDirection.transform = .identity
        cell.distanceDirection.transform = CGAffineTransform(rotationAngle: CGFloat(data.toRadians(value: savedPrevious)))
        UIView.animate(withDuration: 0.2) {
            cell.distanceDirection.transform = CGAffineTransform(rotationAngle: CGFloat(self.data.toRadians(value:  self.results[indexPath.row].heading)))
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print(String("comgooglemaps://?center=" + String(self.results[indexPath.row].lat) + "," + String(self.results[indexPath.row].long) + "&zoom=14"))
        let urlString = String("http://maps.google.com/?daddr=" + String(self.results[indexPath.row].lat) + "," + String(self.results[indexPath.row].long) + "&directionsmode=driving")
        
        if let url = URL(string: urlString)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            /*
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Can't use comgooglemaps://");
            }*/
        }
    }
    
    

}

