use v6;

use Test;
plan 8;

use November::Tags;

use November::Config;
my $config = November::Config.new(
    server_root => 't/tags/',
);

role Testing {
    method clear ($_:) {
        my $c = {};
        .write_tags_count($c);
        .write_tags_index($c);
        .write_page_tags('Test_Page', '');
        .write_page_tags('Another_Page', '');
    }
}

my $t = November::Tags.new(:$config) does Testing;
$t.page_tags_path  = 't/tags/data/page_tags/';
$t.tags_count_path = 't/tags/data/tags_count';
$t.tags_index_path = 't/tags/data/tags_index';

$t.clear;

$t.update_tags('Test_Page', 'Foo, Bar');

is-deeply(
    $t.read_tags_count,
    {"foo" => 1, "bar" => 1},
    'Simple tag counting'
);
is-deeply(
    $t.read_tags_index,
    {"foo" => ["Test_Page"], "bar" => ["Test_Page"]},
    'Simple tag indexing'
);

$t.update_tags('Test_Page', 'Bar, Her');

is-deeply(
    $t.read_tags_count,
    {"bar" => 1, "her" => 1},
    'Tag count after addition and removal'
);
is-deeply(
    $t.read_tags_index,
    {"foo" => [], "bar" => ["Test_Page"], "her" => ["Test_Page"]},
    'Tag index after add and remove'
);

$t.update_tags('Another_Page', 'Bar, Her');

is-deeply(
    $t.read_tags_count,
    {"bar" => 2, "her" => 2},
    'Tag count after adding another page'
);
is-deeply(
    $t.read_tags_index,
    {
        "foo" => [],
        "bar" => ["Test_Page", "Another_Page"],
        "her" => ["Test_Page", "Another_Page"]
    },
    'Tags index after adding another page'
);

$t.update_tags('Test_Page', 'Bar, Her');

is-deeply(
    $t.read_tags_count,
    {"bar" => 2, "her" => 2},
    'Tag count after saving a page without changes');
is-deeply(
    $t.read_tags_index,
    {
        "foo" => [],
        "bar" => ["Test_Page", "Another_Page"],
        "her" => ["Test_Page", "Another_Page"]
    },
    'Tag index after save page without changes'
);

$t.clear;

# vim:ft=perl6
