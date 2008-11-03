use v6;

use Test;
plan 2;

use Tags;

my @counts_to_test = 
        [ 2, 5, 6, 14 ], 
        [ 0, 4, 5, 10 ],

        [ 5,  5,  2, 1 ], 
        [ 10, 10, 4, 0 ];

my $t = Tags.new;

for @counts_to_test -> $in, $expected {

    # RAKUDO: list assigment do not implemented
    # my $min, $max = $in.min, $in.max;
    my $min = $in.min;
    my $max = $in.max;
    
    # debugging
    # say $in.perl ~ " min:$min, max:$max";

    # RAKUDO: min and max there save its values, and I cant reasign it :( 
    # So, second map work with wrong min and max
    my $out = map { $t.norm($_, $min, $max) }, $in.values;

    is_deeply( $out, $expected, 'Normalize: ' ~ $in.perl );
}


