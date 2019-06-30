# CarthageFileListMaker

`.xcfilelist` file generator for Carthage

## Motivation

We can use `xcfilelist` file for setting input & output files in Xcode script.(https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos) However, you should write `$(SRCROOT)/Carthage/Build/iOS` in every line. It's very annoying 😩, so I created an automation shell script. You can find `CarthageFileListMaker.sh` in `Carthage` Folder.

## Before
1. Edit `input.xcfilelist`
```
$(SRCROOT)/Carthage/Build/iOS/Alamofire.framework
$(SRCROOT)/Carthage/Build/iOS/SnapKit.framework
```

2. Edit `output.xcfilelist`
```
$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Alamofire.framework
$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/SnapKit.framework
```

## Now
1. Edit `FrameworkNames`
```
Alamofire
SnapKit
```

2. Run `CarthageFileListMaker`
```
$ sh CarthageFileListMaker.sh
```

3. Boom 🎉 Here are `xcfilelist`s.
```
$ ls
input.xcfilelist
output.xcfilelist
FrameworkNames
CarthageFileListMaker.sh
```
