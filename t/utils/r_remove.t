use v6;
use Test;
plan 2;

use November::Utils;

my $str = 'ar r \ r';
r_remove($str);
is($str, 'ar r \ r', 'r_remove do nothing with string without \r' );

$str = 'foo\r\nbar\r\n';
r_remove($str);
is($str, 'foo\nbar\n', 'r_remove remove \r' );

# vim:ft=perl6
