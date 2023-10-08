#! /bin/bash

# Copyright (c) 2023 PaddlePaddle Authors. All Rights Reserved.
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

log_dir=log_hybrid
rm -rf $log_dir

export FLAGS_embedding_deterministic=1
export FLAGS_cudnn_deterministic=1
export FLAGS_flash_attn_version=v1
export USE_FAST_LN=0

export PYTHONPATH=../../:$PYTHONPATH

mode="dp"
mode="sep"

num_layers=24

if [[ "$mode" == "dp" ]]; then
rm -rf ./dp_log
rm -rf ./dp_input_data
python -m paddle.distributed.launch --log_dir "dp_log" --devices "0" \
    ./tools/train.py \
    -c ./ppfleetx/configs/nlp/gpt/pretrain_gpt_1.3B_sep2.yaml \
    -o Engine.save_load.save_steps=10000 \
    -o Engine.max_steps=0 \
    -o Distributed.dp_degree=1 \
    -o Distributed.mp_degree=1 \
    -o Distributed.sep_degree=1 \
    -o Model.num_layers=$num_layers \
    -o Model.use_recompute=False \

elif [[ "$mode" == "sep" ]]; then
rm -rf ./sep_log
rm -rf ./sep_input_data
python -m paddle.distributed.launch --log_dir "sep_log" --devices "1,2" \
    ./tools/train.py \
    -c ./ppfleetx/configs/nlp/gpt/pretrain_gpt_1.3B_sep2.yaml \
    -o Engine.save_load.save_steps=10000 \
    -o Engine.max_steps=0 \
    -o Distributed.dp_degree=1 \
    -o Distributed.mp_degree=1 \
    -o Distributed.sep_degree=2 \
    -o Model.num_layers=$num_layers \
    -o Model.use_recompute=False \

fi