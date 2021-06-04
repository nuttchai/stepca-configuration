# CA Setup
#
#!/bin/bash
#
# This script will launch and configure a step-ca SSH Certificate Authority
# with OIDC and AWS provisioners

ROOT_KEY_PASSWORD="[A password for your CA's root key]"

CA_NAME="[A name for your CA]"
PUBLIC_HOSTNAME="[CA Hostname]"
PUBLIC_IP="[CA IP Address]"
EMAIL="[your@email.address]"

# This is for OIDC Provisioner, in this case, we use Google Service that we need to generate a pair of client and secrect client id on Google Service (See full tutorial on part "Create a Google OAuth Credential": https://smallstep.com/blog/diy-single-sign-on-for-ssh/)
OIDC_CLIENT_ID="[Google Client ID]" 
OIDC_CLIENT_SECRET="[Google Client Secret ID]"
ALLOWED_DOMAIN="[The domain name of accounts your users will use to sign to OAuth Service, note that it should be same with organization name that is setup in OAuth Service (for example, cmkl.ac.th)]"     
OPENID_CONFIG_ENDPOINT="https://accounts.google.com/.well-known/openid-configuration" # Google Endpoint

JWK_EMAIL="[your email that will be setup for our JWK provisioner]"

#1. Install Step 

curl -sLO https://github.com/smallstep/certificates/releases/download/v0.15.4/step-certificates_0.15.4_amd64.deb
dpkg -i step-certificates_0.15.4_amd64.deb

curl -sLO https://github.com/smallstep/cli/releases/download/v0.15.2/step-cli_0.15.2_amd64.deb
dpkg -i step-cli_0.15.2_amd64.deb

#2. Provide your root key and push all your CA config and certificates go into $STEPPATH.

export STEPPATH=/etc/step-ca
mkdir -p $STEPPATH
chmod 700 $STEPPATH
echo $ROOT_KEY_PASSWORD > $STEPPATH/password.txt

#3. Add a service to systemd for our CA.
cat<<EOF > /etc/systemd/system/step-ca.service
[Unit]
Description=step-ca service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
Environment=STEPPATH=/etc/step-ca
ExecStart=/usr/bin/step-ca ${STEPPATH}/config/ca.json --password-file=${STEPPATH}/password.txt

[Install]
WantedBy=multi-user.target
EOF

#4. Set up our basic CA configuration and generate root keys
step ca init --ssh --name="$CA_NAME" \
     --dns="$PUBLIC_IP,$PUBLIC_HOSTNAME" \
     --address=":443" --provisioner="$EMAIL" \
     --password-file="$STEPPATH/password.txt"

#5. Add the Google OAuth provisioner, for user certificates
step ca provisioner add Google --type=oidc --ssh \
    --client-id="$OIDC_CLIENT_ID" \
    --client-secret="$OIDC_CLIENT_SECRET" \
    --configuration-endpoint="$OPENID_CONFIG_ENDPOINT" \
    --domain="$ALLOWED_DOMAIN"

#6. Add the JWK provisioner, for host bootstrapping  
step ca provisioner add $JWK_EMAIL --create 
# !!! Note that it will ask for decrypt password key for our JWK provisioner, save it. We will use it later on in target host setup !!! 

#7. Add sshpop provisioner, lets hosts renew their ssh certificates
step ca provisioner add SSHPOP --type=sshpop --ssh

#8. Use Google (OIDC) as the default provisioner in the end user's. 
#   SSH configuration template.
sed -i 's/\%p$/%p --provisioner="Google"/g' /etc/step-ca/templates/ssh/config.tpl

#9. Start the service
service step-ca start

#10. Make sure that path is in the root users profile
echo "export STEPPATH=$STEPPATH" >> /root/.profile