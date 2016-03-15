//
//  UIViewControllerExtensions.swift
//  PolyRides
//
//  Created by Vanessa Forney on 3/13/16.
//  Copyright © 2016 Vanessa Forney. All rights reserved.
//

struct AlertOptions {

  static let DefaultMessage = "Error"
  static let DefaultTitle = "An error occurred. Please try again."

  let title: String
  let message: String
  let acceptText: String
  let handler: ((UIAlertAction) -> Void)?
  let showCancel: Bool

  init(message: String = DefaultMessage, title: String = DefaultTitle, acceptText: String = "OK",
    handler: ((UIAlertAction) -> Void)? = nil, showCancel: Bool = false) {
      self.message = message
      self.title = title
      self.acceptText = acceptText
      self.handler = handler
      self.showCancel = showCancel
  }
}

extension UIViewController {

  func presentAlert(alertOptions: AlertOptions = AlertOptions()) {
    let title = alertOptions.title
    let message = alertOptions.message
    let acceptText = alertOptions.acceptText
    let handler = alertOptions.handler
    let style = UIAlertControllerStyle.Alert

    let alert = UIAlertController(title: title, message: message, preferredStyle: style)
    alert.addAction(UIAlertAction(title: acceptText, style: .Default, handler: handler))
    if alertOptions.showCancel {
      alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    }
    self.presentViewController(alert, animated: true, completion: nil)
  }

  func trackScreen(screenName: String) {
    GoogleAnalyticsHelper.trackScreen(screenName)
  }

}