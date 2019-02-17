#!/bin/sh
clear
printf "This script has to run in sudo mode.\nIf this isn't the case CTRL+C now.\nAlso please don't install this in /root/ but whatever I installed it but I don't really care anyway.\nThis is also meant to be used on a fresh Ubuntu 16.04 install but you can use other OS anyway because this creates a new database etc.\nThis installer is simplistic as its just something I put together so I could easily recreate the server once things change or when I move server around for testing etc.\n\t- Aoba\n"

valid_domain=0

printf "\nInstall directory "[$(pwd)"/ripple"]": "
read MasterDir
MasterDir=${MasterDir:=$(pwd)"/ripple"}

printf "\n\n..:: NGINX CONFIGS ::.."
while [ $valid_domain -eq 0 ]
do
printf "\nMain domain name: "
read domain

if [ "$domain" = "" ]; then
	printf "\n\nYou need to specify the main domain. Example: cookiezi.pw"
else
	printf "\n\nFrontend: $domain"
	printf "\nBancho: c.$domain"
	printf "\nAvatar: a.$domain"
	printf "\nBackend: old.$domain"
	printf "\n\nIs this configuration correct? [y/n]: "
	read q
	if [ "$q" = "y" ]; then
		valid_domain=1
	fi
fi
done

printf "\n\n..:: BANCHO SERVER ::.."
printf "\ncikey [changeme]: "
read peppy_cikey
peppy_cikey=${peppy_cikey:=changeme}

printf "\n\n..:: LETS SERVER::.."
printf "\nosuapi-apikey [YOUR_OSU_API_KEY_HERE]: "
read lets_osuapikey
lets_osuapikey=${lets_osuapikey:=YOUR_OSU_API_KEY_HERE}

printf "\n\n..:: FRONTEND ::.."
printf "\nPort [6969]: "
read hanayo_port
hanayo_port=${hanayo_port:=6969}
printf "\nAPI Secret [Potato]: "
read hanayo_apisecret
hanayo_apisecret=${hanayo_apisecret:=Potato}

printf "\n\n..:: DATABASE ::.."
printf "\nUsername [root]: "
read mysql_usr
mysql_usr=${mysql_usr:=root}
printf "\nPassword [meme]: "
read mysql_psw
mysql_psw=${mysql_psw:=meme}

printf "\n\nAlright! Let's see what I can do here...\n\n"

# Configuration is done.
# Start installing/downloading/setup

START=$(date +%s)

echo "Installing dependencies..."
sudo apt-get install build-essential autoconf libtool pkg-config python-opengl python-imaging python-pyrex python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 python-dev -y	 
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update
apt-get install python3.6 python3.6-dev -y
add-apt-repository ppa:ondrej/php -y
add-apt-repository ppa:longsleep/golang-backports -y
apt-get update
apt install git curl python3-pip -y
apt-get install python-dev libmysqlclient-dev nginx software-properties-common libssl-dev mysql-server -y
pip3 install --upgrade pip
pip3 install flask

# i fucked up these php remove this if you want to.

apt-get install php5.6 php5.6-mbstring php5.6-mcrypt php5.6-fpm php5.6-curl php5.6-mysql golang-go -y
apt-get install php7.0 php7.0-mbstring php7.0-mcrypt php7.0-fpm php7.0-curl php7.0-mysql -y
apt-get install php7.2 php7.2-mbstring php7.2-mcrypt php7.2-fpm php7.2-curl php7.2-mysql -y

# edit code to remove garbage shit
# composer install for old-frontend
apt-get install composer -y
apt-get install zip unzip php5.6-zip php7.0-zip php7.2-zip -y

echo "Done installing dependencies!"
mkdir ripple
cd ripple

echo "Downloading Bancho server..."
git clone https://zxq.co/ripple/pep.py
cd pep.py
git submodule init && git submodule update
python3.6 -m pip install -r requirements.txt
python3.6 setup.py build_ext --inplace
python3.6 pep.py
sed -i 's#root#'$mysql_usr'#g; s#changeme#'$peppy_cikey'#g' config.ini
sed -E -i -e 'H;1h;$!d;x' config.ini -e 's#password = #password = '$mysql_psw'#'
cd $MasterDir
echo "Bancho Server setup is done!"

# UNUSED CODE BECAUSE ITS TOO OLD LOL
#echo "Setting up oppai..."
#git clone https://github.com/Francesco149/oppai.git
#cd oppai/pyoppai
#python3.5 setup.py install
#cd $MasterDir
#echo "oppai: Done!"

