use v6;

use Test;
plan 22;

use CGI;
ok(1,'We use CGI and we are still alive');

my $cgi = CGI.new();
isa_ok( $cgi, 'CGI', 'Instant it');

# Don't know why I do this
$cgi.init();
isa_ok( $cgi, 'CGI', '...still' );

my @queries = (
    'test=',
      { :test('') } ,
    'test=1',
      { :test<1> },
    'test=2&params=2',
      { :test<2>, :params<2> },
    'test=3&params=3&words=first+second',
      { :test<3>, :params<3>, :words('first second') },
    'test=4&params=3&words=first+%41+second',
      { :test<4>, :params<3>, :words('first A second') },
    'test=5&params=3&words=first%0Asecond',
      { :test<5>, :params<3>, :words("first\nsecond") },
    'test=foo&test=bar',
      { :test<foo bar> },
    'test=2;params=2',
      { :test<2>, :params<2> },
    'test=3;params=3;words=first+second',
      { :test<3>, :params<3>, :words('first second') },
    'test=4;params=3&words=first+%41+second',
      { :test<4>, :params<3>, :words('first A second') },
    );

for @queries -> $in, $expected {
    my %res;
    $cgi.parse_params(%res, $in);
    is_deeply(%res, $expected, 'Parse param: ' ~ $in);
}

my @keywords = (
    'foo',
      ['foo'],
    'foo+bar+her',
      ['foo','bar','her'],
    );

for @keywords -> $in, $expected {
    $cgi.parse_params(my %res, $in);
    is_deeply($cgi.keywords, $expected , 'Parse param (keywords): ' ~ $in);
}

my %start = {};
my @add_params = (
    :key1<val> , { :key1<val> },
    :key2<val> , { :key1<val>,      :key2<val> },
    :key1<val2>, { :key1<val val2>, :key2<val> },
    :key3<4>   , { :key1<val val2>, :key2<val>, :key3<4> },
    :key4<4.1> , { :key1<val val2>, :key2<val>, :key3<4>, :key4<4.1> },

    # Do not consistency :( but we don`t have adverbial syntax to set pairs with undef value
    # see http://www.nntp.perl.org/group/perl.perl6.language/2008/09/msg29610.html
    # Skip now, because is_deeply do not work properl with undef :(
    #key2 => undef , { :key1<val val2>, key2 => ["val", undef], :key3<4>, :key4<4.1> },
);

for @add_params -> $in, $expected {
    my $key = $in.key;
    my $val = $in.value;
    $cgi.add_param( %start, $key, $val);
    is_deeply( %start, $expected, "Add kv: :$key<" ~ ($val or '') ~ ">" );
}

my @cookies = (
    'foo=bar',
      { :foo<bar> },
    'foo=bar; bar=12.20',
      { :foo<bar>, :bar<12.20> },
    );

for @cookies -> $in, $expected {
    $cgi.eat_cookie($in);
    is_deeply($cgi.cookie, $expected, 'Parse cookies: ' ~ $in);
}

# vim:ft=perl6

