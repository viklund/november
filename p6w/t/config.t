use v6;

use Test;
plan 3;

use Config;

ok(Config.skin, 'find skin in Config');
ok(defined Config.web_root, 'find web_root in Config');
ok(defined Config.server_root, 'find server_root in Config');

# vim:ft=perl6
