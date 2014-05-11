use v6;
use Test;
plan 28;

use November::URI;
ok(1,'We use URI and we are still alive');

my $u = November::URI.new(uri => 'http://example.com:80/about/us?foo#bar');

is($u.scheme, 'http', 'scheme'); 
is($u.host, 'example.com', 'host'); 
is($u.port, '80', 'port'); 
is($u.path, '/about/us', 'path'); 
is($u.query, 'foo', 'query'); 
is($u.frag, 'bar', 'frag'); 
is($u.chunks, 'about us', 'chunks'); 
is($u.chunks[0], 'about', 'first chunk'); 
is($u.chunks[1], 'us', 'second chunk'); 

is( ~$u, 'http://example.com:80/about/us?foo#bar',
    'Complete path stringification');

$u = November::URI.new(uri => 'https://eXAMplE.COM');

is($u.scheme, 'https', 'scheme'); 
is($u.host, 'example.com', 'host'); 
is( "$u", 'https://example.com',
    'https://eXAMplE.COM stringifies to https://example.com');

$u = November::URI.new(uri => '/foo/bar/baz');

is($u.chunks, 'foo bar baz', 'chunks from absolute path'); 
ok($u.absolute, 'absolute path'); 
nok($u.relative, 'not relative path'); 

$u = November::URI.new(uri => 'foo/bar/baz');

is($u.chunks, 'foo bar baz', 'chunks from relative path'); 
ok( $u.relative, 'relative path'); 
nok($u.absolute, 'not absolute path'); 

is($u.chunks[0], 'foo', 'first chunk'); 
is($u.chunks[1], 'bar', 'second chunk'); 
is($u.chunks[*-1], 'baz', 'last chunk'); 

$u = November::URI.new(uri => 'http://foo.com');
ok($u.chunks.perl eq 'Array.new("")', ".chunks return [''] for empty path");
ok($u.absolute, 'http://foo.com has an absolute path'); 
nok($u.relative, 'http://foo.com does not have a relative path'); 

# test November::URI parsing with <> or "" and spaces
$u = November::URI.new(uri => "<http://foo.com> ");
is("$u", 'http://foo.com', '<> removed from str');

$u = November::URI.new(uri => ' "http://foo.com"');
is("$u", 'http://foo.com', '"" removed from str');


# vim:ft=perl6
