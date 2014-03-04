#! /bin/bash

GITCONF=".git/config"

if grep -q "107.170.232.228" ".git/config"; then
echo "Digital Ocean production repo configured."
else
	echo "[remote \"production\"]
	url = ssh://root@107.170.232.228/home/rails
	fetch = +refs/heads/*:refs/remotes/production/*" >> $GITCONF

	echo "Added DigitalOcean production repo to .git/config"
fi
