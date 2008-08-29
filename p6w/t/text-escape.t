use v6;
use Test;

plan 10;

use Text::Escape;

for <none html uri> -> $e {
    is escape('',  $e), '',  "Can escape empty string with $e";
    is escape('0', $e), '0', "Can escape false string with $e";

}

my $s = '<>"&abc|';
my @tests = (
    [$s,      'NONE',     $s,    'NONE pseudo escape works'],
    [$s,      'HTML',     '&lt;&gt;&quot;&amp;abc|',
                                  "HTML escape of '$s'"    ],
    ['<<<',   'HTML',     '&lt;&lt;&lt;',
                                  "HTML escape of '<<<'"   ],
    [' ',     'URI',      '%20', 'Can URI-escape a space'  ],

);

for @tests -> $t {
    is escape($t[0], $t[1]), $t[2], $t[3];
}

# vim: ft=perl6
