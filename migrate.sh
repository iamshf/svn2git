#!/bin/sh

# 要转换的SVN地址
SVN_URL="$1"
FOLDER_NAME="$2"



# svn转git
git svn clone $SVN_URL $FOLDER_NAME --no-metadata --trunk=trunk --branches=branches --tags=tags  --authors-file ./users --no-minimize-url eisp-eipsc-parent-to-git

cd $FOLDER_NAME

# 创建本地标签并删除对应的远程分支
git for-each-ref refs/remotes/origin/tags |cut -d / -f 5-|grep -v @| while read tagname; do git tag "$tagname" "origin/tags/$tagname"; done
git for-each-ref refs/remotes/origin/tags |cut -d / -f 5-|grep -v @| while read tagname; do git branch -r -d "origin/tags/$tagname"; done

# 在本地针对每一个远程分支创建对应的本地跟踪分支
git for-each-ref refs/remotes/origin/ |cut -d / -f 4-|grep -v @| while read branchname; do git branch "$branchname" "refs/remotes/origin/$branchname"; done
git for-each-ref refs/remotes/origin/ |cut -d / -f 4-|grep -v @| while read branchname; do git branch -r -D "origin/$branchname"; done

# 删除无用的trunk分支
git branch -d trunk

# 删除与SVN的关联
rm -rf .git/svn

# 删除所有的远程分支
for i in $(git branch -r); do git branch -D -r "$i"; done;

# 删除SVN中被删除的分支
svn ls $SVN_URL/branches | sed 's|/$||' > svn-branch.txt
git branch |sed 's|^\*||' |sed 's|^[[:space:]]*||' | grep -v '^origin/tags/' | sed 's|origin/||' > git-branch.txt
diff -u git-branch.txt svn-branch.txt |grep -v '^--'|grep '^-' |sed 's|-||'|grep -v '^master' > deleted-branch.txt
for i in $(cat deleted-branch.txt); do echo "$i"; git branch -D "$i"; done;

# 删除SVN中被删除的tags
svn ls $SVN_URL/tags | sed 's|/$||' > svn-branch.txt
git tag  > git-branch.txt
diff -u git-branch.txt svn-branch.txt |grep -v '^--'|grep '^-' |sed 's|-||'|grep -v '^master' > deleted-branch.txt
for i in $(cat deleted-branch.txt); do echo "$i"; git tag -d "$i"; done;

