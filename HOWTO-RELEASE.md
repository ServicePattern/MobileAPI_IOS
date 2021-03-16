# Releasing a new MobileMessaging library version to Cocoapods
In the instructions below replace X with a partical number which is higher then the current one.
1. Increase a version in file `BPMobileMessaging.podspec`
	```ruby
	s.version          = '0.1.X'
	```
2. Testing:
	```ruby
	pod lib lint
	```
3. Commit changes:
	```ruby
	git add -A && git commit -m "Release 0.1.X"
	git tag '0.1.X'
	git push --tags
	```
4. Submitting
	```ruby
	pod trunk push BPMobileMessaging.podspec
	```