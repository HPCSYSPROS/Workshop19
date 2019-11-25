#!/bin/bash

TAG=`git tag -l v* | tail -1`

echo $TAG
git log --pretty="format:%h %an	%s" $TAG..HEAD | grep -v AUTOMATIC: || echo "No changes"
