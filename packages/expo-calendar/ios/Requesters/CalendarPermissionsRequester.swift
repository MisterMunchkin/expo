import ExpoModulesCore
import EventKit

public class CalendarPermissionsRequester: NSObject, EXPermissionsRequester {
  private let eventStore: EKEventStore

  init(eventStore: EKEventStore) {
    self.eventStore = eventStore
  }

  static public func permissionType() -> String {
    return "calendar"
  }

  public func getPermissions() -> [AnyHashable: Any] {
    var status: EXPermissionStatus
    var permissions: EKAuthorizationStatus

    let description = {
      if #available(iOS 17.0, *) {
        return "NSCalendarsFullAccessUsageDescription"
      }
      return "NSCalendarsUsageDescription"
    }()

    if Bundle.main.object(forInfoDictionaryKey: description) != nil {
      permissions = EKEventStore.authorizationStatus(for: .event)
    } else {
      EXFatal(MissingCalendarPListValueException(description))
      permissions = .denied
    }

    switch permissions {
    case .restricted, .denied, .writeOnly:
      status = EXPermissionStatusDenied
    case .notDetermined:
      status = EXPermissionStatusUndetermined
    case .fullAccess:
      status = EXPermissionStatusGranted
    @unknown default:
      status = EXPermissionStatusUndetermined
    }

    return ["status": status.rawValue]
  }

  public func requestPermissions(resolver resolve: @escaping EXPromiseResolveBlock, rejecter reject: @escaping EXPromiseRejectBlock) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents { [weak self] _, error in
        guard let self else {
          return
        }
        if let error {
          reject("E_CALENDAR_ERROR_UNKNOWN", error.localizedDescription, error)
        } else {
          resolve(self.getPermissions())
        }
      }
    } else {
      eventStore.requestAccess(to: .event) { [weak self] _, error in
        guard let self else {
          return
        }
        if let error {
          reject("E_CALENDAR_ERROR_UNKNOWN", error.localizedDescription, error)
        } else {
          resolve(self.getPermissions())
        }
      }
    }
  }
}
