//
//  ViewController.swift
//  combineUIKit
//
//  Created by JB Gill on 2/13/20.
//  Copyright © 2020 JB Gill. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {

  @IBOutlet weak var usernameField: UITextField!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var publicReposLabel: UILabel!
  @IBOutlet weak var avatarLabel: UILabel!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  var apiRequestSubscriber: AnyCancellable?  // need this as a class-level reference because
  
  override func viewDidLoad() {
    super.viewDidLoad()
    activateSpinner(false)
  }


  @IBAction func goPressed(_ sender: Any) {
    guard let username = usernameField.text,
          username.count > 3
    else {
      return
    }
    
    activateSpinner(true)
    
    apiRequestSubscriber = GithubAPI.retrieveGithubUser(username: username)
      .receive(on: RunLoop.main)
      .sink() {[weak self] githubUserData in
        self?.activateSpinner(false)
        self?.populateUI(githubUserData)
        self?.apiRequestSubscriber = nil // this causes the pipeline to be torn down
      }
  }
  
  fileprivate func populateUI(_ githubUserData: GithubAPIUser?) {
    print("in populateUI")
    fullNameLabel.text = githubUserData?.name
    usernameLabel.text = githubUserData?.login
    if let repos = githubUserData?.public_repos {
      publicReposLabel.text = String(repos)
    } else {
      publicReposLabel.text = ""
    }
    avatarLabel.text = githubUserData?.avatar_url
  }
  
  fileprivate func activateSpinner(_ isOn: Bool) {
    if isOn {
      activityIndicator.isHidden = false
      activityIndicator.startAnimating()
    } else {
      activityIndicator.isHidden = true
      activityIndicator.stopAnimating()
    }
  }
}

