use v6;

use Test;
plan 5;

use November::Storage::File;

role Testing {
    method clear {
        run 'rm t/storage/data/modifications/*';
        run 'touch t/storage/data/modifications/empty-file';
    }
}

my $s = November::Storage::File.new does Testing;
$s.modifications_path = 't/storage/data/modifications/';

my $id = $s.write_modification([ 'Page', 'Text', 'Author' ]);

ok($id, 'write_modification returns an id');

my $modif = $s.read_modification($id);

is($modif[0], 'Page', 'read modification data -- Page');
is($modif[1], 'Text', 'read modification data -- Text');
is($modif[2], 'Author', 'read modification data -- Author');
ok($modif[3] <= time.Int, 'read time, and it <= now');

$s.clear;

# vim:ft=perl6
