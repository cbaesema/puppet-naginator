#
# This class sets up the Nagios server pieces required for Nagios
# monitoring
#
# In addition, if the Nagios server is monitoring itself, this class
# also includes the definitions for monitors which target the
# Nagios server
#

class naginator {

    package { [ "nagios3", "nagios-nrpe-plugin", "nagios-plugins", ]:
        ensure => installed,
    }

    service { "nagios3":
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Package[ ["nagios3", "nagios-nrpe-plugin", "nagios-plugins",] ],
    }

    #
    # workaround for Debian packaging / Puppet design decision
    # regarding resource management in "non-standard" locations
    file { "/etc/nagios":
        ensure => link,
        target => "/etc/nagios3/conf.d",
    }

    Nagios_host <<| |>> {
        notify => Service["nagios3"],
    }

    Nagios_service <<| |>> {
        notify => Service["nagios3"],
    }

    Nagios_hostextinfo <<| |>>

    file {[ "/etc/nagios3/conf.d/nagios_command.cfg",
            "/etc/nagios3/conf.d/nagios_host.cfg",
            "/etc/nagios3/conf.d/nagios_service.cfg", ]:
        ensure  => file,
        mode    => 0644,
        owner   => root,
        group   => root,
        replace => false,
        notify  => Service["nagios3"],
    }

    file { "/etc/nagios3/htpasswd.users":
        ensure  => file,
        mode    => 0644,
        owner   => root,
        group   => root,
        source  => 'puppet:///modules/naginator/htpasswd.users',
    }

    file { "/etc/nagios3/cgi.cfg":
        ensure => file,
        mode   => 0644,
        owner  => root,
        group  => root,
        source => 'puppet:///modules/naginator/cgi.cfg',
    }

    #
    # nagios server monitors

    @@nagios_host { $fqdn:
        ensure  => present,
        alias   => [ $hostname, "localhost", ],
        address => $ipaddress,
        use     => "generic-host",
        notify  => Service["nagios3"],
    }

    @@nagios_service { "check_ntp_time_${hostname}":
        check_command          => "check_ntp_time!$::company_ntp_server!1!3",
        use                    => "generic-service",
        host_name              => "localhost",
        service_description    => "NTP",
    }

    @@nagios_service { "check_disks_${hostname}":
        check_command       => "check_all_disks",
        use                 => "generic-service",
        host_name           => "localhost",
        service_description => "Disk Space",
    }

}
