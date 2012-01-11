# Class: graylog2::server
#
# This module manages graylog2::server
#
# Parameters:
#
# Actions:
#
# Requires: 
#
# Sample Usage:  
#   include graylog2::server
#
# [Remember: No empty lines between comments and class definition]
class graylog2::server inherits graylog2 {

  include mongodb
  include elasticsearch

  file { "${glBasePath}/src/graylog2-server-${glVersion}.tar.gz":
    owner   => root,
    group   => root,
    mode    => 644,
    source  => "puppet:///modules/graylog2/graylog2-server-${glVersion}.tar.gz",
  }

  exec { "graylog2-server-extract":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "${glBasePath}/src",
    command => "tar -xzf graylog2-server-${glVersion}.tar.gz",
    require => File["${glBasePath}/src/graylog2-server-${glVersion}.tar.gz"],
    creates => "${glBasePath}/src/graylog2-server-${glVersion}",
  }

  file { "${glBasePath}/server":
    ensure  => link,
    target  => "${glBasePath}/src/graylog2-server-${glVersion}",
    require => Exec["graylog2-server-extract"],
  }

  file { "/etc/graylog2.conf":
    content => template("graylog2/graylog2.conf.erb"),
    owner   => root,
    group   => root,
    mode    => 644,
    notify  => Service["graylog2-server"],
  }
  
  file { "/etc/init/graylog2-server.conf":
    content => template("graylog2/graylog2-server.conf.erb"),
    owner   => root,
    group   => root,
    mode    => 644,
  }
  
  file { "/etc/cron.d/graylog2-server":
    content => template("graylog2/graylog2-server.cron.erb"),
    owner   => root,
    group   => root,
    mode    => 644,
  }

  service { "graylog2-server":
    ensure    => running,
    hasstatus => false,
    start     => "start graylog2-server",
    stop      => "stop graylog2-server",
    restart   => "restart graylog2-server",
    require   => File["/etc/init/graylog2-server.conf"],
    provider  => "base",
  }

}