#!/bin/bash
source $1
cd /etc && git diff-index --name-only HEAD --
git status -sb | grep 'ahead'
