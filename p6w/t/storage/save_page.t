use v6;

use Test;
plan 1;

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
$s.content_path        = 't/storage/data/articles/';
$s.modifications_path  = 't/storage/data/modifications/';
$s.recent_changes_path = 't/storage/data/recent-changes';
$s.index_path = 't/storage/index_data';

$s.beforeTest;

is($s.read_index.perl, '[]', 'Read clear index');

#TODO: more tests here :)

$s.afterTest;


# vim:ft=perl6
