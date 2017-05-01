#!/bin/bash
source $1
cd /etc && git diff-index --name-only HEAD --
cd /etc && git status -sb | grep 'ahead'
