//
//  ViewController.swift
//  combineUIKit2
//
//  Created by JB Gill on 2/14/20.
//  Copyright © 2020 JB Gill. All rights reserved.
//

import UIKit
import Combine


//  this is borrowed heavily from :  https://heckj.github.io/swiftui-notes/


class ViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @Published var username: String = ""
  @Published private var githubUserData: GithubAPIUser? = nil
  
  var apiNetworkActivitySubscriber: AnyCancellable?
  var usernameSubscriber: AnyCancellable?
  var avatarViewSubscriber: AnyCancellable?
  var nameLabelSubscriber: AnyCancellable?
  
  var myBackgroundQueue: DispatchQueue = DispatchQueue(label: "MyQueue", qos: .userInitiated)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    hideSpinner()
    
    let apiActivitySub = GithubAPI.networkActivityPublisher
      .receive(on: RunLoop.main)
      .sink { doingSomethingNow in
        if (doingSomethingNow) {
          self.showSpinner()
        } else {
          self.hideSpinner()
        }
    }
    apiNetworkActivitySubscriber = AnyCancellable(apiActivitySub)
    
    usernameSubscriber = $username
      .throttle(for: 0.5, scheduler: myBackgroundQueue, latest: true)
      .removeDuplicates()
      .print("username pipeline: ") // debugging output for pipeline
      .map { username -> AnyPublisher<GithubAPIUser?, Never> in
        return GithubAPI.retrieveGithubUser(username: username)
    }
    .switchToLatest()
    .receive(on: RunLoop.main)
    .assign(to: \.githubUserData, on: self)
    
    nameLabelSubscriber = $githubUserData
      .print("github user data: ")
      .map { userData -> String in
        if let user = userData {
          return String(user.name ?? "")
        }
        return "unknown"
    }
    .receive(on: RunLoop.main)
    .assign(to: \.text, on: nameLabel)
    
    let avatarViewSub = $githubUserData
        .map { userData -> AnyPublisher<UIImage, Never> in
            guard let user = userData else {
                return Just(UIImage()).eraseToAnyPublisher()
            }
            return URLSession.shared.dataTaskPublisher(for: URL(string: user.avatar_url)!)
                .handleEvents(receiveSubscription: { _ in
                    DispatchQueue.main.async {
                        self.showSpinner()
                    }
                }, receiveCompletion: { _ in
                    DispatchQueue.main.async {
                        self.hideSpinner()
                    }
                }, receiveCancel: {
                    DispatchQueue.main.async {
                        self.hideSpinner()
                    }
                })
                .map { $0.data }
                .map { UIImage(data: $0)!}
                .subscribe(on: self.myBackgroundQueue)
                .catch { err in
                    return Just(UIImage())
                }
                .eraseToAnyPublisher()
        }
        .switchToLatest()
        .subscribe(on: myBackgroundQueue)
        .receive(on: RunLoop.main)
        .map { image -> UIImage? in
            image
        }
        .assign(to: \.image, on: self.imageView)
    avatarViewSubscriber = AnyCancellable(avatarViewSub)
    
    
  }
  
  @IBAction func textFieldChanged(_ sender: UITextField) {
    username = sender.text ?? ""
    print("Set username to ", username)
  }
  
  fileprivate func hideSpinner() {
    activityIndicator.stopAnimating()
    activityIndicator.isHidden = true
  }
  
  fileprivate func showSpinner() {
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
  }
  
}

