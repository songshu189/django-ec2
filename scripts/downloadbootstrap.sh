#!/bin/bash
if [ ! -d static ]; then
  mkdir static
else
  echo "static already exists"
fi
if [ -z "$1" ]; then
	echo "Please input bootstrap version(like 4.2.1):"
    read bootstrap_version
else
	bootstrap_version=$1
fi
wget -O bootstrap.zip https://github.com/twbs/bootstrap/releases/download/v${bootstrap_version}/bootstrap-${bootstrap_version}-dist.zip
unzip bootstrap.zip
mv bootstrap-${bootstrap_version}-dist static/bootstrap-${bootstrap_version}
rm bootstrap.zip