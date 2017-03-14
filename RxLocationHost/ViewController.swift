//
//  ViewController.swift
//  RxLocationHost
//
//  Created by Jamie Pinkham on 3/14/17.
//  Copyright © 2017 Snagajob. All rights reserved.
//

import UIKit
import RxSwift
import RxCoreLocation

class ViewController: UIViewController {

    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GeolocationService.instance.updateLocations().subscribe(onNext: { location in
            print(location)
        }).disposed(by: disposeBag)
    }


}

