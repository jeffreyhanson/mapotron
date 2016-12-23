Installation
============

1. Create Dokku droplet (Ubuntu 14.04).

2. Navigate to IP address and set up keys.

3. Set up Travis CI for automatic deployment.

4. Create swap file. This is important to install packages that need compiling.

```
fallocate -l 1G /swap
chmod 600 /swap
mkswap /swap
swapon /swap
```
