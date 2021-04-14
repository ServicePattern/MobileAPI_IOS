# CHANGELOG

The changelog for `BPMobileMessaging`. Also see the [releases](https://github.com/ServicePattern/MobileAPI_IOS/releases) on GitHub.

## [0.1.5](https://github.com/ServicePattern/MobileAPI_IOS/releases/tag/0.1.5)

### Fixed
- Sample application improvements and fixes
- [Issue 27](https://github.com/ServicePattern/MobileAPI_IOS/issues/27): Phone number should not be mandatory
- [Issue 29](https://github.com/ServicePattern/MobileAPI_IOS/issues/29): Second chat session would not poll for events if application has been moved to background and then restored

### Added

 - Missing error codes added to the `ContactCenterError` enumeration
 - `getVersion()` method and corresponding `ContactCenterVersion` structure
 
### Changed

### Removed


## [0.1.4](https://github.com/ServicePattern/MobileAPI_IOS/releases/tag/0.1.4)

### Fixed

- [Issue 22](https://github.com/ServicePattern/MobileAPI_IOS/issues/22): Can't compile library with swift 5
- Fixed JSON deserialization of optional `ewt` attribute in `ContactCenterChatSessionProperties` and `ContactCenterServiceAvailability`

### Added

### Changed

- **Breaking Change** Updated to Swift 5.0

### Removed


## [0.1.3](https://github.com/ServicePattern/MobileAPI_IOS/releases/tag/0.1.3)

- First pre-release.
