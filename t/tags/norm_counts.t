use v6;

use Test;
plan 3;

use November::Tags;

use November::Config;
my $config = November::Config.new(
    server_root => 't/tags/',
);

role Testing {
    method clear {
        my $c = {};
        self.write_tags_count( $c );
    }
}

my $t = November::Tags.new(:$config) does Testing;
$t.clear;

is( ($t.norm_counts).perl, '{}', 'With empty tags_count norm_counts produce empty Hash' );

my $in = { foo => 5, bar => 5, baz => 2, her => 1 };
$t.write_tags_count($in);

is-deeply( $t.norm_counts, {"foo" => 10, "bar" => 10, "baz" => 4, "her" => 0}, 'Normalize all from: ' ~ $in.perl );

my @tags = <foo baz>;
is-deeply( $t.norm_counts(@tags), {"foo" => 10, "baz" => 4}, 'Normalize foo and baz from: ' ~ $in.perl );


$t.clear;

# vim:ft=perl6
