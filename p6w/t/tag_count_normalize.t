use v6;

use Test;
plan 2;

use Wiki;

my @counts_to_test = (
    [ { one => 2, foo => 5, bar => 6, her => 14 }, 
      { one => 0, foo => 4, bar => 5, her => 10} ],
    [ { one => 5, foo => 5, bar => 2, her => 1 }, 
      { one => 10, foo => 10, bar => 4, her => 0} ],
);

for @counts_to_test -> $each {
    my $tags = $each[0];
    my $expected = $each[1];

    my %out;
    for $tags.kv -> $tag, $count {
        %out{$tag} = tag_count_normalize($count, $tags.values.min, $tags.values.max);
    } 

    is_deeply( %out , $expected, 'Normalize: ' ~ $tags.perl );
}
