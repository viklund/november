use v6;

use Test;
use CGI;

my @t =
    '%61'       => 'a',
    '%C3%A5'    => 'å',
    '%C4%AC'    => 'Ĭ',
    '%C7%82'    => 'ǂ',
    '%E2%98%BA' => '☺',
    '%E2%98%BB' => '☻';

plan +@t;

for @t {
    ok( CGI::decode_urlencoded_utf8( .key ) eq .value, 'Decoding ' ~ .key );
}

# vim: ft=perl6
