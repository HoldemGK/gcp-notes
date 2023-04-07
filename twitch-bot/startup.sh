#!/bin/bash
# ubuntu-2204
sudo apt update
sudo apt install -y python3-pip unzip
wget https://github.com/antimatter15/alpaca.cpp/releases/download/81bd894/alpaca-linux.zip
wget https://huggingface.co/Sosaka/Alpaca-native-4bit-ggml/resolve/main/ggml-alpaca-7b-q4.bin
unzip alpaca-linux.zip