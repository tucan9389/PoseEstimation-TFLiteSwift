# PoseEstimation-TFLiteSwift

![platform-ios](https://img.shields.io/badge/platform-ios-lightgrey.svg)
![swift-version](https://img.shields.io/badge/swift-5-red.svg)
![lisence](https://img.shields.io/badge/license-MIT-black.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

This project is Pose Estimation on iOS with TensorFlow Lite.<br>If you are interested in iOS + Machine Learning, visit [here](https://github.com/motlabs/iOS-Proejcts-with-ML-Models) you can see various DEMOs.<br>

![pose-demo-002](https://user-images.githubusercontent.com/37643248/77227994-99ba2a80-6bc7-11ea-9b08-9bb57723bc42.gif)

screenshot1 | screenshot2 | screenshot3 | screenshot4
--- | --- | --- | ---
![IMG_7500](https://user-images.githubusercontent.com/37643248/77227851-61feb300-6bc6-11ea-9e76-fd3a43567163.PNG) | ![IMG_7501](https://user-images.githubusercontent.com/37643248/77227847-61661c80-6bc6-11ea-848f-63c22b03cc75.PNG) | ![IMG_7502](https://user-images.githubusercontent.com/37643248/77227842-6034ef80-6bc6-11ea-8f36-5c7e04367559.PNG) | ![IMG_7503](https://user-images.githubusercontent.com/37643248/77227834-57dcb480-6bc6-11ea-83f3-6dffc41e5077.PNG)

## Support Pose Estimation Models

- [x] PoseNet model of [tensorflow/examples](https://github.com/tensorflow/examples/blob/master/lite/examples/posenet/ios)
- [x] cpm and hourglass model of [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile)
- [ ] OpenPose model of [ildoonet/tf-pose-estimation](https://github.com/ildoonet/tf-pose-estimation/issues/355) 
- [ ] Simple Baselines Pose model
- [ ] AlphaPose, SelecSLS, IBPPose, Lightweight OpenPose from [osmr/imgclsmob](https://github.com/osmr/imgclsmob)

## Requirements

- Xcode 11.3+
- iOS 11.0+
- Swift 5
- CocoaPods
```shell
gem install cocoapods
```

## Build & Run

1. Install dependencies with cocoapods
```shell
cd ~/{PROJECT_PATH}
pod install
```

2. Open the .xcworkspace and run the project

## See also

- [motlabs/awesome-ml-demos-with-ios](https://github.com/motlabs/awesome-ml-demos-with-ios)
- [tucan9389/PoseEstimation-CoreML](https://github.com/tucan9389/PoseEstimation-CoreML)
- [PoseNet example of tensorflow/examples](https://github.com/tensorflow/examples/blob/master/lite/examples/posenet/ios)
- [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile)