echo "Setting up LETS server & oppai..."
git clone https://zxq.co/ripple/lets
cd lets
git submodule init && git submodule update
python3.6 -m pip install -r requirements.txt
python3.6 setup.py build_ext --inplace
echo "Downloading patch from osu!thailand (Ainu)"
cd pp
rm -rf oppai-ng/
git clone https://github.com/Francesco149/oppai-ng
cd oppai-ng
./build
cd ..
rm -rf catch_the_pp/
git clone https://github.com/osuripple/catch-the-pp
mv catch-the-pp/ catch_the_pp/
rm -rf __init__.py
wget -O __init__.py https://pastebin.com/raw/gKaPU6C6
wget -O wifipiano2.py https://pastebin.com/raw/ZraV7iU9
cd ..
cp -R $MasterDir/pep.py/common $MasterDir/lets/common
python3.6 setup.py build_ext --inplace
cd $MasterDir
cd lets
git clone https://github.com/osufx/secret
cd secret
git submodule init && git submodule update
cd ..
python3.6 lets.py
sed -i 's#root#'$mysql_usr'#g; s#changeme#'$peppy_cikey'#g; s#YOUR_OSU_API_KEY_HERE#'$lets_osuapikey'#g' config.ini
sed -E -i -e 'H;1h;$!d;x' config.ini -e 's#password = #password = '$mysql_psw'#'
#TODO: oppai-ng
#mkdir .data
#cd .data
#mkdir oppai
#cd oppai
#git init
#git remote add origin https://github.com/osuripple/oppai.git
#git pull origin master
#make
#chmod +x oppai
#mkdir maps
cd $MasterDir
echo "LETS Server setup is done!"

echo "Installing Redis..."
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
rm redis-stable.tar.gz
cd redis-stable
make
make test
cd $MasterDir
echo "redis: Done!"

echo "Downloading nginx config..."
mkdir nginx
cd nginx
systemctl restart php5.6-fpm
systemctl restart php7.0-fpm
systemctl restart php7.2-fpm
pkill -f nginx
cd /etc/nginx/
rm -rf nginx.conf
wget -O nginx.conf https://pastebin.com/raw/9aduuq4e 
sed -i 's#include /root/ripple/nginx/*.conf\*#include '$MasterDir'/nginx/*.conf#' /etc/nginx/nginx.conf
cd $MasterDir
cd nginx
wget -O nginx.conf https://pastebin.com/raw/a3p3G5cZ
sed -i 's#DOMAIN#'$domain'#g; s#DIRECTORY#'$MasterDir'/nginx#g; s#6969#'$hanayo_port'#g' nginx.conf
wget -O old-frontend.conf https://pastebin.com/raw/KBL6qrLd
sed -i 's#DOMAIN#'$domain'#g; s#DIRECTORY#'$MasterDir'/nginx#g; s#6969#'$hanayo_port'#g' old-frontend.conf
echo "Downloading certificate..."
wget -O cert.pem https://raw.githubusercontent.com/osuthailand/ainu-certificate/master/cert.pem
wget -O key.pem https://raw.githubusercontent.com/osuthailand/ainu-certificate/master/key.key
echo "Certificate downloaded!"
nginx
cd $MasterDir
echo "NGINX server setup is done!"

echo "Setting up mysql..."
#echo "America/Chicago" > /etc/timezone
#dpkg-reconfigure -f noninteractive tzdata
#ufw enable
#ufw allow 3306
#echo "mysql-server-5.6 mysql-server/root_password password root" | debconf-set-selections
#echo "mysql-server-5.6 mysql-server/root_password_again password root" | debconf-set-selections
#mysql_secure_installation
#sed -i 's#127\.0\.0\.1#0\.0\.0\.0#g' /etc/mysql/my.cnf
#mysql -uroot -p -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'
#service mysql restart
# Download custom php file for installation (I could also just run a bunch of sql commands etc in shell but its easier this way)
wget -O ripple_db.php https://pastebin.com/raw/U8nVSe9m
sed -i 's#DB_USR#'$mysql_usr'#g; s#DB_PSW#'$mysql_psw'#g' ripple_db.php
mysql -u "$mysql_usr" -p"$mysql_psw" -e 'CREATE DATABASE ripple;'
php ripple_db.php
echo "mysql: Done!"

echo "Deleting go folder for some reason..."
rm -rf /root/go

echo "Setting up hanayo..."
mkdir hanayo
cd hanayo
go get -u zxq.co/ripple/hanayo
mv /root/go/bin/hanayo ./
mv /root/go/src/zxq.co/ripple/hanayo/data ./data
mv /root/go/src/zxq.co/ripple/hanayo/scripts ./scripts
mv /root/go/src/zxq.co/ripple/hanayo/sematic ./sematic
mv /root/go/src/zxq.co/ripple/hanayo/static ./static
mv /root/go/src/zxq.co/ripple/hanayo/templates ./templates
mv /root/go/src/zxq.co/ripple/hanayo/website-docs ./website-docs
sed -i 's#ripple.moe#'$domain'#' templates/navbar.html
./hanayo
sed -i 's#ListenTo=#ListenTo=127.0.0.1:'$hanayo_port'#g; s#AvatarURL=#AvatarURL=https://a.'$domain'#g; s#BaseURL=#BaseURL=https://'$domain'#g; s#APISecret=#APISecret='$hanayo_apisecret'#g; s#BanchoAPI=#BanchoAPI=https://c.'$domain'#g; s#MainRippleFolder=#MainRippleFolder='$MasterDir'#g; s#AvatarFolder=#AvatarFolder='$MasterDir'/nginx/avatar-server/avatars#g; s#RedisEnable=false#RedisEnable=true#g' hanayo.conf
sed -E -i -e 'H;1h;$!d;x' hanayo.conf -e 's#DSN=#DSN='$mysql_usr':'$mysql_psw'@/ripple#'
sed -E -i -e 'H;1h;$!d;x' hanayo.conf -e 's#API=#API=http://localhost:40001/api/v1/#'
cd $MasterDir
echo "Hanayo setup is done!"

