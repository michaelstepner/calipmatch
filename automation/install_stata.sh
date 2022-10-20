#!/bin/bash

# Install Stata
mkdir -p /tmp/statafiles
curl -u oi:${OI_HTTPS_PW} https://d2bx6aas1fcmzl.cloudfront.net/stata16/Stata16Linux64.tar.gz --output /tmp/statafiles/Stata16Linux64.tar.gz
cd /tmp/statafiles
tar -zxf ./Stata16Linux64.tar.gz
sudo mkdir -p /usr/local/stata16
cd /usr/local/stata16

# The following command returns 1 even though it's ok
set +e
sudo sh -c 'yes | /tmp/statafiles/install'
set -e

cd /usr/local/bin
sudo ln -s /usr/local/stata16/stata-mp .
sudo ln -s /usr/local/stata16/xstata-mp .
sudo curl -u oi:${OI_HTTPS_PW} https://d2bx6aas1fcmzl.cloudfront.net/stata16/stata.lic --output /usr/local/stata16/stata.lic
rm -r /tmp/statafiles
cd /tmp
