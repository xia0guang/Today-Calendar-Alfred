//
//  Authorization.swift
//  Today_Calendar_Alfred
//
//  Created by Ray Wu on 4/21/21.
//

import Foundation
import EventKit
import AlfredWorkflowScriptFilter

func requestAccess(store: EKEventStore) {
    store.requestAccess(to:.event) { _,_ in
        ScriptFilter.add(Item(title: "You Have granted permission. Please type \"acal\" to start query today's calendar event"))
        print(ScriptFilter.output())
    }
    Thread.sleep(forTimeInterval: 2.0)
}
