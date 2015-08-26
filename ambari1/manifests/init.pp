 include base
 # redirect repo request to buildoop VM
 

  node default {
  include local-repo
  include host-manager
  package { "ambari-agent":
    ensure => "installed",
    require => Yumrepo[ "ambari-1.x" ]
  }
  package { "ambari-server":
    ensure => "absent",
    require => Yumrepo[ "ambari-1.x" ]
  }
  file{'/etc/ambari-agent/conf/ambari-agent.ini':
  ensure => file,
  source => 'puppet:///files/ambari-agent.ini',
  require => Package["ambari-agent"]
  }
  service { "ambari-agent":
  ensure => "running",
  require => Package["ambari-agent"],
  subscribe => File["/etc/ambari-agent/conf/ambari-agent.ini"]
  }
  }


  node 'master' {
  include local-repo
  include host-manager
  include keedio
  package { "ambari-server":
    ensure => "installed",
    require => Yumrepo[ "ambari-1.x","Updates-ambari-1.x" ]
  }
  package { "ambari-agent":
    ensure => "installed",
    require => Yumrepo[ "ambari-1.x","Updates-ambari-1.x" ]
  }
  package { "ambari-log4j":
    ensure => "installed",
    require => Yumrepo[ "ambari-1.x" ]
  }
  package { "jdk":
    ensure => "present",
    require => Yumrepo[ "keedio-1.2" ]
  }
  file{'/etc/ambari-server/conf/ambari.properties':
  ensure => file,
  source => 'puppet:///files/ambari.properties',
  require => [Package["ambari-server","ambari-agent","ambari-log4j"],Exec["ambari-setup"]]
  }
  file{'/usr/lib/ambari-server/web/javascripts/app.js.gz':
  ensure => file,
  source => 'puppet:///files/app.js.gz',
  require => Package["ambari-server","ambari-agent","ambari-log4j"]
  }
  file { '/var/lib/ambari-server/resources/stacks/FLUME':
  ensure => 'link',
  target => '/vagrant/files/keedio-stacks/FLUME/',
  require => Package["ambari-server","ambari-agent","ambari-log4j"]
  }
  file { '/var/lib/ambari-server/resources/stacks/KEEDIO':
  ensure => 'link',
  target => '/vagrant/files/keedio-stacks/KEEDIO/',
  require => Package["ambari-server","ambari-agent","ambari-log4j"]
  }
  exec { "ambari-setup":
  command => "ambari-server setup -s",
  cwd     => "/var/tmp",
  creates => "/var/lib/pgsql/data/postgresql.conf",
  path    => ["/usr/bin", "/usr/sbin","/sbin","/bin"],
  require => Package["ambari-server","ambari-agent","ambari-log4j"]
  }
  service { "ambari-server":
  ensure => "running",
  require => [Package["ambari-server"],Exec["ambari-setup"]],
  subscribe => File["/etc/ambari-server/conf/ambari.properties"]
  }
  file{'/etc/ambari-agent/conf/ambari-agent.ini':
  ensure => file,
  source => 'puppet:///files/ambari-agent.ini',
  require => Package["ambari-agent"]
  }
  service { "ambari-agent":
  ensure => "running",
  require => Package["ambari-agent"],
  subscribe => File["/etc/ambari-agent/conf/ambari-agent.ini"]
  }
  }
 
  node buildoop {
  include keedio
  class { 'groovy': 
    }
  package { "fuse-devel": ensure => "installed"}
  package { "fuse-libs": ensure => "installed"}
  package { "fuse": ensure => "installed"}
  package { "cmake": ensure => "installed"}
  package { "lzo-devel": ensure => "installed"}
  package { "openssl-devel": ensure => "installed"}
  package { "createrepo": ensure => "installed"}
  package { "yum-utils": ensure => "installed"}
  package { "httpd": ensure => "installed"}
  package { "git": ensure => "installed"}
  package { "redhat-rpm-config": ensure => "installed"}
  package { "rpm-build": ensure => "installed"}
  package { "glibc-devel.i686": ensure => "installed"}
  package { "elfutils-libelf.i686": ensure => "installed"}
  package { "compat-libstdc++-33.i686": ensure => "installed"}
  package { "gcc-c++": ensure => "installed"}
  package { "jdk": 
             ensure => "installed",
             require => Yumrepo["keedio-1.2"]
          }
  file {"/etc/profile.d/buildoop.sh":
         ensure  => "present",
         content => "export JAVA_HOME=/usr/java/jdk1.7.0_51\nexport PATH=/usr/java/jdk1.7.0_51/bin:\$PATH\nexport MAVEN_OPTS='-Xms512m -Xmx1024m'"
       }
  cron { "createrepo":
         ensure  => present,
         command => "createrepo --simple-md-filenames /vagrant/repo/keedio-1.2/",
         user    => 'root',
         hour    => 14,
         minute  => 0,
         require => Package["createrepo"]
       }
  file_line{'repo_root':
            path =>'/etc/httpd/conf/httpd.conf',
            line =>'DocumentRoot "/var/www/html/repo"',
            match => '^DocumentRoot *',
            require => Package['httpd'] }
  file_line{'repo_root2':
            path =>'/etc/httpd/conf/httpd.conf',
            line => '<Directory "/var/www/html/repo">',
            match => '^\<Directory "/var/www/html"\>', 
            require => Package['httpd']}
  file {'/var/www/html/repo':
         ensure => 'directory',
         require => Package['httpd']}

  service { 'httpd':
      ensure => running,
      enable => true,
      require => [Package["httpd"], File["/var/www/html/repo"]],
      subscribe => File_line["repo_root","repo_root2"]
    } 
  }  

