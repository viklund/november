use v6;

use Test;
plan 4;

use November::Storage::File;

my $s = November::Storage::File.new does Testing;
$s.index_path = 't/storage/index_data';

$s.clear;

is($s.read_index.perl, '[]', 'Read clear index');
$s.add_to_index('Foo');
is($s.read_index.perl, '["Foo"]', 'Add to index one page');
$s.add_to_index('Bar');
is($s.read_index.perl, '["Foo", "Bar"]', 'Add to index another page');
$s.add_to_index('Foo');
is($s.read_index.perl, '["Foo", "Bar"]', 'Do not add to index page doubble');

$s.clear;

role Testing {
    method clear {
        my $fh = open($.index_path, :w);
        $fh.say('[]');
        $fh.close;
    }
}

# vim:ft=perl6
