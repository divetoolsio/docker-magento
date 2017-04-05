#!/bin/bash
docker run -d -p 8080:80 --name $1 fgx-magento
docker exec -i -t $1 /bin/bash /mangento_install.sh $2 $3
