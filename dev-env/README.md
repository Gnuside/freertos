WhiteBrick Dev environment
==========================

Setup
-----


To test the compilation of the dev environment, you can use a VM or on make
locally on your computer (faster).

### Common needed setup

In both cases, you must do the followings to be able to compile the environment.

#### Fetch git submodules

Once this repository cloned, don't forget to update project submodules with at
git root directory (whitebrick-sources):

    git submodule init
    git submodule update


#### Install basic packages

This section depends obviously of your distribution, but on debian/ubuntu
systems, the following commands will unsure you have the correct packages
installed.
We need :
  - ruby1.9.3-p194
We strongly suggest :
  - rbenv (https://github.com/sstephenson/rbenv)
  - ruby-build : necessary for rbenv to work properly

You can install everything with this command on debian/ubuntu :

    sudo apt-get install ruby1.9.3 ruby-build rbenv

##### Configure rbenv locally
Once installed, you must unsure rbenv to be properly configured by sending those commands :
    sudo echo '# rbenv setup' > /etc/profile.d/rbenv.sh
    sudo echo 'export RBENV_ROOT=$HOME/.rbenv' >> /etc/profile.d/rbenv.sh
    sudo echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
    sudo echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
    sudo chmod +x /etc/profile.d/rbenv.sh
    source /etc/profile.d/rbenv.sh

Then install locally ruby (again) in 1.9.3-p194 :
    rbenv install 1.9.3-p194

This may take a while...


Install the bundler gem system-wide (that will be usefull for many other
ruby projects too) :

    sudo gem install bundler


##### Project dependencies

In src/dev-env, do the following to install ruby packages dependencies:

    bundle install --binstubs --path vendor/bundle

This may take a while too...
(This will install all dependencies in vendor/bundle and related executable
scripts in ./bin)

### Local installation of compilation environment

You simply need to start the script 

### VM installation

This was to test our installation process, but may be usefull for people not
wanting to change their own installation. Compilation is a little slower if
you use the same architecture than your local computer, but could be just
week long if you use a x86 arch on a ARM or ppc architecture (we didn't really
test, but this is the idea)...


