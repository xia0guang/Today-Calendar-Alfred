import EventKit
import AppKit
import Foundation
import AlfredWorkflowScriptFilter

enum Command {
    case id
    case webex
    case detail(String)
    case none
}

//Shared instances
var store = EKEventStore()
let app = NSApplication.shared

class AppDelegate: NSObject, NSApplicationDelegate {
    var command = Command.none

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.count < 2 {
            print("invalid arguments")
            app.terminate(self)
        }

        let arg = CommandLine.arguments[1]
        switch arg {
        case "auth":
            store.requestAccess(to:.event) { _,_ in
                ScriptFilter.add(Item(title: "You Have granted permission. Please type \"acal\" to start query today's calendar event"))
                print(ScriptFilter.output())
                app.terminate(self)
            }
            app.terminate(self)
        case "detail":
            guard CommandLine.arguments.count >= 3 else {
                print("no id is provided to fetch specific event")
                app.terminate(self)
                return
            }
            let eventId = CommandLine.arguments[2]
            command = .detail(eventId)
        case "webex":
            command = .webex
        case "id":
            command = .id
        default:
            print("invalid arguments")
        }
        executeCommand(command)
        app.terminate(self)
    }

    func applicationWillTerminate(_ notification: Notification) {
        //TODO clean up, it's not needed
    }
}

//execute command
extension AppDelegate {
    func executeCommand(_ command: Command) {
        if EKEventStore.authorizationStatus(for: .event) != .authorized {
            print("please call 'auth' to grant Calendar permission")
            app.terminate(self)
        }
        
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 24, to: startTime)!
        let cals = store.calendars(for: .event)
        let todayPredicate = store.predicateForEvents(withStart: startTime, end: endTime, calendars: cals)
        let events = store.events(matching: todayPredicate)

        guard events.count > 0 else {
            ScriptFilter.add(Item(title: "There is no event in next 24 hrs"))
            print(ScriptFilter.output())
            app.terminate(self)
            return
        }

        switch command {
        case .id:
            getEvents(events, for: OutputType.id)
        case .webex:
            getEvents(events, for: OutputType.webex)
        case .detail(let eventId):
            getEvent(byId: eventId, inEventStore: store) {
                print(ScriptFilter.output())
                app.terminate(self)
            }
        case .none:
            print("no args is provide")
        }

        print(ScriptFilter.output())
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()

