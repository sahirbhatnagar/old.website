#!/bin/sh
# push.sh : publish & commit with a single command
git add source
git commit -am "`date`" && git push origin source
rake generate && rake deploy
