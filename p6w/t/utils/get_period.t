use v6;
use Test;
plan 2;

use Utils;

my $t = get_period(1227315969, 1227316090);

is($t[0], 0, 'Return 0 hour when period < hour' );
is($t[1], 2, 'Return 2 min when period 121 sec' );

my $t = get_period(1227315969, 1227321470);

is($t[0], 1, 'Return 1 hour when period < 1 hour (5501)' );
is($t[1], 31, 'Return 3 min when period 5501 sec' );


# vim:ft=perl6

