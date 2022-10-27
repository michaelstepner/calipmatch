#!/bin/bash

# Define parameters
if [ -z "$STATA_VERSION" ]; then
    STATA_VERSION=17
fi
url_installer=https://d2bx6aas1fcmzl.cloudfront.net/stata_install/Stata${STATA_VERSION}Linux64.tar.gz
url_license=https://d2bx6aas1fcmzl.cloudfront.net/stata_install/stata.lic
download_username=oi
download_password=${OI_HTTPS_PW}

# Install Stata
mkdir -p /tmp/statafiles
curl -u ${download_username}:${download_password} ${url_installer} --output /tmp/statafiles/Stata${STATA_VERSION}Linux64.tar.gz
cd /tmp/statafiles
tar -zxf ./Stata${STATA_VERSION}Linux64.tar.gz
sudo mkdir -p /usr/local/stata${STATA_VERSION}
cd /usr/local/stata${STATA_VERSION}

# The following command returns 1 even though it's ok
set +e
sudo sh -c 'yes | /tmp/statafiles/install'
set -e

cd /usr/local/bin
sudo ln -s /usr/local/stata${STATA_VERSION}/stata-mp .
sudo ln -s /usr/local/stata${STATA_VERSION}/xstata-mp .
sudo curl -u ${download_username}:${download_password} ${url_license} --output /usr/local/stata${STATA_VERSION}/stata.lic
rm -r /tmp/statafiles
cd /tmp
