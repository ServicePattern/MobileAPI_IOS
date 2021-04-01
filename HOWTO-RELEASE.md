# Releasing a new MobileMessaging library version to Cocoapods
In the instructions below replace X with a partical number which is higher then the current one.
1. Increase a version in file `BPMobileMessaging.podspec`
	```ruby
	s.version          = '0.1.X'
	```
2. Modify a description about changes in file `CHANGELOG.md`
3. Update demo app:
    ```ruby
    cd Example ; pod install ; cd ..
    > Installing BPMobileMessaging 0.X.B (was 0.X.A)
    ```
4. Testing:
	```ruby
	pod lib lint
	```
5. Commit changes:
	```ruby
	git add -A && git commit -m "Release 0.X.B"
	git tag '0.X.B'
	git push --tags
	```
6. Submitting
	```ruby
	pod trunk push BPMobileMessaging.podspec
	```
