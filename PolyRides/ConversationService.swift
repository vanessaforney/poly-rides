//
//  ConversationService.swift
//  PolyRides
//
//  Created by Max Parelius on 3/21/16.
//  Copyright © 2016 Vanessa Forney. All rights reserved.
//

import FirebaseDatabase

protocol ConversationDelegate: class {
}

class ConversationService {

  var conversationDeligate: ConversationDelegate?
  let ref = FIRDatabase.database().reference()

  func pushConversationToFirebase(convo: Conversation) {
    let convoRef = ref.child("conversations").childByAutoId()
    if let driverId = convo.driver?.id {
      if let passengerId = convo.passenger?.id {
        let driverConvoRef = ref.child("users/\(driverId)/conversations/\(convoRef.key)")
        let passengerConvoRef = ref.child("users/\(passengerId)/conversations/\(convoRef.key)")
        driverConvoRef.setValue(true)
        passengerConvoRef.setValue(true)
        convoRef.setValue(convo.toAnyObject())
      }
    }
  }

}
