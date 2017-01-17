Installation
============

1. Create Dokku droplet on Digital Ocean (Ubuntu 14.04).

2. Navigate to droplet's IP address and set up keys.

3. Set up Travis CI for automatic deployment
	* create a email settings file: `email.toml`
	* create private ssh key file: `mapotron.pem`
	* create tar archive containing both files: `tar cvf secrets.tar email.toml mapotron.pem`
	* encrypt the tar file: `travis encrypt-file secrets.tar`

4. SSH into droplet as root
	* initialize the application: `dokku apps:create mapotron.org`
	* configure persistant storage: `dokku docker-options:add deploy "-v /data:/host/data"`
	* create swap file (this is important for compiling R packages):

```
fallocate -l 1G /swap
chmod 600 /swap
mkswap /swap
swapon /swap
```