echo "Setting up API..."
mkdir rippleapi
cd rippleapi
go get -u zxq.co/ripple/rippleapi
#Ugly fix?
rm -rf /root/go/src/zxq.co/ripple
mv /root/go/src/zxq.co/rippleapi /root/go/src/zxq.co/ripple
go build zxq.co/ripple/rippleapi
mv /root/go/bin/rippleapi ./
./rippleapi
sed -i 's#root@#'$mysql_usr':'$mysql_psw'@#g; s#Potato#'$hanayo_apisecret'#g; s#OsuAPIKey=#OsuAPIKey='$peppy_cikey'#g' api.conf
cd $MasterDir
echo "API setup is done!"

echo "Setting up avatar server..."
go get -u zxq.co/Sunpy/avatar-server-go
mkdir avatar-server
mkdir avatar-server/avatars
mv /root/go/bin/avatar-server-go ./avatar-server/avatar-server
cd $MasterDir
echo "Avatar Server setup is done!"

echo "Setting up backend..."
cd /var/www/
git clone https://zxq.co/ripple/old-frontend.git
mv old-frontend osu.ppy.sh
cd osu.ppy.sh
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
cd inc
cp config.sample.php config.php
sed -i 's#root#'$mysql_usr'#g; s#meme#'$mysql_psw'#g; s#allora#ripple#g; s#ripple.moe#'$domain'#g' config.php
cd ..
composer install
rm -rf secret
git clone https://github.com/osufx/secret.git
cd $MasterDir
echo "Backend server is done!"

echo "Setting up PhpMyAdmin..."
apt-get install phpmyadmin -y
cd /var/www/osu.ppy.sh
ln -s /usr/share/phpmyadmin phpmyadmin
echo "PhpMyAdmin setup is done!"

echo "Making up certificate for SSL"
cd /root/
git clone https://github.com/Neilpang/acme.sh
apt-get install socat -y
cd acme.sh/
./acme.sh --install
./acme.sh --issue --standalone -d $domain -d c.$domain -d i.$domain -d a.$domain -d old.$domain -d c1.$domain -d c2.$domain -d c3.$domain -d c4.$domain -d c5.$domain -d c6.$domain -d c7.$domain -d c8.$domain -d c9.$domain -d ce.$domain -d s.$domain
echo "Certificate is ready!"

echo "Changing folder and files permissions"
chmod -R 777 ../ripple

END=$(date +%s)
DIFF=$(( $END - $START ))

nginx
echo "Setup is done... but I guess it's still indevelopment I need to check something but It took $DIFF seconds. To setup the server!"
echo "also you can access PhpMyAdmin here... http://old.$domain/phpmyadmin"

printf "\n\nShould you like to download the tmux autorun? [y/n]: "
read q
if [ "$q" = "y" ]; then
	apt-get install tmux -y
	echo '#!/bin/sh' > tmux-start.sh
	echo "tmux new-session -d -s redis 'tmux set remain-on-exit on && cd redis-stable/src && ./redis-server ../redis.conf'" >> tmux-start.sh
	echo "tmux new-session -d -s avatar-server 'tmux set remain-on-exit on && cd avatar-server && ./avatar-server'" >> tmux-start.sh
	echo "tmux new-session -d -s lets 'tmux set remain-on-exit on && cd lets && python3.6 lets.py'" >> tmux-start.sh
	echo "tmux new-session -d -s bancho 'tmux set remain-on-exit on && cd pep.py && python3.6 pep.py'" >> tmux-start.sh
	echo "tmux new-session -d -s rippleapi 'tmux set remain-on-exit on && cd rippleapi && ./rippleapi'" >> tmux-start.sh
	echo "tmux new-session -d -s hanayo 'tmux set remain-on-exit on && cd hanayo && ./hanayo'" >> tmux-start.sh
	echo "echo TMUX window has been created. If they die restart them by calling ':respawn-window'" >> tmux-start.sh
	chmod 777 tmux-start.sh
	printf "\n\nAlright! You can start the server by running ./tmux-start.sh\n\nSee you later in the next server.\n\n"
fi
