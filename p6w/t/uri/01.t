use v6;
use Test;
plan 23;

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
is($u.chunks, 'about us', 'chunks'); 
is($u.chunks[0], 'about', 'first chunk'); 
is($u.chunks[1], 'us', 'second chunk'); 

is( ~$u, 'http://her.com:80/about/us?foo#bar', 'Complite path sringification');

$u.init('https://HeR.COM');

is($u.scheme, 'https', 'scheme'); 
is($u.host, 'her.com', 'host'); 
is( "$u", 'https://her.com', 'https://HeR.COM stringifiaction to https://her.com');

$u.init('/foo/bar/her');

is($u.chunks, 'foo bar her', 'chunks from absolute path'); 
ok($u.absolute, 'absolut path'); 
ok( ! $u.relative, 'not relative path'); 

$u.init('foo/bar/her');

is($u.chunks, 'foo bar her', 'chunks from relative path'); 
ok( $u.relative, 'relative path'); 
ok( ! $u.absolute, 'not absolut path'); 

is($u.chunks[0], 'foo', 'first chunk'); 
is($u.chunks[1], 'bar', 'second chunk'); 
is($u.chunks[-1], 'her', 'last chunk'); 

# vim:ft=perl6
