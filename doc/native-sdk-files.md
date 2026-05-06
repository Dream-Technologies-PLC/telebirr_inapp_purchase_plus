# Native SDK Files

Telebirr currently provides local native SDK files. Add them to a local checkout
before Android or iOS device builds.

## Android

Required files:

```text
android/libs/EthiopiaPaySdkModule-uat-release.aar
android/libs/EthiopiaPaySdkModule-prod-release.aar
```

The package Gradle file expects local Maven entries created from those AARs.
Run:

```sh
./scripts/install_telebirr_sdks.sh /path/to/TelebirrSDKFolder
```

The script copies the AAR files and creates:

```text
android/libs-maven/com/telebirr/sdk/ethiopia-pay-sdk-uat/1.0.0/
android/libs-maven/com/telebirr/sdk/ethiopia-pay-sdk-prod/1.0.0/
```

## iOS

Required file:

```text
ios/Frameworks/EthiopiaPaySDK.framework
```

Then run:

```sh
cd example/ios
pod install
```

## GitHub And pub.dev

Do not commit the SDK binaries unless your Telebirr agreement explicitly allows
redistribution. This repository ignores `android/libs/*.aar`,
`android/libs-maven/`, and `ios/Frameworks/` by default.
