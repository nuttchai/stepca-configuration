# Local Host Setup
#
#!/bin/bash

#Obtain your CA fingerprint by running this on your CA:
# step certificate fingerprint $(step path)/certs/root_ca.crt
CA_URL="[CA address (for example, IP address)]"
CA_FINGERPRINT="[CA Fingerprint]"

OAUTH_EMAIL="[Email that is registered in OAUTH service]"

#1. Open your local terminal 

#2. Install step CA in local machine (Tutorial Link: https://smallstep.com/docs/step-ca/installation)

#3. Configure `step` to connect to & trust our `step-ca`
step ca bootstrap --ca-url $CA_URL \
                  --fingerprint $CA_FINGERPRINT

#4. Verify client identity with our OAUTH service (in this case, provisioner is Google)
step ssh login $OAUTH_EMAIL --provisioner "Google"

#5. Configure SSH client locally 
step ssh config

#6. Finally, client can be able to SSH to the host with the account that is registered in target host
#ssh USER@TARGETHOST_ADDRESS