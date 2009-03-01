use v6;

use Test;
plan 3;

use Config;

my $c = Config.new;

ok($c.skin, 'find skin in Config');
ok(defined $c.web_root, 'find web_root in Config');
ok(defined $c.server_root, 'find server_root in Config');

# vim:ft=perl6
