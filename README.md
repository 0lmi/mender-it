# Mender!t

Let's make some automation around Mender.

# Current state

For now if you want to use AWS to host it, aws cli tool is installed and configured on your system, then it's possible to get Mender demo server installed and configured by symply executing:  
```
aws ec2 run-instances \
  --image-id ami-0ac05733838eabc06 \
  --count 1 \
  --instance-type t3.medium \
  --key-name <your-key-name> \
  --user-data https://raw.githubusercontent.com/0lmi/mender-it/master/server/scripts/mender-demo-server-setup.sh
```
It starts t3.medium instance with Ubuntu 18.04, installs all required packages and does all steps are described in [official documentation](https://docs.mender.io/2.2/getting-started/on-premise-installation/create-a-test-environment).  
After it finishes all you need to do is modify DNS entries accordigly and you'll get your Mender server up and running with even user created, so, you can just login and start playing with it.  
Of course it has some hardcoded values in the script ^^ and you can't just spesify URL like in the example, you need to download it locally, modify the header and spesify it as '--user-data file:///path/to/file' instead. Instance also is not properly configured, etc...  

