# Class: graylog2::web
#
# This module manages graylog2::web
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage: 
#   include graylog2::web
#
# [Remember: No empty lines between comments and class definition]
class graylog2::web inherits graylog2 {

  include apache

  if !defined(Package["bundler"]) {
    package { "bundler": ensure => latest, provider => gem }
  }

  if !defined(Package["libapache2-mod-passenger"]) {
    package { "libapache2-mod-passenger": ensure => latest, }
  }
  
  file { "${glBasePath}/src/graylog2-web-interface-${glVersion}.tar.gz":
    owner   => root,
    group   => root,
    mode    => 644,
    source  => "puppet:///modules/graylog2/graylog2-web-interface-${glVersion}.tar.gz",
  }

  exec { "graylog2-web-extract":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "${glBasePath}/src",
    command => "tar -xzf graylog2-web-interface-${glVersion}.tar.gz",
    require => File["${glBasePath}/src/graylog2-web-interface-${glVersion}.tar.gz"],
    creates => "${glBasePath}/src/graylog2-web-interface-${glVersion}",
  }

  file { "${glBasePath}/src/graylog2-web-interface-${glVersion}":
    ensure  => directory,
    owner   => www-data,
    group   => www-data,
    mode    => 755,
    require => Exec["graylog2-web-extract"],
  }

  file { "${glBasePath}/src/graylog2-web-interface-${glVersion}/log":
    ensure  => directory,
    owner   => www-data,
    group   => www-data,
    mode    => 755,
    require => File["${glBasePath}/src/graylog2-web-interface-${glVersion}"],
  }

  file { "${glBasePath}/src/graylog2-web-interface-${glVersion}/log/production.log":
    owner   => www-data,
    group   => www-data,
    mode    => 666,
    replace => false,
    content => "# graylog2 web interface log",
    require => File["${glBasePath}/src/graylog2-web-interface-${glVersion}/log"],
  }

  file { "${glBasePath}/web":
    ensure  => link,
    target  => "${glBasePath}/src/graylog2-web-interface-${glVersion}",
    require => Exec["graylog2-web-extract"],
  }
  
  exec { "mongoid-downgrade":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "${glBasePath}/web",
    command => "cp Gemfile Gemfile.bak && sed 's/2\.3\.3/2\.2\.5/g' Gemfile.bak > Gemfile",
    require => File[ "${glBasePath}/web" ],
    creates => "${glBasePath}/src/graylog2-web-interface-${glVersion}/Gemfile.bak",
  }

  exec { "graylog2-web-install":
    path    => "/bin:/usr/bin:${gem_bin_path}",
    cwd     => "${glBasePath}/web",
    command => "bundle install && touch bundle-installed",
    require => [Package["bundler"], File["${glBasePath}/web"]],
    creates => "${glBasePath}/web/bundle-installed",
  }

  file { "/etc/apache2/sites-available/graylog2":
    content => template("graylog2/apache2-graylog2.erb"),
    owner   => root,
    group   => root,
    mode    => 644,
  }
  
  file { "/etc/apache2/sites-enabled/graylog2":
    ensure  => link,
    target  => "/etc/apache2/sites-available/graylog2",
    require => Exec["graylog2-web-extract"],
    notify  => Service["apache2"],
  }

}