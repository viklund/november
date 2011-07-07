use v6;

use Test;
plan 4;

use November::Storage::File;

role Testing {
    method beforeTest {
        my $fh = open($.index_path, :w);
        $fh.say('[]');
        $fh.close;
    }

    method afterTest {
        # TODO: Make more platform-independent, somehow.
        run("rm $.index_path");
    }
}

my $s = November::Storage::File.new does Testing;
$s.index_path = 't/storage/index_data';

$s.beforeTest;

is($s.read_index.perl, '[]', 'Read clear index');
$s.add_to_index('Foo');
is($s.read_index.perl, '["Foo"]', 'Add to index one page');
$s.add_to_index('Bar');
is($s.read_index.perl, '["Foo", "Bar"]', 'Add to index another page');
$s.add_to_index('Foo');
is($s.read_index.perl, '["Foo", "Bar"]', 'Do not add dup to index page');

$s.afterTest;


# vim:ft=perl6
