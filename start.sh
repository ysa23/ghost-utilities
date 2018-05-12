NODE_ENV=production forever start -l /var/www/logs/forever.log -o /var/www/logs/out.log -e /var/www/logs/err.log /var/www/house-of-code-blog/index.js

