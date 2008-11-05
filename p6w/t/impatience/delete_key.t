use v6;

use Test;
plan 1;
use Impatience;

my $h = {foo => 1, bar => 2};
delete_key($h, "foo");

is( $h.perl, '{"bar" => 2}', 'Delete key from the hash');
