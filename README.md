![logo-pose-estimatiton-for-tflite-3](https://user-images.githubusercontent.com/37643248/120911940-18fd2680-c6c6-11eb-972e-9bdd3e975c3b.png)

![platform-ios](https://img.shields.io/badge/platform-ios-lightgrey.svg)
![swift-version](https://img.shields.io/badge/swift-5-red.svg)
![lisence](https://img.shields.io/badge/license-MIT-black.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

This project is Pose Estimation on iOS with TensorFlow Lite.<br>If you are interested in iOS + Machine Learning, visit [here](https://github.com/motlabs/iOS-Proejcts-with-ML-Models) you can see various DEMOs.<br>

|               2D pose estimation in real-time                |                      3D pose estimation                      |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| <img src="https://user-images.githubusercontent.com/37643248/77227994-99ba2a80-6bc7-11ea-9b08-9bb57723bc42.gif" width=240px> | <img src="https://user-images.githubusercontent.com/37643248/110994933-e68ca780-83bc-11eb-8331-d827e19d2d36.gif" width=240px> |


## Features

- [x] Support 2D pose estimaiton TFLite models
    - [x] Real-time demo with Metal framwork
    - [x] Photo album demo
- [x] Support 3D pose estimation TFLite model
    - [x] Real-time demo with Metal framwork (but realtime model is not ready yet)
    - [x] Real-time pose matching demo
    - [x] Photo album demo
- [x] Render the result keypoints of 2D pose estimation in 2D demo page
- [x] Render the result keypoints of 3D pose estimation with SceneKit
- [x] Render the heatmaps of 2D pose estimation output
    - [x] Part Confidence Maps for typical heatmap based models
    - [x] Part Affinity Fields for OpenPose (2D multi-person)
- [x] Implemented pose-matching with cosine similiarity in 3D pose demo
- [x] Implemented to fix the shoulders' keypoints in 3D pose estimation to pre-process for pose-matching


## Models

<details><summary>Source Images</summary>
<p>

Name | gif | img-0 | img-1 | img-2
:---: | :---: | :---: | :---: | :---:
Source | - | <img src="https://user-images.githubusercontent.com/37643248/81012180-15301c80-8e94-11ea-83ec-bd45a690efb3.jpg" width=200px> | <img src="https://user-images.githubusercontent.com/37643248/81010350-1ca1f680-8e91-11ea-81fd-0ff4c78b8641.png" width=200px> | <img src="https://user-images.githubusercontent.com/37643248/81009122-0135ec00-8e8f-11ea-8a3a-e62929f19d8e.png" width=200px>

</p>
</details>


### Joint Samples

Model Names | gif | img-0 | img-1 | img-2
:---: | :---: | :---: | :---: | :---:
PoseNet | - | ![pose-demo-linedot-posenet-0](https://user-images.githubusercontent.com/37643248/81031293-bf289c80-8ec6-11ea-9ec2-6fa4fa07effb.jpeg) | ![pose-demo-linedot-posenet-2](https://user-images.githubusercontent.com/37643248/81031298-c64faa80-8ec6-11ea-8cf6-29eff18ef832.jpeg) | ![pose-demo-linedot-posenet-3](https://user-images.githubusercontent.com/37643248/81031302-c94a9b00-8ec6-11ea-9de8-f91cd97bc48a.jpeg)
PEFM CPM | - | ![pose-demo-PEFMCPM-0](https://user-images.githubusercontent.com/37643248/81031404-21819d00-8ec7-11ea-8a65-4bb2575808c6.jpeg) | ![pose-demo-PEFMCPM-2](https://user-images.githubusercontent.com/37643248/81031420-29414180-8ec7-11ea-8388-260baada3a3d.jpeg) | ![pose-demo-PEFMCPM-3](https://user-images.githubusercontent.com/37643248/81031426-2a726e80-8ec7-11ea-975e-5ad0037650a8.jpeg)
PEFM Hourglass | - | ![pose-demo-PEFMHourglass-0](https://user-images.githubusercontent.com/37643248/81031512-6efe0a00-8ec7-11ea-9e27-b411044cdf39.jpeg) | ![pose-demo-PEFMHourglass-2](https://user-images.githubusercontent.com/37643248/81031522-77564500-8ec7-11ea-8dba-71982428d1ce.jpeg) | ![pose-demo-PEFMHourglass-3](https://user-images.githubusercontent.com/37643248/81031523-78877200-8ec7-11ea-8160-858a6a7fc527.jpeg)
OpenPose (multi-person) | - | ![pose-demo-openpose-0](https://user-images.githubusercontent.com/37643248/81030774-fa29d080-8ec4-11ea-8164-a5e960d09fe4.jpeg) | ![pose-demo-openpose-2](https://user-images.githubusercontent.com/37643248/81030820-28a7ab80-8ec5-11ea-9fcc-283ca97b5748.jpeg) | ![pose-demo-openpose-3](https://user-images.githubusercontent.com/37643248/81030783-ff871b00-8ec4-11ea-94dc-f609bce71536.jpeg)

### Heatmap-ConfidenceMap Samples

Model Names | gif | img-0 | img-1 | img-2
:---: | :---: | :---: | :---: | :---:
PoseNet | - | - | - | - | -
PEFM CPM | - | ![pose-demo-heatmap-PEFMCPM-0](https://user-images.githubusercontent.com/37643248/81032662-aa023c80-8ecb-11ea-8e6d-bbcb8be2a695.jpeg) | ![pose-demo-heatmap-PEFMCPM-2](https://user-images.githubusercontent.com/37643248/81032670-b38ba480-8ecb-11ea-9821-15eeb9af4946.jpeg) | ![pose-demo-heatmap-PEFMCPM-3](https://user-images.githubusercontent.com/37643248/81032672-b5556800-8ecb-11ea-9660-2d0626a6213e.jpeg)
PEFM Hourglass | - | ![pose-demo-heatmap-PEFMHourglass-0](https://user-images.githubusercontent.com/37643248/81032762-fe0d2100-8ecb-11ea-965d-8443e3d3e24e.jpeg) | ![pose-demo-heatmap-PEFMHourglass-2](https://user-images.githubusercontent.com/37643248/81032758-fc435d80-8ecb-11ea-9f18-4ad82374ff63.jpeg) | ![pose-demo-heatmap-PEFMHourglass-3](https://user-images.githubusercontent.com/37643248/81032752-f3eb2280-8ecb-11ea-949a-80a34f6752a3.jpeg)
OpenPose (multi-person) | - | ![pose-demo-heatmap-posenet-0](https://user-images.githubusercontent.com/37643248/81032579-52fc6780-8ecb-11ea-9c6f-2dfa5a7f524e.jpeg) | ![pose-demo-heatmap-posenet-2](https://user-images.githubusercontent.com/37643248/81032601-5f80c000-8ecb-11ea-8f05-f95e8b1e9d28.jpeg) | ![pose-demo-heatmap-posenet-3](https://user-images.githubusercontent.com/37643248/81032603-63144700-8ecb-11ea-9af5-b9b38380a8b8.jpeg)


### Heatmap-PAF Samples

Model Names | gif | img-0 | img-1 | img-2
:---: | :---: | :---: | :---: | :---:
OpenPose (PAF x) | - | ![pose-demo-heatmap-pafx-PEFMHourglass-0](https://user-images.githubusercontent.com/37643248/81033830-fea7b680-8ecf-11ea-991d-37868d902c64.jpeg) | ![pose-demo-heatmap-pafx-PEFMHourglass-2](https://user-images.githubusercontent.com/37643248/81033840-07988800-8ed0-11ea-8c71-8474399e8660.jpeg) | ![pose-demo-heatmap-pafx-PEFMHourglass-3](https://user-images.githubusercontent.com/37643248/81033842-09624b80-8ed0-11ea-9374-3812b5702917.jpeg)
OpenPose (PAF y) | - | ![pose-demo-heatmap-pafy-PEFMHourglass-0](https://user-images.githubusercontent.com/37643248/81033852-12531d00-8ed0-11ea-85b4-c8efa8e61232.jpeg) | ![pose-demo-heatmap-pafy-PEFMHourglass-2](https://user-images.githubusercontent.com/37643248/81033861-17b06780-8ed0-11ea-9806-6b819d3c78ff.jpeg) | ![pose-demo-heatmap-pafy-PEFMHourglass-3](https://user-images.githubusercontent.com/37643248/81033864-1848fe00-8ed0-11ea-8ccc-1adc358a85b3.jpeg) 

### Meta Data

#### 2D

✅ vs ☑️ | Name | Size | Inference<br>Time<br>on iPhone11Pro | Post-process<br>Time<br>on iPhone11Pro | PCKh-0.5 | multi person <br>vs<br> single person | Model Source | Paper | tflite<br>download
:---: | --- | --- | --- | --- | --- | :---: | --- | --- | ---
✅ | **PoseNet** | 13.3 MB | - | - | - | single | [tensorflow/tensorflow](https://github.com/tensorflow/examples/blob/master/lite/examples/posenet/ios) | [PersonLab](https://arxiv.org/abs/1803.08225)
✅ | **PEFM CPM** | 2.4 MB | - | - | - | single | [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile) | [Convolutional Pose Machines](https://arxiv.org/abs/1602.00134)
✅ | **PEFM Hourglass v1** | 1.8 MB | - | - | - | single | [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile) | [Stacked Hourglass Networks](https://arxiv.org/abs/1603.06937)
✅ | **PEFM Hourglass v2** | 1.7 MB | - | - | - | single | [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile) | [Stacked Hourglass Networks](https://arxiv.org/abs/1603.06937)
✅ | **OpenPose** | 7.8 MB | - | - | - | multi | [ildoonet/tf-pose-estimation](https://github.com/ildoonet/tf-pose-estimation/issues/355) | [OpenPose](https://arxiv.org/abs/1812.08008)
☑️ | **AlphaPose** | - | - | - | - | single | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | [RMPE](https://arxiv.org/abs/1612.00137)
☑️ | **SelecSLS** | - | - | - | - | single | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | -
☑️ | **IBPPose** | - | - | - | - | single | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | -
☑️ | **Lightweight OpenPose** | - | - | - | - | single | [osmr/imgclsmob](https://github.com/osmr/imgclsmob) | [OpenPose](https://arxiv.org/abs/1812.08008)

#### 3D 

✅ vs ☑️ | Name | Size | Inference<br>Time<br>on iPhone11Pro | Post-process<br>Time<br>on iPhone11Pro | (metric) | Model Source | Paper | tflite<br>download
:---: | --- | --- | --- | --- | ---  | --- | --- | ---
✅ | **Baseline3DPose** | 137.1 MB | 347 ms | 79 ms | - | [mks0601/3DMPPE_POSENET_RELEASE](https://github.com/mks0601/3DMPPE_POSENET_RELEASE) | [Baseline3D](https://arxiv.org/abs/1907.11346) | [download](https://github.com/tucan9389/PoseEstimation-TFLiteSwift/releases/download/v2.0.0/baseline_moon_noS.tflite)
✅ | **LiteBaseline3DPose** | **16.6 MB** | 116 ms<br>(cpu only) | 19 ms<br>(cpu only) |  | [SangbumChoi/MobileHumanPose](https://github.com/SangbumChoi/MobileHumanPose) | [MHP](https://openaccess.thecvf.com/content/CVPR2021W/MAI/papers/Choi_MobileHumanPose_Toward_Real-Time_3D_Human_Pose_Estimation_in_Mobile_Devices_CVPRW_2021_paper.pdf) | [download](https://github.com/tucan9389/PoseEstimation-TFLiteSwift/releases/download/v2.1.0/lightweight_baseline_choi.tflite)

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
- TensorFlow Lite or Tensorflow models provided by:
  - CPM and Hourglass model provided by  [edvardHua/PoseEstimationForMobile](https://github.com/edvardHua/PoseEstimationForMobile)
  - PoseNet model provided by [tensorflow/examples](https://github.com/tensorflow/examples/blob/master/lite/examples/posenet/ios)
  - OpenPose model provided by [ildoonet/tf-pose-estimation](https://github.com/ildoonet/tf-pose-estimation)
  - Various model provided by [osmr/imgclsmob](https://github.com/osmr/imgclsmob)
  - 3DMPPE PoseNet model provided by [mks0601/3DMPPE_POSENET_RELEASE](https://github.com/mks0601/3DMPPE_POSENET_RELEASE)
- Pose estimation with Core ML - [tucan9389/PoseEstimation-CoreML](https://github.com/tucan9389/PoseEstimation-CoreML)

## License

This repository is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
