# Target Host Setup
#
#!/bin/bash
#This will get an SSH host certificate from our CA and add a weekly. It should be run as root.

#Obtain your CA fingerprint by running this command on your CA:
# step certificate fingerprint $(step path)/certs/root_ca.crt
CA_URL="[CA address (for example, IP address)]"
CA_FINGERPRINT="[CA Fingerprint]"

HOSTNAME="[Our Target Hostname]"
JWK_EMAIL="[Email that is set in JWK provisioner, in CA]"

ADD_USER="[Client Username]"

#1. Install Step CLI by following command…

STEPCLI_VERSION="0.15.2"

curl -LO https://github.com/smallstep/cli/releases/download/v${STEPCLI_VERSION}/step-cli_${STEPCLI_VERSION}_amd64.deb
dpkg -i step-cli_${STEPCLI_VERSION}_amd64.deb

#2. Configure `step` to connect to & trust our `step-ca`
step ca bootstrap --ca-url $CA_URL \
                  --fingerprint $CA_FINGERPRINT

#3. Install the CA cert for validating user certificates (from /etc/step-ca/certs/ssh_user_key.pub` on the CA)
step ssh config --roots > $(step path)/certs/ssh_user_key.pub

#4. Helps us avoid a potential race condition
sleep 1

#5. Get an SSH host certificate
export TOKEN=$(step ca token $HOSTNAME --ssh --host --provisioner "$JWK_EMAIL")

#(Note that, after we type the command above, if we have two or more JWK provisioners in our CA configuration, select the right one by observing through its ID in CA host which is located in /etc/step-ca/config/ca.json) 

#After selecting JWK provisioner, it will ask for a decrypt key password which we will get after creating that JWK provisioner in CA host.

#Next, type the following command to complete our SSH host certificate …
sudo step ssh certificate $HOSTNAME /etc/ssh/ssh_host_ecdsa_key.pub --host --sign --provisioner "$JWK_EMAIL" --token $TOKEN 

#6. Configure and restart `sshd`
sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOF
# SSH CA Configuration
# The path to the CA public key for authenticatin user certificates
TrustedUserCAKeys $(step path)/certs/ssh_user_key.pub
# Path to the private key and certificate
HostKey /etc/ssh/ssh_host_ecdsa_key
HostCertificate /etc/ssh/ssh_host_ecdsa_key-cert.pub
EOF

sudo service ssh restart

#7. Add a client user to SSH from their local host 
# Note that the used name must be same with their name in the allowed domain email
# For example, allowed domain: cmkl.ac.th => mail: nuttc@cmkl.ac.th => username must be 'nuttc'
sudo adduser --quiet --disabled-password --gecos '' $ADD_USER