#!/bin/bash

# Version 2.0.1

# If this isn't a WordPress install, then exit out with an error message.
if ! $(wp core is-installed); then
	echo "This is not a WordPress installation. Exiting."
	exit 2
fi

# Just another WordPress blog (Settings->General->Tagline)
wp option update blogdescription ''

# Turn off registration (Settings->General->Anyone can register)
wp option update users_can_register 0

# Kill emoticons (Settings->Writing->Convert emoticons)
wp option update use_smilies 0

# If you pass any argument then this site isn't a new installation. Usage config.sh --old
if (( $# != 1 ))
then
	# Set up the front page. Home page is for showing latest blog posts
		## Set the front page to a static page (Settings->Reading->Front page displays)
		wp option update show_on_front 'page'
			### The default WordPress page is post ID 2. Set post 2 to the front page (Settings->Reading->Front page displays)
			wp option update page_on_front 2
			### Rename the default page to Front Page. Change its slug to front-page. Set its content to a space.
			wp post update 2 --post_title='Front Page' --post_name='front-page' --post_content=' '
	
	# Set up the home page at /blog. The home page is for showing the latest blog posts, and is not a front page.
		## Create the page, save the output id to a variable
		home_page=$(wp post create --post_type=page --post_status=publish --post_title='Blog' --post_name='blog' --porcelain)
		## Set the posts page to the created page
		wp option update page_for_posts $home_page
	
	# Delete the first post, Hello world!
		## The default WordPress first post is post ID 1. Delete the post with ID 1. Have it bypass the trash (--force)
		wp post delete 1 --force
	
	# Activate common plugins
		## Activate Webspec Design to brand the admin
		wp plugin activate webspec-design-wordpress-core
		wp plugin activate webspec-smtp
		wp plugin activate github-updater
		
fi

# Set blog to public visibility (Settings->Reading->Search Engine Visibility)
wp option update blog_public 1

# Kill all comments
	## Default article settings (Settings->Discussion->Default article settings)
		### Attempt to notify any blogs linked to from the article 
		wp option update default_pingback_flag 0
		### Allow link notifications from other blogs (pingbacks and trackbacks)
		wp option update default_ping_status closed
		### Allow people to post comments on new articles 
		wp option update default_comment_status closed
	## Other comment settings (Settings->Discussion->Other comment settings)
		### Comment author must fill out name and e-mail 
		wp option update require_name_email 1
		### Users must be registered and logged in to comment
		wp option update comment_registration 1
	## Don't email me about comments (Settings->Discussion->E-mail me whenever)
		### Anyone posts a comment 
		wp option update comments_notify 0
		### A comment is held for moderation
		wp option update moderation_notify 0
	## Make it so a user can never comment (Settings->Discussion->Before a comment appears)
		### An administrator must always approve the comment 
		wp option update comment_moderation 1
		### Comment author must have a previously approved comment
		wp option update comment_whitelist 1
		### Add plugins and info to GitHub updater
		wp option update github_updater '{"github_access_token": "", "bitbucket_username": "devs@webspecdesign.com", "bitbucket_password": "g3n3w|lder", "webspec-design-wordpress-core": "1", "all-in-one-seo-populate-keywords": "1", "webspec-smtp": "1"}' --format=json

# Set the permalink structure to Month and Name. (Settings->Permalinks)
# Remember that this is for blog posts (posts with the post type post)
# By changing this from default it enables %post_name% for pages
wp rewrite structure '%year%/%monthnum%/%postname%/'
# rules flushed automatically by wp-cli

#Update timezone#
wp option update timezone_string 'America/Chicago'
#wp option update rg_gforms_key 'a20da950a19d113f35d85f4045c45247'
wp option update acf_pro_license 'b3JkZXJfaWQ9MzQwOTd8dHlwZT1kZXZlbG9wZXJ8ZGF0ZT0yMDE0LTA3LTA5IDE1OjM4OjM3'