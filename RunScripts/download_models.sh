#!/bin/bash
# Copyright 2019 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

# updated by tucan9389 at 21.10.19

# Download TF Lite model from the internet if it does not exist.


while IFS="," read -r TFLITE_FILE MODEL_SRC
do
  if test -f "PoseEstimation-TFLiteSwift/${TFLITE_FILE}"; then
      echo "INFO: TF Lite model already exists. Skip downloading and use the local model."
  else
      curl --create-dirs -o "PoseEstimation-TFLiteSwift/${TFLITE_FILE}" -L --max-redirs 5 "${MODEL_SRC}"
      echo "INFO: Downloaded TensorFlow Lite model to ${TFLITE_FILE}."
  fi
done < <(tail -n +2 'RunScripts/tflite_models.csv')
