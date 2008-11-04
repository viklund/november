use v6;

use Test;
plan 3;

use Tags;
my $t = Tags.new does Testing;
$t.tags_count_path = 't/tags/data/tags_count';
$t.clear;

is( $t.norm_counts.perl, '{}', 'With empty tags_count norm_counts produce empty Hash' );

my $in = { foo => 5, bar => 5, baz => 2, her => 1 };
$t.write_tags_count( $in );

is( $t.norm_counts.perl, '{"foo" => 10, "bar" => 10, "baz" => 4, "her" => 0}', 'Normalize all from: ' ~ $in.perl );

my @tags = <foo baz>;
is( $t.norm_counts(@tags).perl, '{"foo" => 10, "baz" => 4}', 'Normalize foo and baz from: ' ~ $in.perl );


$t.clear;

role Testing {
    method clear {
        my $c = {};
        self.write_tags_count( $c );
    }
}
