use Test::More tests => 2;
use November;
use Data::Dumper;

my $tf = \&November::tag_count_normalize;

my @counts_to_test = (
    [ { one => 2, foo => 5, bar => 6, her => 14 }, 
      { one => 0, foo => 4, bar => 5, her => 10} ],
    [ { one => 5, foo => 5, bar => 2, her => 1 }, 
      { one => 10, foo => 10, bar => 4, her => 0} ],
);

for (@counts_to_test) {
    my ($tags, $expected) = @$_;

    my %tags     = %$tags;
    my %expected = %$expected;


    use List::Util qw| max min |;

    my $min = min values %tags;
    my $max = max values %tags;
    my %out;
    for (keys %tags)  {
        $out{$_} = $tf->($tags{$_}, $min, $max);
    } 
    
    is-deeply( \%out , \%expected, 'Normalize: ' . Dumper(\%tags) );
}
