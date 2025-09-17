git status
git add .
git add Daily-learning-monitor.html - it will add this into staging area
git commit -m 'first version of daily tracker' (it's commited to local contol database computer) still not pushed to remote server
git log
git push (commited local changes to remote server)
qq: you delete local file and how to sink with remote directory?
git difftool HEAD (shows local changes and previous version of the file) (meld as difftool, setup meld for git)
git clone <copy from github>

How to perform the UNDO without commited changes:

git add .
git checkout -- <filename> (undo specific files) - Uncommited changes
git checkout -- . (undo all the files)

how to undo the commited changes

from git log <take the commit i'd> and git revert commit-id
git revert -n <take the commit i'd> - will not commit the changes