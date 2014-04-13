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

if ! which mongo; then
	echo "Need to install Mongodb."
	sudo apt-get install mongodb-server
else
	echo "Mongodb is already installed"
fi

if ! which redis-server; then
	echo "Installing redis server for background processes"
	sudo apt-get install redis-server
else
	echo "Redis-server is already installed"
fi
echo "Checking for new gems"
bundle install
