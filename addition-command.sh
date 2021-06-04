################################################################################################################

# CLIENT SIDE

################################################################################################################

## SSH to Target Host ##

#If the certificate doesn’t expire yet, you can directly SSH through your local machine.
#However, if the certificate already expires, we need to create it again by using following command…

OAUTH_EMAIL="[Email that is registered in OAUTH service]"
step ssh login $OAUTH_EMAIL --provisioner "Google"

#Then, client is able to directly SSH through your local machine again.
#ssh USER@TARGETHOST_ADDRESS

## Inspect Certificate ##

#After we verify ourselves with our OAUTH service, we will be able to inspect our certificate identity by following command…

ssh-add -L | step ssh inspect

```
ssh-add -L = List Identity
step ssh inspect = Make Identity Readable
```

## Remove Certificate ##

ssh-add -D

################################################################################################################

# CA SIDE

################################################################################################################


## INTRODUCTION ##

```
In our overall setup, we need to 3 provisioner services to be set in our CA configuration (See more: https://smallstep.com/docs/step-ca/configuration#oauthoidc-single-sign-on)
    
    1. OAuth/OIDC single sign-on Provisioner 
    To issue certificates to people, step-ca can be configured to use OAuth/OpenID Connect (OIDC) identity tokens for authentication. 
    (It will create Token with ODIC identity which will be passed to CA to issue certificate) You can use single sign-on with...
        
        ID tokens from Okta, G Suite, Azure AD, Auth0.
        or
        ID tokens from an OAuth OIDC service that you host, like Keycloak or Dex

    2. JWK Provisioner 
    for Host Bootstrapping, this allow host able to get certificate from CA

    3. SSHPOP Provisioner
    To allows a client to renew, revoke, or rekey an SSH certificate using that certificate for authentication with the CA.
```

## PROVISIONER ##
# Provisioners are methods of using the CA to get certificates for humans or machines. They offer different modes of authorization for the CA. (See more: https://smallstep.com/docs/step-ca/configuration)

```
For example, you can have your CA issue certificates in exchange for:

    ACME challenge responses from any ACMEv2 client

    OAuth OIDC single sign-on tokens, eg:
        ID tokens from Okta, G Suite, Azure AD, Auth0.
        ID tokens from an OAuth OIDC service that you host, like Keycloak or Dex

    Cloud instance identity documents, for VMs on AWS, GCP, and Azure

    Single-use, short-lived JWK tokens issued by your CD tool — Puppet, Chef, Ansible, Terraform, etc.
```

# Add Provisioner Command 
step ca provisioner add "[Provisioner Service]" 
#documentation and examples on adding provisioners.
step ca provisioner add --help 

# Remove Provisioner Command 
step ca provisioner add "[Provisioner Service]" 
#documentation and examples on removing provisioners.
step ca provisioner remove --help

# Modify Existing Provisioner 
# You can config/edit your provisioner in ca.json file
# Path: $STEPPATH/config/ca.json (STEPPATH: your CA setup path)

################################################################################################################