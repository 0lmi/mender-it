# Mender!t

Let's make some automation around Mender.

# Current state

For now if you want to use AWS to host it, aws cli tool is installed and configured on your system, then it's possible to get Mender production server installed and configured by symply executing:  
```
aws ec2 run-instances \
  --image-id ami-a4dc46db \
  --count 1 \
  --instance-type t2.medium \
  --key-name <your key name> \
  --subnet-id subnet-<id> \
  --security-group-ids sg-<id> \
  --user-data https://raw.githubusercontent.com/0lmi/mender-it/master/server/scripts/mender-server-setup.sh
```
It starts t2.medium instance with Ubuntu 16.04, installs all required packages and does all steps are described in [official documentation](https://docs.mender.io/1.5/administration/production-installation).  
After it finishes all you need to do is modify DNS entries accordigly and you'll get your Mender server up and running with even user created, so, you can just login and start playing with it.  
Of course it has some hardcoded values in the script ^^ and you can't just spesify URL like in the example, you need to download it locally, modify the header and spesify it as '--user-data file:///path/to/file' instead. Instance also is not properly configured, etc... but I'm working on making it awesom ;)  

Cheers!

