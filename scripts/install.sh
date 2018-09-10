sudo apt update
sudo apt install --yes python3-pip python3-dev
pip3 install --user pipenv
echo "PATH=$HOME/.local/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
sudo apt install nginx git unzip
sudo apt install libpq-dev postgresql postgresql-contrib
mkdir ~/sites
cd ~/sites