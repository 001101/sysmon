cd /etc && git diff-index --name-only HEAD --
git status -sb | grep 'ahead'
