use v6;

use Test;
use Test::InputOutput;

use Text::Markup::Wiki::MediaWiki;

my @tests =
    [ '<'  => '<p>&lt;</p>',   '&lt;'   ],
    [ '>'  => '<p>&gt;</p>',   '&gt;'   ],
    [ '&'  => '<p>&amp;</p>',  '&amp;'  ],
    [ '\'' => '<p>&#039;</p>', '&#039;' ];

plan +@tests;

my $converter = Text::Markup::Wiki::MediaWiki.new;
Test::InputOutput.using( { $converter.format($^input) } ).test(@tests);

# vim:ft=perl6
