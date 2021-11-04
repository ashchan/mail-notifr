## 2.1.0 (Nov 4, 2021)

* Add support for Drag & Drop to re-order accounts
* Fix unread count setting issue

## 2.0.3 (Oct 29, 2021)

* Fix zero messages notification sound issue

## 2.0.2 (Oct 26, 2021)

* Fix an issue that caused missing menu items for disabled account

## 2.0.1 (Oct 24, 2021)

* Fix notification sound issue

## 2.0.0 (Oct 23, 2021)

* Add support for Google OAuth 2.0
* Access unread messages using Google Gmail API
* No longer require password
* Optimized for latest OS and hardware

## 1.3.5 (July 18, 2015)

* Fix a bug that fails to authenticate on OS X 10.11 Beta 4

## 1.3.4 (Mar 15, 2015)

* Fix a bug that shows the wrong unread count

## 1.3.3 (Mar 9, 2015)

* Fix a crash when messages from feed have different count from the value declared by feed

## 1.3.2 (Nov 6, 2014)

* Fix 'blinking' icon issue

## 1.3.1 (Oct 24, 2014)

* Add Compose Mail feature
* Fix duplicated separator menu item bug
* Update icons (black only)
* Gray menu icon when all accounts are disabled

## 1.3.0 (Oct 8, 2014)

* Support 10.10 Dark Mode
* Move 'Enable/Disable Account' menu item to bottom
* Add an 'Info' preference tab linkings to Feedback and FAQs

## 1.2.2 (Apr 18, 2014)

* Add shortcut (CMD+V) for pasting password
* Improve localizations
* Use outlined and smaller menu icons

## 1.2.1 (Apr 15, 2014)

* Remove the annoying checking (arrow) icon
* Update menu icons (blue icon for having new messages)
* Add Finnish localization

## 1.2.0 (Mar 29, 2014)

* Show messages under top level menu if there's only one account
* Add Polish localization
* Improve Italian localization

## 1.1.0 (Mar 16, 2014)

* Support global shortcut to trigger 'Check All'
* Fixes a crash when parsing a message's timestamp results in null date

## 1.0.1 (Feb 4, 2014)

* Fix Launch at login
* Allow closing Preferences window via CMD+W

## (App Store) 1.0 (Jan 31, 2014)

* 1.0 and above will update on App Store only

## .0.9.0 (Jan 31, 2014)

* Bugfix &amp; performance optimization
* App Store (paid) version released

## 0.8.0 (Mar 17, 2013)

* Smaller binary size and memory usage. The app has been re-written (yes again) in Objective-C.
* Click Notification Center items to open account. If growl is installed and enabled growl notificatin will be used instead.
* Bugfix: Auto launch not working on some 10.8 machines.
* Optimized icon for retina.

## 0.7.0 (Sep 16, 2012)

* Mountain Lion 10.8 support. Basic Notification Center feature was also added.

## 0.6.4 (Feb 25, 2012)

* Bugfix: crash on adding new account (bug in v0.6.3).

## 0.6.3 (Feb 25, 2012)

* Added browser setting. Now you can set each account to open in different browsers! Support Safari, Google Chrome and Firefox. - thanks to Akinori MUSHA
* Bugfix: mailto handling not working.
* Added Dutch localization. - thanks to Ico Davids
* Note: Doesn't run on Mountain Lion 10.8, not yet be able to fix it very soon. Follow the author (@ashchan) on twitter if you have suggestions or feedbacks.

## 0.6.2 (July 31, 2011)

* Fixed Snow Leopard issue.

## 0.6.1 (July 27, 2011)

* Bugfix: Multiple accounts show same result from a single account.
* Bugfix: Crash on updating menu. Now more stable on Lion.

## 0.6.0 (July 25, 2011)

* Lion compatible.
* The whole app has been rewritten in MacRuby.
* Several localization and issue fix.
* Note: This is the test build for Lion, some functionalities might not be doing well. Due to the fact it embeds the MacRuby framework, the app size is bigger.

## 0.5.2 (Aug 30, 2010)

* Enhancements on mailto handler, now should support most situations.
* Localization Fix (German)

## 0.5.1 (Aug 20, 2010)

* Localization Fix
* Can now set as default email reader to handle mailto link in browser (please set it under Preferences of Mail.app)

## 0.5.0 (Sep 21, 2009)

* Support separate checking and notification setting for each account
* Option to Enable/Disable account
* Option to hide unread message count in memu bar
* Click on message subject menu item opens that message
* Show message summary as menu item tooltip on message subject
* Show last check time for each account
* Localization for Simplified Chinese, French, Japanese, Italian and German

## 0.4.4 (Aug 31, 2009)

* Bugfix: Message count doesn't show in menu bar under Snow Leopard
* Note: A new beta version has also been released (still marked as v0.4.3) at http://ashchan.com/gn-beta.zip. It’s not stable yet so try it at your own risk. Don’t be mad of me if it doesn’t work well.

## 0.4.3 (Aug 2, 2009)

* New icons from Iiro J&auml;ppinen (http://iirojappinen.com/)
* Do not notify if there's a connection or wrong username/password error

## 0.4.2 (Apr 18, 2009)

* Bugfix: Crash when startup items are empty

## 0.4.1 (Feb 12, 2009)

* Updated icons (don't update if you like the current icons; don't be mad if the new set are not looking good for you)

## 0.4.0 (Feb 3, 2009)

* Added Sparkle Update support and packaged as DMG
* Add unread messages count to menu items for accounts
* Click on menu items for accounts goes to inbox

## 0.3.5 (Feb 1, 2009)

* Use Leopard style icons

## 0.3.4 (Jan 27, 2009)

* Bugfix: Special characters in the password not recognized

## 0.3.3 (Jan 26, 2009)

* Bugfix: Crash on adding user account
* Reset timer(interval) when check mail by menu

## 0.3.2 (Jan 8, 2009)

* Bugfix: Username/password could not be saved

## 0.3.1 (Jan 7, 2009)

* Add hint to guide new user to add an account
* Bugfix: Crash when there’s no account information
* Bugfix: Crash when new message doesn’t have a subject

## 0.3.0 (Jan 7, 2009)

* Multiple accounts support, finally!

## 0.2.8 (Dec 7, 2008)

* Do not notify if unread messages unchanged
* Open Inbox with https

## 0.2.7 (Nov 20, 2008)

* Bugfix: Exit sometimes due to onClick error of the grwol notification
* Handle Gmail feed connect timeout error

## 0.2.6 (Nov 14, 2008)

* Bugfix: Crash when set launch at login
* Bugfix: Crash on launch
* Do not show count number if there is no new message

## 0.2.5 (Nov 12, 2008)

* Play the sound when selected in Preferences window

## 0.2.4 (Nov 7, 2008)

* Added growl and sound notification settings to Preferences
* Got rid of the ssl warning in system log:  "peer certificate won't be verified in this SSL session"

## 0.2.2 (Nov 3, 2008)

* Goto inbox when click on the growl notification
* Show sender names and subjects of the first three messages

## 0.2.1 (Oct 31, 2008)

* Bugfix: Crash when registering defaults.

## 0.2.0 (Oct 30, 2008)

* Added Growl support.
* Play the "Blow" sound when there're new messages.

## 0.1.3 (Oct 29, 2008)

* "Open Inbox" goes to the proper url instead of the normal gmail url if hosted domains account is used.

## 0.1.2 (Oct 4, 2008)

* initial release.
