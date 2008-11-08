use v6;
use Test;
plan 11;

use URI;
ok(1,'We use URI and we are still alive');

my $u = URI.new;
$u.init('http://her.com:80/about/us?foo#bar');

is($u.scheme, 'http', 'scheme'); 
is($u.host, 'her.com', 'host'); 
is($u.port, '80', 'port'); 
is($u.path, '/about/us', 'path'); 
is($u.query, 'foo', 'query'); 
is($u.frag, 'bar', 'frag'); 

is($u.chunks.perl, '["about", "us"]', 'first chunk'); 
is($u.chunks[0], 'about', 'first chunk'); 
is($u.chunks[1], 'us', 'second chunk'); 

is( ~$u, 'http://her.com:80/about/us?foo#bar', 'Sringification');

# vim:ft=perl6
