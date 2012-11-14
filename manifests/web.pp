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
class graylog2::web ($glPort = "80") inherits graylog2 {

  include apache

  package { "rubygems-update":
    ensure    => installed,
    provider  => gem,
  }

  exec { "update-rubygems":
    path    => "/bin:/usr/bin:/usr/local/bin:/var/lib/gems/1.8/bin",
    command => "update_rubygems",
    creates => "/usr/bin/gem1.8",
    require => Package["rubygems-update"],
  }

  package { "ruby-dev":
    ensure  => installed,
    require => Exec["update-rubygems"],
  }

  if !defined(Package["bundler"]) {
    package { "bundler":
      ensure => latest,
      provider => gem,
      require => Package["ruby-dev"],
    }
  }

  if !defined(Package["libapache2-mod-passenger"]) {
    package { "libapache2-mod-passenger": ensure => latest, }
  }

  exec { "${glBasePath}/src/graylog2-web-interface-${glVersion}.tar.gz":
    path        => "/bin:/usr/bin:/usr/local/bin",
    cwd         => "${glBasePath}/src",
    command     => "wget -q https://github.com/downloads/Graylog2/graylog2-web-interface/graylog2-web-interface-${glVersion}.tar.gz -O graylog2-web-interface-${glVersion}.tar.gz" ,
    creates     => "${glBasePath}/src/graylog2-web-interface-${glVersion}.tar.gz",
    require     => File["${glBasePath}/src"],
  }

  exec { "graylog2-web-extract":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "${glBasePath}/src",
    command => "tar -xzf graylog2-web-interface-${glVersion}.tar.gz",
    require => Exec["${glBasePath}/src/graylog2-web-interface-${glVersion}.tar.gz"],
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
    path    => "/bin:/usr/bin:/usr/local/bin:${gem_bin_path}",
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