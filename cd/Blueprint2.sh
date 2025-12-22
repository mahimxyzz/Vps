export PTERODACTYL_DIRECTORY=/var/www/pterodactyl

sudo apt install -y curl wget unzip


cd $PTERODACTYL_DIRECTORY


DOWNLOAD_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
  | grep browser_download_url \
  | grep '.zip"' \
  | head -n 1 \
  | cut -d '"' -f 4)

wget "$DOWNLOAD_URL" -O release.zip
unzip -o release.zip

sudo apt install -y ca-certificates curl git gnupg unzip wget zip


sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

cd $PTERODACTYL_DIRECTORY
npm i -g yarn
yarn install
touch $PTERODACTYL_DIRECTORY/.blueprintrc
echo \
'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > $PTERODACTYL_DIRECTORY/.blueprintrc

chmod +x $PTERODACTYL_DIRECTORY/blueprint.sh


bash $PTERODACTYL_DIRECTORY/blueprint.sh
