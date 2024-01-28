#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
sudo yum install php -y
echo '<?php phpinfo();?>' > info.php
sudo cp info.php /var/www/html/
sudo systemctl restart httpd