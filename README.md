[![Build Status](https://travis-ci.org/JioCloud/puppet-rjil.svg?branch=master)](https://travis-ci.org/JioCloud/puppet-rjil)

puppet-rjil
===========


### Table of Contents

1. [Overview - What is puppet-rjil module?](#overview)
2. [Details - how does it work?](#details)
3. [Orchestration - how cross host dependencies work](#cross-host-dependencies)
4. [Development Workflow](#development-environment)
5. [Running Behind Proxy Server](#running-behind-proxy-server)
6. [Build script - command line tool for generating test deployments](#build-script)
7. [Development - Resources for Developers](#development)

# Overview

This project is the top level project where most of the deployment coding
for jiocloud happens.

At a high level, it contains the following files/directories

* ./manifests/
  composition Puppet manifests for building jiocloud
* hiera/hiera.yaml
  hiera configuration file that should be used for jiocloud
* hiera/data/
  directory where default hiera data should go. Pretty much anything that
  doesn't contain lookups or secrets should be stored here.
* Vagrantfile
  A Vagrantfile that can be used for faster deployments and iterative
  development.
  NOTE: Vagrant has its own hiera env data in `./hiera/data/env/vagrant.yaml`:
* Puppetfile
  List of all puppet modules that need to be installed as dependencies.
* ./build\_scripts/deploy.sh - Script that performs deployment of jiocloud.
* ./files/maybe-upgrade.sh - script that actually runs Puppet to perform
  deployments on provisioned machines (when not using vagrant)
* ./environment/full.yaml - contains the definition of nodes that can be used for testing
* site.pp - puppet content that contains role assignments to node.

# Details

## Building custom deployments

In general, most people be using the predefined full layout for deployments
(which deploys the jiocloud reference architecture for openstack)

This deployment module was built using the following steps:

1. Describe the environment you need to deploy (what roles and how many)

2. Ensure that Puppet configuration exists to support this deployment

3. Ensure the relevant hiera data exists in the hierarchy

4. Use either the build script (deploy.sh) or vagrant to perform an environment build

5. Debug the build process to follow a build's progress


## Puppet

### overview

Puppet is responsible for ensuring that each of the defined hosts in our
layout get assigned their correct role.

For example, for the case of an apache server. Puppet contains the description
of how a machine is transitioned to its desired role.

````
+----------+      +-----------+
|  base    |      | configured|
|  image   +------> apache    |
|          |      | server    |
|          |      |           |
+----------+      +-----------+
````

### assigning roles

The provisioned hosts have their hostname set as:

````
<role><number>_<project_id>
````

A set of matching nodes from *site.pp* might look like:

````
node /^bootstrap\d+/ {

}
node /^apache\d+/ {

}
````

Those nodes definitions should include whatever classes are required to configure those
roles.

### external modules

All services that Puppet configures are configured through modules that are installed as
external dependencies to the puppet-rjil module.

These dependencies are defined in the Puppetfile (which results to modules that are installed
using librarian-puppet-simple)

### puppet-rjil as a module

The Puppet-rjil module contains all of the composition roles that combine the external modules into the roles defined in site.pp.

In Puppet's lexicon, the type of content found in this module are referred to as profiles.

TODO: document more about the kinds of things that belong here and our expectations for how those
things are developed.

### Populating hiera data

All data used to override defaults of Puppet Profiles located in puppet-rjil/modules are passed in
via hiera.

Understanding hiera is a requirement for using this system. Please get started [here](https://docs.puppetlabs.com/hiera/1/).

Hiera uses [Facter](http://puppetlabs.com/facter) to determine how data is set for a given node:

`hiera/hiera.yaml` supplies the override configuration that hiera uses to determine how to set hosts
for a given system. The override levels are as follows:

* clientcert/%{::clientcert} - client specific data
* secrets/%{env} - environment specific secrets. This data is provided from env specific packages
* role/%{jiocloud\_role} - role specific overrides
* cloud\_provider/%{cloud\_provider} - overrides specific to a certain cloud provider.
* env/%{env} - environment specific overrides
* secrets/common - default test secrets that are overridden in prod via packages
* common - default overrides (the majority of the hiera data is stored here)

## Layout (stack) data

The build script is driven by a set of data that describes the machines that
need to be configured.

These build scripts can be found in the environment directory.
The filename should be of the form:

````
./environment/<layout>.yaml
````

NOTE: layout defaults to full (full openstack install) if not specified

where layout/env is an argument passed into the build script/Vagrantfile.

The following file contains our reference architecture for openstack:

````
./environment/full.yaml
````

### file contents

This file should contain the top level key `resources`.

Here resources should be listed. Where the names of these
resource should match a node expression (specified from Puppet
in site.pp).

For example, if the following resources are specified:

````
resources:
  haproxy:
    number: 1
    ...
  httpproxy:
    number: 2
````

### applying layout files

Layout files can be applied using the command:

````
python -m jiocloud.apply_resources apply --mappings=environment/${cloud_provider} environment/${layout}.yaml
````

This command will create only the desired nodes specified in the layout file that do not already exist.

Apply this file  will result in host whose names are prefixed with the following strings:
* hapoxy1
* httpproxy1
* httpproxy2

# Cross host dependencies

This document is intended to capture the orchestration requirements for our current Openstack installation.

There are two main motivations for writing this document:

1. Our overall orchestration workflow is getting very complicated. It makes sense to document it to ensure
that anyone from the team can understand how it works.

2. The workflow is complicated and not as well performing as it could be. This document is intended to
capture those issues along with recommendations for how it can be improved.

## Configuration Orchestration

Configuration orchestration is managed via a combination of registering services in consul
and the following [module](https://github.com/jiocloud/puppet-orchestration_utils).

### Consul

Orchestration is currently managed by [consul](https://consul.io/), a tool that provides
DNS service registration and discovery.

Consul works as follows:

  * The following Puppet Defined resource `rjil::jiocloud::consul::service` is used to define a service in consul.
  * Each service registers its ip address as an A record for the address: `<service_name>.service.consul`
  * Each service registers its hostname: <hostmame>.node.consul as an SRV record for `<service_name>.service.consul`

### Orchestrating with consul

Each service registers itself with consul, along with health checks that ensure that services are not
actually registered until they are functional. These services are available both through the
consul http api as well as via regular DNS tools (like dig)

Puppet uses both DNS as well as the consul API to understand what remote services are available
and uses this information to make decisions about if local configuration should be applied.

1. block until an address is resolvable
2. block until we can retrieve registered A records or SRV records from an address.
3. fail if a DNS address is not available

#### Puppet design

In order to understand the motivation for the design of Puppet + Consul for orchestration, you need to first
understand the difference between compile vs. runtime in Puppet.

1. compile time - Puppet goes through a separate process of compiling the catalog that will be used to apply the
   desired configuration state of each agent. During compile time, the following things occur:

* classes are evaluated
* hiera variables are bound
* conditional logic is evaluated
* functions are run
* variables are assigned to resource attributes

This phase processes Puppet manifests, functions, and hiera. In general, data can only be supplied during the
compile time phase in Puppet. This means that all data must be available during compile to be used during
runtime.

2. run time - during Run time, a graph of resources is applied to the system. Most of the logic that is performed
   during these steps is contained within the actual ruby providers.

#### Puppet orchestration integration tooling

The [orchestration\_utils](https://github.com/JioCloud/puppet-orchestration_utils) repo contains all code used
to orchestrate configuration based on the current state of registered services in consul.

##### functions

Functions can be used at runtime to collect data.

* dns\_resolve - gets A records for an address
* service\_discovery\_consul - pull a host => ip hash for a specified hostname.


##### type/provider

* runtime\_fail - used to trigger a catalog failure which causes the entire subgraph to fail. This is used as a
more performant way to fail and retry when certain data is not ready at compile time.
* dns\_blocker - blocks until a specified address is registered. This blocks not only dependent resources, but
also resources that are not dependencies that just happen to not have run.
* consul\_kv\_fail - fail a catalog subgraph if a certain key has not been set in consul. This is used to
orchestrate arbitrary events besides registered services.
* consul\_kv - used to register arbitrary keys from Puppet as a part of run time (meaning that keys can be
sure to be inserted only after certain configuration has been applied.


#### Orchestration performance

3 kinds of orchestration actions are performed in our Puppet vs. Consul integration. This section will
discussed along with its performance and design implications.

##### Fail catalog on missing data - Since data must be available during compile time, the easiest
Orchestration decision is to simply fail to compile and retry until all external services are ready.
We initially tried this approach, but discontinued for the following reason:
* Performance was terrible. Failing at compile time blocked all resource from being able to run.
* Unable to represent cross host circular dependencies.
* Impossible to decouple package installations. Currently, to ensure the best performance, we install
all packages as a separate call to puppet apply with --tags package to ensure that package installs
never have to be blocked on service level dependencies.

##### Block until data ready - In this case, types/providers retry until DNS records are registered.

PROS:
* Easy to monitor cross host orchestration flow
* Less spurious failures.

CONS:
* Cannot work unless hard coded DNS addresses can be used
* Leads to some resource executions getting delayed.

##### Collect data and compile and fail at runtime if not ready

We are tending towards a combination of function/type/providers. At compile time,
functions are used to query for data which is then forwarded to a type that fails
catalog compile if the expected values are not present.

This failure just results in a sub-graph failure, which means that failures are
not preventing other resources from being executed.

## Openstack Dependencies

This section is intended to document all of the cross host dependencies of our current Openstack architecture,
and emphasize the performance implications of each step.

1. All machines block for the consul (bootstrap) server to come up.

2. Currently, the stmonleader, contrail controller, and haproxy machine can all start applying configuration immediately.

** The contrail node can currently install itself successfully as soon as consul it up. This is only because it doesn't
   actually install the service correctly.

** stmonleader can install itself as soon as consul is ready. It may have to run twice to configure OSD's (which we may do
   in testing, but not in prod)

** haproxy - can install itself, but it does not configure the balance members until the controller nodes are running.


It is worth noting that two of these roles will need to reapply configuration when the rest of the services come online.

* haproxy needs all addresses for all controllers it adds them as pool members
* stmonleader needs to have all it's mons registered as well as an OSD number that matches num replicas.

3. Once stmon.service.consul is registered in consul, stmon, ocdb, and oc can start compiling. These machines have
   not performed any configuration at all at this point. At the same time, stmonleader might be adding it's ods (which
   takes two runs)

4. oc will start compiling, but it blocks until the database is resolvable, once that is resolvable, it continues. At the same
  time stmon's are rerunning Puppet to set up their osd drives.

5. once oc and ocdb are up, haproxy registers pool members.

#### Diagram

The below diagram is intended to keep track of what services are dependent on other services
for configuration.

                  +--------+
                  | consul |
                  +------+-+---------------+--------------+
                         |                 |              |
                         |                 |              |
                         |                 |              |
                         |                 |              |
                 +-------v-----+     +-----v----+   +-----v----+
                 | stmonleader |     | contrail |   |  haproxy |
            +----+-----------+-+     +----------+   +----------+
            |                |
            |                |
            |                |
        +---v---+        +---v--+
        | stmon |        | ocdb |
        +-------+        +----+-+
        |                     |
        |                     |
        |                     |
    +---v---+               +-v--+
    | stmon |               | oc |
    +-------+               +----+-----+
                                       |
                                       |
                                       |
                                       |
                                  +----v----+
                                  | haproxy |
                                  +---------+


### known issues

1. the system still does not properly distinguish between addresses of services that will be running vs.
   addresses of things that will be running.

For example: glance, cannot actually be a functional service until keystone has been been registered as
a service and it's address propagated to the load balancer. However, the load balancer cannot be properly
verified until glance has registered (maybe this is actually not a problem...)

2. We have not yet implemented service watching. Currently, it is possible that all occurrences of a certain
   service are not property configured. This is because Puppet just continues to run until it can validate a
   service as functional. The correct way to resolve this is to ensure that you can watch a service, and ensure
   that Puppet runs to reconfigure things when service addresses change (this would currently apply to zeromq,
   ceph, and haproxy.)

3. Failing on compile time adds significant wall-clock time to tests, especially because multiple nodes have to
   be installed completely in serial.

4. The system doesn't really know when it is done running Puppet. We need to somehow understand what the desired
   cardinality is for a service. Perhaps this should be configured as a validation check (ie: haproxy is only
   validated when it has the same number of members as there should be configured services.)

# Development environment

You can setup a Dev environment on a bare-metal node with enough resources using Vagrant. Once you have the bare-metal
server available, follow these steps.

## Installing vagrant

[Install Virtualbox](http://www.virtualbox.org/manual/ch01.html#intro-installing)

It is possible that you can use LXC for this, but it is not fully validating.

[Install vagrant](https://docs.vagrantup.com/v2/installation/)

This setup has been tested with the 1.6.5 installer from [Vagrant Home Page](https://www.vagrantup.com/downloads.html)
The default version of Vagrant in the Ubuntu 14.04 Repo is 1.4.3 which causes an [issue](https://github.com/mitchellh/vagrant/pull/3349).

## Using vagrant

Vagrant makes it easier to perform iterative development on modules. It allows you to develop on your local laptop and see the effects of those changes on localized VMs in real time. We have designed a vagrant based solution that can be used to create VMs that
very closely resemble the openstack environments that we are deploying.

When spinning up VMs for local development, Vagrant/VBox would need to be run on the physical host that has VT-x  enabled in its BIOS. Currently, this setup cannot be provisioned and tested inside a VM itself (KVM/VBox).

The following initial setup steps are required to use the vagrant environment:

#### 1. Set a local system squid proxy to access the internet from the server

Option 1: You can create an rc file in the puppet-rjil directory. Name it something that doesn't
actually mean something on the system (like vagrant_http_proxy, etc) (e.g., .mayankrc).
Disadvantage: You'll have to source it everytime you login.
Option 2: You can add the lines to your default .bashrc file in your home directory. That is automatically
sourced each time you login.

Write following lines at the bottom of the rc file:

    export http_proxy="http://10.135.121.138:3128"
    export https_proxy="https://10.135.121.138:3128"
    export no_proxy = "localhost, 127.0.0.1"
    export env=vagrant-lxc # used to customize the environment to use

Then do `$ source .bashrc`

In order to use proxy with sudo command, use sudo with -E option, e.g.,

    sudo -E apt-get update

In order to use proxy for apt, e.g., create a file in /etc/apt/apt.conf.d/90_proxy. Write following lines:

    Acquire::http::proxy "http://10.135.121.138:3128";
    Acquire::https::proxy "https://10.135.121.138:3128";

#### 2. clone project:

    git clone git://github.com/jiocloud/puppet-rjil
    cd puppet-rjil

If the git:// protocol doesn't work, use https://

#### 3. setup tokens (this is required for setting up consul)

    source newtokens.sh

You'll see a consul ID. Copy that consul ID and paste onto last line of the rc file (.bashrc).
Note: There may be problems with reusing the same id. You need to be careful that you recreate
the env from scratch every-time, or old machines will join the new cluster. So whenever you create
a dev env, always run newtokens.sh.

    export consul_discovery_token=ca004..7f42f3

#### 4. Install puppet modules (using sudo -E)

NOTE: you will need to run this operation as sudo if you intend to install the gems as system
gems. Otherwise, consider installing ruby via rvm to ensure that you can install gems in the
local users environment.

First, you need to make sure that your Puppet module dependencies are installed.
NOTE: make sure that you install librarian-puppet-simple and *not* librarian-puppet!!!!

    gem install librarian-puppet-simple
    librarian-puppet install # from root level of this repo

#### 5. create rjil directory in modules
This step is required b/c the top level directory (i.e. puppet-rjil is a module itself and
it needs to exist in the modulepath for the vagrant environment.)

    mkdir modules/rjil

#### 6. setup your extra environment variables

The Vagrantfile accepts a few additional environment variables that can be used to
further customize the environment.

### Vagrant operations

Once you have initialized your vagrant environment using the above steps, you are ready
to start using vagrant.

It is highly recommended that if you intend to use this utility that you be familiar
with the basics of [vagrant](https://www.vagrantup.com/).

#### vagrant status

To get a list of support roles that can be booted by vagrant, run:

    vagrant status

This list is populated using the ./environment/full.yaml file by default. It is possible to
customize the roles to be populated by adjusting

#### vagrant up

To boot your desired role in vagrant

    vagrant up <role>

#### vagrant provision

To re-run Puppet provisioning (for interactive development of modules):

    vagrant provision <role>

#### vagrant ssh

To login to VMs:

    vagrant ssh <role_name>

### using vagrant to spin up dev machines:

## Adding new roles to vagrant

1. Ensure that the role exists in site.pp as a node declaration

````
node /^somerole/ {
  include somerole
}
````

2. Ensure the node is defined in Vagrant

Roles in vagrant are populated from layouts. In order to be able to see
a machine in vagrant, you need to add it to environment/layout.yaml
for your custom layout or for the layout you are working on.

Then you need to set the layout env variable.

3. Add relevant hiera data. Vagrant environment specific data should
be added to the following location.

````
./hiera/data/env/<env_name>.yaml
````

# Running Behind Proxy Server

In order to run the system behind proxy server, the following extra configuration is required.

* While running Vagrant or deploy.sh, export http_proxy and https_proxy variables on the
   system where running them. This will make sure those scripts will use system wide proxy
   settings.

example
````
export http_proxy=http://10.135.121.138:3128
export https_proxy=http://10.135.121.138:3128

where the proxy url is http://10.135.121.138:3128.
````

* Set rjil::system::proxies hiera data, preferably in hiera/data/env/<env_name>.yaml as below.
    If this is configured, puppet will configure system wide proxy settings on all systems.

````
rjil::system::proxies:
  "no":
    url: "127.0.0.1,localhost,consul,jiocloud.com"
  "http":
    url: "http://10.135.121.138:3128"
  "https":
    url: "http://10.135.121.138:3128"

where the proxy url is http://10.135.121.138:3128.
````

* Sometimes, the systems will not have access to upstream ntp servers, in which case that setting
 have to be changed to internal ntp server (By default, it take pool.ntp.org).

Configure appropriate ntp server in hiera/data/env/<env_name>.yaml.

example:

````
upstream_ntp_servers:
 - 10.135.121.138
````

# Build script

This project contains the following script that is used to deploy out openstack
environments.

````
build\_scripts/deploy.sh
````
## build script environment variables

The script can be configured using the following environment variables:

## BUILD\_NUMBER (required)

Used to attach a unique identifier to all vms created as a part of a test deployment.
This is useful for distinguishing between separate sets of machines that may be
on the same network.

If you are going to be performing multiple deployments for testing purposes, it is recommended
to use a timestamp to make the build number unique per invocation:

````
export BUILD\_NUMBER=`date +"%d%m%y%H%M%S"`;
````

This build number is appended to all of the hostname prefixes of the provisioned machines.

### env (required)

The environment indicator.

````
export env=dan
````

This is used to determine the file that specifies what machines
should exist for a specific deployment.
It refers to the file environment/cloud.${env}.yaml.

It is also used to pull env specific hiera data from ./hiera/data/env/${env}.yaml

### KEY\_NAME (required)

The name of the keypair that will used assigned to the VM.

````
export KEY\_NAME=openstack\_ssh\_key
````

### env\_file (optional)

File that contains the following environment variables used to configuration access
and authentication against your openstack environment.

This argument is optional provided that you manually provide those environment variables.

````
export env\_file=~/credentials.sh
````

### timeout (optional)

Name of the command that provides the timeout capability. You should only even have to
set this if you are using the script from a Mac (or other Unix system).

````
export timeout\_command=gtimeout
````

### puppet\_modules\_source (optional)

Location of source repository for puppet-rjil. This is required if you want to test against
a branch instead of against the puppet-rjil contents that are packaged. This is very
handy for pre-validating some configuration before running tests.

````
export puppet\_modules\_source\_repo=https://github.com/bodepd/puppet-rjil
````

### puppet\_modules\_source\_branch (optional, only makes sense together with puppet\_modules\_source)

Branch that should be used from the provided puppet-rjil repo.

````
export puppet\_modules\_source\_branch=origin/deploy\_script
````

### python\_jiocloud\_source\_repo (optional)

Allows a user to specify an alternative location
for python jiocloud so that users can test builds
with patches to this repository.

This is intended to make testing changes to
this external python library easier.

### python\_jiocloud\_source\_branch (optional)

Branch that should be used to install python-jiocloud.

### ssh\_user

User to that build process should use to ssh into bootstrap server.

````
ssh\_user=ubuntu
````

### git_protocol (optional)

Protocol to use when fetching puppet modules. Defaults to `git`.

````
export git_protocol=https
````

### dns\_override

Provide a DNS server to use during bootstrapping. This will replace the
contents of /etc/resolv.conf during the bootstrapping process and until
it is changed back to localhost for consul.

### override\_repo

A file location for a tgz file that stores an apt repo that needs to be
added for development or testing of new repo features. This repo will be
downloaded onto all compute instances of your build, and pinned at a
higher precedence than your other package repos (specifically at 999).

The current workflow assumes that this file location is the URL of the
location of an artifact created by jenkins. It is assumed that apt
repos will be created by using the `build_scripts/override_packages.sh`
which builds a set of packages based on the [repoconf](https://github.com/jiocloud/repoconf) repo

By default, builds assume that no override repo is being used.

### slack\_url

Slack url to post consul alerts.

## Example of a full invocation

This is what I used for testing:

````
export BUILD\_NUMBER=test\_`date +"%d%m%y%H%M%S"`;export env=dan;export KEY\_NAME=openstack\_ssh\_key; export env\_file=~/credentials.sh;export timeout\_command=gtimeout; export puppet\_modules\_source\_repo=https://github.com/bodepd/puppet-rjil;export puppet\_modules\_source\_branch=origin/deploy\_script;export ssh\_user=ubuntu;bash -x build\_scripts/deploy.sh
````

## dependencies on mac

The first time this script runs (or when it needs to update the version of jiocloud
install), there are a few deps that need to be manually installed on Mac.

````
brew install python
pip install virtualenv
brew install libffi
brew install libyaml
brew install coreutils
alias timeout=gtimeout
````


It is possible that you will also have to manually update the include path to ensure
that libffi is available:

````
export CFLAGS="-I/usr/local/opt/libffi/lib/libffi-3.0.13/include/"
````

# Development

## Process

In general, the process has been designed to be as unobtrusive and
lenient as possible, and is split into the following:

### github pull requests

````
https://github.com/jiocloud/puppet-rjil/pulls
````

The easiest way to make a contribution is to submit a pull request
via github. It is not a requirement that an issue of task exist for
a pull request to be merged (although it might be helpful for some
situations). Contributions are merged as long as they:

1. Are approved by at least one core team member
2. Pass unit tests
3. Pass integration tests (if they risk regressions to
   any of the systems under integration tests)
4. Contain commit messages that provide enough context for reviewers
   to understand
* * the motivation for the patch
* * the desired outcome of the patch

### github issues

````
https://github.com/jiocloud/puppet-rjil/issues
````

Github issues are used to track issues where there is not a patch immediately
available. This might be because:

1. The issue is not well understood/diagnosed
2. The issue is non-trivial to fix
3. The person opening the issue does not immediately know how to resolve it.

In general, at least a menial attempt to debug an issue should be attempted before opening
an issue. There are standard procesures that anyone can use to attempt to categorize
and provide context around a given failure so that they can open a useful (ie: actionable)
as opposed to a useless issue.

Example of a useless issue:

````
Umm... dude, it doesn't work.
<enter random log spew here, or even worse, logs from jenkins, showing that you put
zero effort into it>
````

Issues like the above will result in a mild scolding followed by a request that you perform
the debugging steps mentioned in this section.

### slack

````
https://rjil.slack.com/messages/deployment-team/
````

We use slack as the communication center for this project. Slack is a great place
to ask a questions, or to collaborate on issues where pairing is desired. Events related
to the development of the cloud platform are also streamed to slack in real time.

### Specifications

````
https://github.com/jiocloud/jiocloud-specs
````

A specification should be created in advance for large features.

Specifications are intended to allow more people to be involved in the
design and consensus for larger feature sets. This becomes more important
as more people get on boarded, especially as those resources intend to assist
in the implementation of larger features sets.

## Basic debugging

1. login to one of the roles with a floating ip assigned (review your specified
   layout to be sure)

2. from there, run the following

````
*jorc get_failures --hosts*
````

This command will list three kinds of failures for each host.
In order to debug each host, you generally need to log into the
host that is in an error state.

NOTE: it is possible to login to each host by the same hostname
returned by *get_failures*. It even autocompletes for you.

### puppet failures

Indicate that the last puppet run did not complete successfully.

````
Node: XXXX, Check: puppet
````

Indicates the last puppet run has failing resources. Review
/var/log/syslog to track down failures.

NOTE: all puppet lines from the logs contain puppet-user

NOTE: some errors from the logs are just cascading failures, you need
to track these down to the root cause

### validation failures

````
Node: XXX, Check: validation
````

Validation checks are run to ensure that each service installed on a machine
is in an active state before calling the failure a success. Validation failures
indicate that while the configuration has been successfully applied, the service
is not actually functional. This may indicate that it is still waiting for external
dependencies or in the case of ceph, that it is still performing bootstrapping
operations.

The output from each validation command can be viewed in /var/log/syslog of the
machine whose validation is failing. It is also easy to run the validation commands
yourself:

````
sudo run-parts --regex=. --verbose --exit-on-error  --report /usr/lib/jiocloud/tests/
````

After seeing that a service is not in a functional state, you should check the logs
for that individual service to see if there are any clues there.
### consul service failures

Lists additional consul checks that are currently in the critical state

To see all consul services in the critical state:

````
curl http://localhost:8500/v1/health/state/critical?pretty=1
````

Each service mentioned here also contains the output from it's failed command.

* logging into the machines
* running jorc get\_failures --hosts
* * tracking down failures to root causes (in either /var/log/syslog or /var/log/cloud-init.log)

/var/log/cloud-init-output.log

## Developing as your own tenant

It is possible to invoke build scripts as your own tenant. In fact, for
development, this is how you should be creating environments.

### Setting up your environment:

There are a few steps that need to be performed before you can use your own tenant for testing.

#### Get Credentials

First of all, you need to get credentials for a user in that tenant. Please ask your
cloud adminstrator for this. Once you get these credentials, you should store them
in a local rc file:

    export OS_AUTH_URL=https://somecloud:5000/v2.0/
    export OS_TENANT_NAME=sometenant
    export OS_PASSWORD=somepassword
    export OS_USERNAME=someuser

These examples assume this file is stored at `/home/dan/cloud.dan.env`

#### Create Openstack objects

Next, you need to create the required objects in your
cloud using those credentials.

* keypair
* security group rules - you may need to add some security groups rules
to your default security group, at a minimum, you will need rules to
allow ssh ingress.

    neutron security-group-rule-create --protocol tcp --port-range-min 22 --port-range-max 22 --direction ingress <default_sec_group_uuid>

* network - You need to create your own tenant specific network to launch VMs into.

    neutron net-create dannet
    neutron subnet-create --dns-nameserver 10.0.0.2 --enable-dhcp --allocation-pool start=10.0.0.2,end=10.0.255.254  dannet 10.0.0.0/16

This network *MUST* be in the 10.0.0.0/16 range or you will have to update the following
network settings in hiera:

    public_address: "%{ipaddress_10_0_0_0_16}"
    public_interface: "%{interface_10_0_0_0_16}"
    private_address: "%{ipaddress_10_0_0_0_16}"
    private_interface: "%{interface_10_0_0_0_16}"

#### Custom mapping file

You will also need to create a custom mapping file since you will need to refer
to your own custom network in this file.

Most of the settings inside of the mappings file can be used, you may want to
use the nova-api to make sure that that uuids specified in this file are visible.

At a minimum, you should be able to copy a mapping file from your cloud provider
and just update the uuid of the network with the one that you created above.

#### Create your httpproxy server

Each enviroment needs to have a local proxy server for 2 reasons:

1. Vms only get access to the outside world if they have a floating ip
assigned, therefore, you need a server on your local subnet to proxy requests
to the outside for machines that don't have fips assigned.

2. Build machines pull down lots of bits from the internet over and over again,
caching those bits in a proxy saves lots of time, and bandwidth!

The following scripts can be used as an example of how to create your proxy server:

    # make sure that no proxy is set b/c this machine will access the internet directly
    unset http_proxy
    unset https_proxy
    unset env_http_proxy
    unset env_https_proxy
    # specify an external dns server
    export dns_override=8.8.8.8
    # get a token
    export consul_discovery_token=$(curl http://consuldiscovery.linux2go.dk/new)
    export BUILD_NUMBER=external
    export env=at
    # be sure to specify the cloud provider name that maps to your mapping file that you created
    export cloud_provider=dan
    # be sure to use the key that you created above
    export KEY_NAME=combo
    # make sure that you specify the file that contains your credentials
    export env_file=/home/dan/cloud.jio.env
    export ssh_user=ubuntu
    # use the external layout, it builds the httpproxy server
    export layout=external
    # the httpproxy server will also be the consul bootstrap server
    export consul_bootstrap_node=httpproxy1
    bash build_scripts/deploy.sh

To simplify the instructions, I am going to assume that the private ip address
of this machine is 10.0.0.2, I would strongly suggest that you ensure that it
gets that ip address.

#### Build your build script for you other layouts

It make sense to create a wrapper script to for your other build environments:

    export env_http_proxy=http://10.0.0.2:3128/
    export env_https_proxy=http://10.0.0.2:3128/
    export consul_discovery_token=$(curl http://consuldiscovery.linux2go.dk/new)
    export BUILD_NUMBER=test`date +"%d%m%y%H%M%S"`
    export env=at
    export cloud_provider=dan
    export KEY_NAME=combo
    export env_file=/home/dan/cloud.dan.env
    bash -x build_scripts/deploy.sh

## supporting devs

we want to better support project devs.

here is what I envision:

  - developers can check out their local code into the puppet-rjil environment
  - set it up as a mount in vagrant (or rely on the fact it will be automounted into /vagrant/)
  - customize the load path for whatever is using it
