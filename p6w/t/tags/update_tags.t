use v6;

use Test;
plan 8;

use Tags;

my $t = Tags.new does Testing;
$t.page_tags_path  = 't/tags/data/page_tags/';
$t.tags_count_path = 't/tags/data/tags_count';
$t.tags_index_path = 't/tags/data/tags_index';

$t.clear;

$t.update_tags('Test_Page', 'Foo, Bar');

is_deeply( $t.read_tags_count, {"foo" => 1, "bar" => 1}, 'Simple tags counting');
is_deeply( $t.read_tags_index, {"foo" => ["Test_Page"], "bar" => ["Test_Page"]}, 'Simple tags indexing' );

$t.update_tags('Test_Page', 'Bar, Her');

is_deeply( $t.read_tags_count, {"bar" => 1, "her" => 1}, 'Tags counting after add and remove');
is_deeply( $t.read_tags_index, {"foo" => [], "bar" => ["Test_Page"], "her" => ["Test_Page"]}, 'Tags indexing after add and remove' );

$t.update_tags('Another_Page', 'Bar, Her');

is_deeply( $t.read_tags_count, {"bar" => 2, "her" => 2}, 'Tags count after add another page');
is_deeply( $t.read_tags_index, {"foo" => [], "bar" => ["Test_Page", "Another_Page"], "her" => ["Test_Page", "Another_Page"]}, 'Tags index after add another page' );

$t.update_tags('Test_Page', 'Bar, Her');

is_deeply( $t.read_tags_count, {"bar" => 2, "her" => 2}, 'Tags count after save page without changes');
is_deeply( $t.read_tags_index, {"foo" => [], "bar" => ["Test_Page", "Another_Page"], "her" => ["Test_Page", "Another_Page"]}, 'Tags index after save page without changes' );

$t.clear;

role Testing {
    method clear ($_:) {
        my $c = {};
        .write_tags_count($c);
        .write_tags_index($c);
        .write_page_tags('Test_Page', '');
        .write_page_tags('Another_Page', '');
    }
}

# vim:ft=perl6
