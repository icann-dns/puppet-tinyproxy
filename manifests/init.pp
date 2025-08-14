# @summary Install and configure Tinyproxy, a lightweight HTTP/HTTPS proxy server.
# @param listen The IP address to listen on.
# @param port The port to listen on.
# @param user The user to run the Tinyproxy process as.
# @param group The group to run the Tinyproxy process as.
# @param timeout The timeout for connections.
# @param max_clients The maximum number of clients.
# @param min_spare_servers The minimum number of spare servers.
# @param max_spare_servers The maximum number of spare servers.
# @param start_servers The number of servers to start.
# @param syslog Enable or disable syslog logging.
# @param log_level The level of logging for Tinyproxy.
# @param default_error_file Path to the default error file.
# @param stat_file Path to the statistics file.
# @param pid_file Path to the PID file.
# @param connect_ports Array of ports allowed for CONNECT requests.
# @param allowed Array of IP addresses allowed to use the proxy.
# @param blocked Array of IP addresses denied access to the proxy.
class tinyproxy (
  Stdlib::IP::Address        $listen             = '0.0.0.0',
  Stdlib::Port               $port               = 8888,
  String                     $user               = 'tinyproxy',
  String                     $group              = 'tinyproxy',
  Integer[1]                 $timeout            = 600,
  Integer[1]                 $max_clients        = 100,
  Integer[1]                 $min_spare_servers  = 5,
  Integer[1]                 $max_spare_servers  = 20,
  Integer[1]                 $start_servers      = 10,
  Boolean                    $syslog             = true,
  Tinyproxy::Syslog_level    $log_level          = 'warning',
  Stdlib::Unixpath           $default_error_file = '/usr/share/tinyproxy/default.html',
  Stdlib::Unixpath           $stat_file          = '/usr/share/tinyproxy/stats.html',
  Stdlib::Unixpath           $pid_file           = '/run/tinyproxy/tinyproxy.pid',
  Array[Stdlib::Port]        $connect_ports      = [443],
  Array[Stdlib::IP::Address] $allowed            = [],
  Array[Stdlib::IP::Address] $blocked            = [],

) {
  $config_file = '/etc/tinyproxy/tinyproxy.conf'
  $connect_ports_lines = $connect_ports.map |$port| { "ConnectPort ${port}" }.join("\n")
  $allowed_lines = $allowed.map |$ip| { "Allow ${ip}" }.join("\n")
  $blocked_lines = $blocked.map |$ip| { "Deny ${ip}" }.join("\n")
  $config = @("CONFIG")
    Listen ${listen}
    Port ${port}
    User ${user}
    Group ${group}
    Timeout ${timeout}
    MaxClients ${max_clients}
    MinSpareServers ${min_spare_servers}
    MaxSpareServers ${max_spare_servers}
    StartServers ${start_servers}
    Syslog ${syslog.bool2str('On', 'Off')}
    LogLevel ${log_level.capitalize()},
    DefaultErrorFile ${default_error_file}
    PidFile ${pid_file}
    StatFile ${stat_file}
    ${connect_ports_lines}
    ${allowed_lines}
    ${blocked_lines}
    | CONFIG

  $defaults_config = @("CONFIG"/$)
    CONFIG="${config_file}"
    FLAGS="-c \$CONFIG"
    | CONFIG

  stdlib::ensure_packages(['tinyproxy'])
  # Define the class resources
  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      notify => Service['tinyproxy'];
    $config_file:
      content => $config;
    '/etc/default/tinyproxy':
      content => $defaults_config;
  }

  service { 'tinyproxy':
    ensure => running,
    enable => true,
  }
}
