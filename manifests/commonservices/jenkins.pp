#
# base class for jenkins
#
class rjil::commonservices::jenkins {
  $packages = [
    'openjdk-7-jre-headless',
    'sbuild',
    'ubuntu-dev-tools',
    'python-pip',
    'npm',
    'git',
    'python-lxml',
    'python-dev',
    'autoconf',
    'libtool',
    'haveged',
    'apt-cacher-ng',
    'debhelper',
    'pkg-config',
    'bundler',
    'libxml2-utils',
    'build-essential',
    'libffi-dev',
    'python-virtualenv']

  package { $packages: ensure => 'installed' }

  include rjil::commonservices::jenkins::cloudenvs

  ::sudo::conf { 'jenkins_reprepro': content => 'jenkins ALL = (reprepro) NOPASSWD: /usr/bin/reprepro' }
}
