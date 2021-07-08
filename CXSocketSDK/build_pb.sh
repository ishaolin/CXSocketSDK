#!/bin/bash

# proto文件目录
pd_dir=./Pb
# oc文件目录
oc_dir=./ProtoBuffer

# 删除已存在的oc文件
rm -f $oc_dir/*

# 编译oc文件
protoc -I=$pd_dir --objc_out=$oc_dir $pd_dir/*.proto
