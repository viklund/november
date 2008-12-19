use v6;
class Config {
    our $config_file = 'config';
    our $.server_root;
    our $.web_root;
    our $.skin;
}

# RAKUDO: merge with class when we can set attribute values in the declaration
$Config::config_file ~~ :e or die "couldn't open config file";
my %config = eval slurp $Config::config_file;

Config.server_root = %config<server_root>;
Config.web_root    = %config<web_root>;
Config.skin        = %config<skin>;
 
# vim:ft=perl6
  

