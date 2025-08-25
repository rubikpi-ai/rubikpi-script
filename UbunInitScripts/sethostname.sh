sudo hostnamectl set-hostname $1
sudo sed -i "s/^127\.0\.1\.1\s\+.*/127.0.1.1 $1/" /etc/hosts
