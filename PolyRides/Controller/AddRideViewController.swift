//
//  AddRideViewController.swift
//  PolyRides
//
//  Created by Vanessa Forney on 3/17/16.
//  Copyright © 2016 Vanessa Forney. All rights reserved.
//

import GoogleMaps
import GooglePlaces

class AddRideViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

  let gpaKey = "AIzaSyBV7uveXT1JXkp149zLJgmCb2U-caWuH84"
  let rideService = RideService()

  var user: User?
  var ride: Ride?
  var toPlace: GMSPlace?
  var fromPlace: GMSPlace?
  var autocompleteTextField: UITextField?
  var placesClient: GMSPlacesClient?
  var activeView: UITextView?
  var keyboardRect: CGRect?

  var activeFieldRect: CGRect?

  @IBOutlet weak var toPlaceTextField: UITextField?
  @IBOutlet weak var fromPlaceTextField: UITextField?
  @IBOutlet weak var datePicker: UIDatePicker?
  @IBOutlet weak var seatsLabel: UILabel?
  @IBOutlet weak var costTextField: UITextField?
  @IBOutlet weak var notesTextView: UITextView?
  @IBOutlet weak var addButton: UIBarButtonItem?
  @IBOutlet weak var scrollView: UIScrollView?


  @IBAction func switchToFromAction(sender: AnyObject) {
    let tempPlace = toPlace
    let tempText = toPlaceTextField?.text
    toPlace = fromPlace
    toPlaceTextField?.text = fromPlaceTextField?.text
    fromPlace = tempPlace
    fromPlaceTextField?.text = tempText
  }

  @IBAction func cancelButtonAction(sender: AnyObject) {
    navigationController?.dismiss(animated: true, completion: nil)
  }

  @IBAction func stepperValChanged(sender: UIStepper) {
      seatsLabel?.text = Int(sender.value).description
  }

  @IBAction func costEditingChanged(sender: AnyObject) {
    if let currentValue = costTextField?.text {
      let strippedValue = currentValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
      var formattedString = ""

      if strippedValue.characters.count > 0 {
        formattedString = "$\(strippedValue)"
      }
      costTextField?.text = formattedString
      setEnableAddButton()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    registerForKeyboardNotifications()

    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
    view.addGestureRecognizer(tap)

    scrollView?.frame = self.view.frame
    scrollView?.isScrollEnabled = false
    scrollView?.showsVerticalScrollIndicator = false
    scrollView?.showsHorizontalScrollIndicator = false

    toPlaceTextField?.delegate = self
    fromPlaceTextField?.delegate = self
    notesTextView?.delegate = self
    datePicker?.setValue(UIColor.white, forKey: "textColor")

    placesClient = GMSPlacesClient()
    setupAppearance()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "addRide" {
      if var cost = costTextField?.text {
        if var description = notesTextView?.text {
          if let seats = seatsLabel?.text {
            if let date = datePicker?.date {
              cost = cost.replacingOccurrences(of: "$", with: "")
              if let user = user {
                if description == "Optional notes for passengers" {
                  description = ""
                }

              let ride =
                  Ride(driver: user, date: date as NSDate, seats: Int(seats), description: description, cost: Int(cost))
                ride.fromLocation = locationFromPlace(place: fromPlace)
                ride.toLocation = locationFromPlace(place: toPlace)
                ride.timestamp = NSDate()
                rideService.pushRideToFirebase(ride: ride)
                self.ride = ride
              }
            }
          }
        }
      }
    } else if segue.identifier == "toAutocomplete" {
      if let navVC = segue.destination as? UINavigationController {
        if let vc = navVC.topViewController as? AutocompleteViewController, let textField = sender as? UITextField {
          vc.delegate = self
          vc.initialText = textField.text
          vc.user = user
        }
      }
    }
  }

  override func shouldPerformSegue(withIdentifier: String, sender: Any?) -> Bool {
    if withIdentifier == "addRide" {
      if let date = datePicker?.date {
        if date.compare(NSDate() as Date) == ComparisonResult.orderedAscending {
          let title = "Invalid Depature Date"
          let message = "Rides in the past cannot be posted. Please adjust your departure date."
          presentAlert(alertOptions: AlertOptions(message: message, title: title))

          return false
        }
      }
    }
    return true
  }

  func setEnableAddButton() {
    if toPlace != nil && fromPlace != nil && costTextField?.text != nil {
      addButton?.isEnabled = true
    }
  }

  func locationFromPlace(place: GMSPlace?) -> Location? {
    if let place = place {
      if let city = place.addressComponents?.city {
        return Location(place: place, city: city)
      } else {
        return Location(place: place, city: place.name)
      }
    }
    return nil
  }

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if textField == toPlaceTextField || textField == fromPlaceTextField {
      autocompleteTextField = textField
      performSegue(withIdentifier: "toAutocomplete", sender: textField)
      return false
    }
    return true
  }

  override func viewDidLayoutSubviews() {
    scrollView?.sizeToFit()
    scrollView?.contentSize = (scrollView?.frame.size)!
    super.viewDidLayoutSubviews()
  }

  deinit {
    self.deregisterFromKeyboardNotifications()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  func registerForKeyboardNotifications() {
    //Adding notifies on keyboard appearing
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(ScrollingFormViewController.keyboardWasShown),
                                           name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(ScrollingFormViewController.keyboardWillBeHidden),
                                           name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }


  func deregisterFromKeyboardNotifications() {
    //Removing notifies on keyboard appearing
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }

  func keyboardWasShown(notification: NSNotification) {
    let info: NSDictionary = notification.userInfo! as NSDictionary
    keyboardRect = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    adjustForKeyboard()
  }


  func keyboardWillBeHidden(notification: NSNotification) {
    keyboardRect = nil
    adjustForKeyboard()
  }

  func adjustForKeyboard() {
    if keyboardRect != nil && activeFieldRect != nil {
      let aRect: CGRect = scrollView!.convert(activeFieldRect!, to: nil)
      if (keyboardRect!.contains(CGPoint(x: aRect.origin.x, y: aRect.maxY))) {
        scrollView?.isScrollEnabled = true
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardRect!.size.height, 0.0)
        scrollView?.contentInset = contentInsets
        scrollView?.scrollIndicatorInsets = contentInsets
        scrollView?.scrollRectToVisible(activeFieldRect!, animated: true)
      }
    } else {
      let contentInsets: UIEdgeInsets = UIEdgeInsets.zero
      scrollView?.contentInset = contentInsets
      scrollView?.scrollIndicatorInsets = contentInsets
      scrollView?.isScrollEnabled = false
    }
  }

  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    activeFieldRect = textView.frame
    adjustForKeyboard()
    return true
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    activeFieldRect = nil
    adjustForKeyboard()
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    activeFieldRect = textField.frame
    adjustForKeyboard()
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    activeFieldRect = nil
    adjustForKeyboard()
  }
  
  func dismissKeyboard() {
    //Causes the view (or one of its embedded text fields) to resign the first responder status.
    view.endEditing(true)
  }

}

// MARK: - AutocompleteDelegate
extension AddRideViewController: AutocompleteDelegate {

  func onPlaceSelected(placePrediction place: GMSPlace?) {
    autocompleteTextField?.text = place?.formattedAddress
    if autocompleteTextField == toPlaceTextField {
      toPlace = place
    } else {
      fromPlace = place
    }
  }

}
