#!/bin/bash

#install wordpress and dependencies
if [ -f composer.sub ]; then
	composer install
else
	composer update
fi
cp wp/index.php index.bak
sed "s|/wp-blog-header.php|/wp/wp-blog-header.php|gI" index.bak > index.php
rm -f index.bak

dbconfirm="n"
while [ "$dbconfirm" != "y" -a "$dbconfirm" != "Y" ]; do

	dbname=""
	while [ "$dbname" = "" ]; do
		echo "Database: "
		read dbname
	done

	dbuser=""
	while [ "$dbuser" = "" ]; do
		echo "Database User: "
		read dbuser
	done

	dbpass=""
	while [ "$dbpass" = "" ]; do
		echo "Database User Password (not empty): "
		read dbpass
	done

	dbhost="192.145.233.22"
	echo "Database Host (defaults to 192.145.233.22): "
	read dbhostnew
	if ! [ -z "$dbhostnew" ]; then
		dbhost="$dbhostnew"
	fi

	dbprefix="wp_"
	echo "Table Prefix (defaults to wp_):"
	read dbprefixnew
	if ! [ -z "$dbprefixnew" ]; then
		dbprefix="$dbprefixnew"
	fi

	echo "Database: $dbname"
	echo "Database User: $dbuser"
	echo "Database Password: $dbpass"
	echo "Database Host: $dbhost"
	echo "Table Prefix: $dbprefix"
	echo "Everything look okay? (y/n)"
	read dbconfirm

done

#create wp-config.php
wp core config --dbname=$dbname --dbuser=$dbuser --dbpass=$dbpass --dbprefix=$dbprefix --dbhost=$dbhost

echo "Site URL (as it appears/would appear in database: http://blah): "
read siteUrl

mv wp/wp-config.php wp-config.bak
sed "/\/\* That's all, stop editing! Happy blogging. \*\//i define\('WP_CONTENT_DIR', dirname\(__FILE__\).'/wp-content'\);" wp-config.bak > wp-config.bak2

sed "/\/\* That's all, stop editing! Happy blogging. \*\//i define\('WP_CONTENT_URL', \'$siteUrl\'.'/wp-content'\);" wp-config.bak2 > wp-config.php

rm -f wp-config.bak
rm -f wp-config.bak2

if ! $(wp core is-installed); then

	#install
	echo "Site Title: "
	read siteTitle
	echo "Admin Username: "
	read siteUser
	echo "Admin Password: "
	read sitePW
	echo "Admin Email: "
	read siteEmail

	wp core install --url="$siteUrl/wp" --title="$siteTitle" --admin_user=$siteUser --admin_password=$sitePW --admin_email=$siteEmail

	homeUrl=$(wp option get home)
	wp option update home ${homeUrl/wp/}

	echo "Site ReplaceMe Substitute (no spaces or dashes!): "
	read replaceme

	#theme
	cd $(wp theme path)
	mv WordpressGulpStarter "$replaceme"
	cd "$replaceme"

	cp style.css style.bak
	sed "s|replaceme|$replaceme|gI" style.bak > style.css
	rm -f style.bak

	cp functions.php functions.bak
	sed "s|replaceme|$replaceme|gI" functions.bak > functions.php
	rm -f functions.bak

	wp theme activate "$replaceme"

	#replaceme
	cd $(wp plugin path)
	mv proprietary-core "$replaceme"-core
	cd "$replaceme"-core
	cp replaceme.php replaceme.bak
	sed "s|replaceme|$replaceme|gI" replaceme.bak > replaceme.php
	rm -f replaceme.bak
	mv replaceme.php "$replaceme".php
	cd ..
	wp plugin activate "$replaceme"-core

	#cd to root
	cd $(wp theme path)/../..

	#gitignore
	cp .gitignore .gitignore.bak
	sed "s|replaceme|$replaceme|gI" .gitignore.bak > .gitignore
	rm -f .gitignore.bak

	#run webspec config
	sh config.sh
	rm -f config.sh

fi

echo "<?php
// Silence is golden." > wp-content/index.php

echo "<?php
// Silence is golden." > wp-content/plugins/index.php

echo "<?php
// Silence is golden." > wp-content/themes/index.php

dbfr="n"
echo "Run search/replace? (y/n)"
read dbfr
if [ "$dbfr" = "y" -o "$dbfr" = "Y" ]; then
	srconfirm="n"
	while [ "$srconfirm" != "y" -a "$srconfirm" != "Y" -a "$srconfirm" != "q" -a "$srconfirm" != "Q" ]; do
		echo "Old URL: "
		read urlold
		echo "Old URL: $urlold"
		echo "New URL: $siteUrl"
		echo "Run search/replace? (y/n or q to quit search/replace)"
		read srconfirm
	done
	if [ "$srconfirm" = "y" -o "$srconfirm" = "Y" ]; then
		wp search-replace "$urlold" "$siteUrl"
	fi
fi

cd $(wp theme path)/$(wp theme list --status=active --field=name)

npm install
bower install --allow-root
gulp build

#cd to root
cd $(wp theme path)/../..

#remove all subdirectory git folders
find ./* -name ".git" | xargs rm -rf

#if this is the first time this is being run
if [ -f composer.sub ]; then
	#remove cwd git
	rm -rf .git
	#init new git
	git init
	#change composers
	rm composer.json
	mv composer.sub composer.json

	composer update
fi

#remove old wp-content
rm -rf wp/wp-content

echo "I finished, in all likelihood, successfully!"
