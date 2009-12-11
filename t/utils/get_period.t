use v6;
use Test;
plan 9;

use November::Utils;

{
    my $t = get_period(1227315969, 1227316090);

    is($t[0], 0, 'Return 0 days when period < 24 hour' );
    is($t[1], 0, 'Return 0 hour when period < hour' );
    is($t[2], 2, 'Return 2 min when period 121 sec' );
}

{
    my $t = get_period(1227315969, 1227321470);

    is($t[0], 0, 'Return 0 days when period < 24 hour' );
    is($t[1], 1, 'Return 1 hour when period > 1 hour (5501)' );
    is($t[2], 31, 'Return 3 min when period 5501 sec' );
}

{
    my $t = get_period(1227315969, 1227514689);

    is($t[0], 2, 'Return number of days' );
    is($t[1], 7, 'Return hours' );
    is($t[2], 12, 'Return mins' );
}

# vim:ft=perl6

