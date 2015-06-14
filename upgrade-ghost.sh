# !/bin/bash

for i in "$@"
do
case $i in
    -t=*|--targetghostversion=*)
    GHOSTVERSION="${i#*=}"
    shift # past argument=value
    ;;
    -g=*|--ghostpath=*)
    GHOSTDIR="${i#*=}"
    shift # past argument=value
    ;;
    --include-theme)
    REMOVETHEME=TRUE
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done

if [ -z "$GHOSTVERSION" ] || [ -z "$GHOSTDIR" ] ; then
	echo "Usage: `basename $0` -t=<target_ghost_version> -g=<ghost_path> [--include-theme]"
	exit 1
fi 

echo "Upgarding ghost at '$GHOSTDIR' to verion $GHOSTVERSION"

cd ~
mkdir downloads
cd downloads
rm -r *

echo "downloading ghost version $GHOSTVERSION..."
wget http://ghost.org/zip/ghost-$GHOSTVERSION.zip

if [ $? -ne 0 ]; then
	echo "Error while trying to download latest version of ghost"
	exit 1
fi

echo "Stopping ghost"
forever stopall

if [ $? -ne 0 ]; then
	echo "Error while trying to stop ghost."
	exit 1
fi

cd ~
cd $GHOSTDIR
if [ $? -ne 0 ]; then
	echo "Ghost blog directory path is not valid."
	exit 1
fi

echo "Backing up data in $GHOSTDIR"
git commit -a -m "Backing up before downloading version $GHOSTVERSION"
if [ $? -ne 0 ]; then
	echo "Error while commit changes to ghost git repo."
	exit 1
fi
git push
if [ $? -ne 0 ]; then
	echo "Error while trying to push changes to ghost git backup."
	exit 1
fi

echo "Upgrading ghost..."
echo "Deleting core folder"
rm -r core
if [ $? -ne 0 ]; then
	echo "Error while trying to delete core folder."
	exit 1
fi

if [ -n "$REMOVETHEME" ]; then
	echo "Deleting content/themes folder"
	rm -r content/themes
	
	if [ $? -ne 0 ]; then
		echo "Error while trying to delete content/themes folder."
		exit 1
	fi
fi

echo "Copying new version files"
unzip -uo ~/downloads/ghost-$GHOSTVERSION.zip -d $GHOSTDIR
if [ $? -ne 0 ]; then
	echo "Error while trying to copy new ghost version files."
	exit 1
fi

echo "Installing Ghost..."
npm install --production
if [ $? -ne 0 ]; then
	echo "Error while trying install ghost."
	exit 1
fi

echo "Backing up after installation..."
git add .
git commit -a -m "Backing up after upgrade to version $GHOSTVERSION"
if [ $? -ne 0 ]; then
	echo "Error while commit backup changes to ghost git repo."
	exit 1
fi
git push
if [ $? -ne 0 ]; then
	echo "Error while trying to push backup to to ghost git backup."
	exit 1
fi

echo "Restarting ghost."
cd ~
NODE_ENV=production forever start /var/www/house-of-code-blog/index.js

echo "All done. Check your new ghost version now!"

