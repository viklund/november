use v6;

use Test;
plan 8;

use Tags;

my @to_parse = (    
    'foo',
      ['foo'],
    'foo,bar',
      ['foo', 'bar'],
    'foo, bar',
      ['foo', 'bar'],
    'foo, bar ,her',
      ['foo', 'bar', 'her'],
    "foo\n",
      ['foo'],
    'foo , bar    , her',
      ['foo', 'bar', 'her'],
    'Foo',
      ['foo'],
    'foo, BAR',
      ['foo', 'bar'],
);

my $t = Tags.new;

for @to_parse -> $in, $expected {
    is_deeply( $t.tags_parse($in), $expected, 'Parse tags: ' ~ $in.perl);
}

# vim:ft=perl6
