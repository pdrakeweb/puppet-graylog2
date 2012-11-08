# Class: graylog2
#
# This module manages graylog2
#
# Parameters: 
#   glVersion - the version of graylog2 being installed (eg. 0.9.6)
#   glBasePath - the location to which graylog2 is being installed (eg. /var/graylog2)
#
# Actions:
#
# Requires: 
#   java
#
# Sample Usage:  
#   include graylog2 // note this is useless without including graylog2::server and/or graylog2::web
#
# [Remember: No empty lines between comments and class definition]
class graylog2 ( $glVersion = "0.9.6p1", $glBasePath = "/var/graylog2") {

  include java
  include mongodb
  include elasticsearch

  file { "${glBasePath}":
    ensure => "directory",
    owner  => "root",
    group  => "root",
    mode   => 755,
  }

  file { "${glBasePath}/src":
    ensure => "directory",
    owner  => "root",
    group  => "root",
    mode   => 755,
  }

}
