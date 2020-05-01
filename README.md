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

## Models

✅ vs ☑️ | Name | Size | Inference<br>Time | Post-process<br>Time | PCKh-0.5 | multi person <br>vs<br> single person | 2D vs 3D | Model Source | Paper
:---: | --- | --- | --- | --- | --- | :---: | :---: | --- | ---
✅ | **PoseNet** | 13.3 MB | - | - | - | single | 2D | [tensorflow/tensorflow](https://github.com/tensorflow/examples/blob/master/lite/examples/posenet/ios) | [PersonLab](https://arxiv.org/abs/1803.08225)
✅ | **PEFM CPM** | 2.4 MB | - | - | - | single | 2D | [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile) | [Convolutional Pose Machines](https://arxiv.org/abs/1602.00134)
✅ | **PEFM Hourglass v1** | 1.8 MB | - | - | - | single | 2D | [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile) | [Stacked Hourglass Networks](https://arxiv.org/abs/1603.06937)
✅ | **PEFM Hourglass v2** | 1.7 MB | - | - | - | single | 2D | [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile) | [Stacked Hourglass Networks](https://arxiv.org/abs/1603.06937)
✅ | **OpenPose** | 7.8 MB | - | - | - | multi | 2D | [ildoonet/tf-pose-estimation](https://github.com/ildoonet/tf-pose-estimation/issues/355) | [OpenPose](https://arxiv.org/abs/1812.08008)
☑️ | **SimplePose** | - | - | - | - | single | 2D | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | [Simple Baselines](https://arxiv.org/abs/1804.06208)
☑️ | **AlphaPose** | - | - | - | - | single | 2D | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | [RMPE](https://arxiv.org/abs/1612.00137)
☑️ | **SelecSLS** | - | - | - | - | single | 2D | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | -
☑️ | **IBPPose** | - | - | - | - | single | 2D | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | -
☑️ | **Lightweight OpenPose** | - | - | - | - | single | 2D | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | [OpenPose](https://arxiv.org/abs/1812.08008)

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

2. Open the `PoseEstimation-TFLiteSwift.xcworkspace` and run the project

## See also

- [motlabs/awesome-ml-demos-with-ios](https://github.com/motlabs/awesome-ml-demos-with-ios)
- TensorFlow Lite models provided by:
  - CPM and Hourglass model provided by  [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile)
  - PoseNet model provided by [tensorflow/examples](https://github.com/tensorflow/examples/blob/master/lite/examples/posenet/ios)
  - OpenPose model provided by [ildoonet/tf-pose-estimation](https://github.com/ildoonet/tf-pose-estimation)
  - Various model provided by [osmr/imgclsmob](https://github.com/osmr/imgclsmob)
- Pose estimation with Core ML - [tucan9389/PoseEstimation-CoreML](https://github.com/tucan9389/PoseEstimation-CoreML)

## License

This repository is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
