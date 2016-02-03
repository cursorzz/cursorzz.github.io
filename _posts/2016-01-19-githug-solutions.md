---
layout: page
title: "githug solutions"
date: 2016-01-19
summary: |
tags: git
---

## Git Hug solutions (partial)

### Level 8
Notice a few files with the '.a' extension.  We want git to ignore all but the 'lib.a' file.

use ** ! ** any matching file excluded by a previous pattern will become included again

### Level 20
Commit your changes with the future date (e.g. tomorrow).

git commit --date=< YYYY.MM.DD, MM/DD/YYYY and DD.MM.YYYY >

### Level 22
You committed too soon. Now you want to undo the last commit, while keeping the index. 

git reset --soft HEAD^


### Level 25
The remote repositories have a url associated to them.  Please enter the url of remote_location.   

git remote -v

### Level 27
Add a remote repository called `origin` with the url https://github.com/githug/githug

git remote add origin https://github.com/githug/githug

notice .git/config file will reflect this config change
[remote "origin"]
	url = https://github.com/githug/githug
	fetch = +refs/heads/*:refs/remotes/origin/*


### Level 35
You forgot to branch at the previous commit and made a commit on top of it. Create branch test_branch at the commit before the last.

git branch test_branch HEAD^ (based on last commit)


### Level 39
Looks like a new branch was pushed into our remote repository. Get the changes without merging them with the local repository
