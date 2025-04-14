#!/bin/bash

# To use this script, you need to have an includes directory with a "config.env" file 
# containing dbhost, dbuser, dbpass, wpuser and wppass variables.
source ./inc/config.env

clear
echo "============================================"
echo "          WordPress Install Script          "
echo "============================================"
echo
echo -n "Site Name (e.g linuxtweaks) : "
read sitename
siteurl=${sitename}.test
echo
echo -n "Site Title (e.g Linux Tweaks): "
read sitetitle
echo
echo -n "Database Name : "
read dbname
echo
echo -n "Email Address (e.g info@linuxtweaks.in) : "
read wpemail

echo -n "run install? (y/n) : "
read run
if [ "$run" == n ] ; then
echo "Bye."
exit
else
echo
echo "Downloading and extracting tarball wordpress..."
curl -s -O https://wordpress.org/latest.tar.gz 
tar -zxvf latest.tar.gz

# Copy file to parent dir
echo "Copying files to target directory..."
target_dir=~/Sites/wp/${sitename}
mkdir "$target_dir"
cp -rf wordpress/* "$target_dir"
rm -R wordpress
rm -R latest.tar.gz

cd "$target_dir"

# Initialise git repo
echo "Initialising git repo..."
git init

# Download and rename wp.gitignore file
echo "Creating .gitignore file..."
wget https://raw.githubusercontent.com/darrendevouge/wp-notes/refs/heads/main/assets/gitignore/.wp-gitignore
cp .wp-gitignore .gitignore
rm .wp-gitignore

# Create wp config
echo "Generating wp-config.php..."
cp wp-config-sample.php wp-config.php
rm wp-config-sample.php

# Delete unnecessary files
rm license.txt
rm readme.html

# Set database details with perl find and replace
perl -pi -e "s/localhost/$dbhost/g" wp-config.php
perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
perl -pi -e "s/username_here/$dbuser/g" wp-config.php
perl -pi -e "s/password_here/$dbpass/g" wp-config.php

# Set keys and salts 
curl "https://api.wordpress.org/secret-key/1.1/salt/" -o salts

# Split wp-config.php into 3 on the first and last definition statements
csplit wp-config.php '/AUTH_KEY/' '/NONCE_SALT/+1'

# Recombine the first part, the new salts and the last part
cat xx00 salts xx02 > wp-config.php

# Tidy up
rm salts xx00 xx01 xx02

# Set debugging to true
wp config set WP_DEBUG true --raw 

# Set file permission on wp=config.php
chmod 640 wp-config.php

#Create uploads folder and set permissions
echo "creating uploads folder..."
mkdir wp-content/uploads
chmod 755 wp-content/uploads

#Create mu-plugins folder and set permissions
echo "creating mu-plugins folder..."
mkdir wp-content/mu-plugins
chmod 755 wp-content/mu-plugins

echo "Installing Wordpress..."
# Create the empty database
wp db create 

# Add DB tables and install Wordpress 
wp core install --url="$siteurl" --title="$sitename" --admin_user="$wpuser" --admin_password="$wppass" --admin_email="$wpemail" 

echo "Configuring Wordpress..."

# Delete default plugins
wp plugin delete akismet hello 

# Install plugins
wp plugin install advanced-custom-fields wordpress-seo classic-editor debug-bar debug-bar-actions-and-filters-addon

# Activate plugins
wp plugin activate --all 

# Set permalink structure
wp rewrite structure '/%postname%/' 

# Delete default post and page
wp post delete 1 --force  # deletes the "Hello world!" post
wp post delete 2 --force  # deletes the Sample Page

# Remove inactive themes
wp theme delete --all 

echo "Wordpress installed successfully! Happy Coding!"
fi

