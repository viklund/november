use v6;
use Test;
plan 11;

use URI;
ok(1,'We use URI and we are still alive');

my $u = URI.new;
$u.init('http://her.com:80/about/us?foo#bar');

is($u.parts<scheme>, 'http:', 'Parsing: true scheme'); 
is($u.parts<authority>, '//her.com:80', 'Parsing: true authority'); 
is($u.parts<path>, '/about/us', 'Parsing: true path'); 
is($u.parts<query>, '?foo', 'Parsing: true query'); 
is($u.parts<fragment>, '#bar', 'Parsing: true fragment'); 

is($u.scheme, 'http', 'True scheme'); 
is($u.host, 'her.com', 'True host'); 
is($u.port, '80', 'True port'); 
is($u.path, '/about/us', 'True path'); 

is( ~$u, 'http://her.com:80/about/us?foo#bar', 'Sringification');

# vim:ft=perl6
