use v6;

use Test;
plan 4;

use Tags;

my $t = Tags.new;
$t.page_tags_path  = 't/tags/data/page_tags/';
$t.tags_count_path = 't/tags/data/tags_count';
$t.tags_index_path = 't/tags/data/tags_index';

clear($t);

$t.update_tags('Test_Page', 'Foo, Bar');

is( $t.read_tags_count.perl, '{"foo" => 1, "bar" => 1}', 'Tags count');
is( $t.read_tags_index.perl, '{"foo" => {"Test_Page" => 1}, "bar" => {"Test_Page" => 1}}', 'Tags index' );

# I think in future index may look like:
#is( $t.read_tags_index.perl, '{"foo" => ["Test_Page"], "bar" => ["Test_Page"]}', 'Tags index' );

$t.update_tags('Test_Page', 'Bar, Her');

is( $t.read_tags_count.perl, '{"foo" => 0, "bar" => 1, "her" => 1}', 'Tags count');

# TODO: Ooops! Now there "bar" => {"Test_Page" => 0} but it`s bugging all_pages list
is( $t.read_tags_index.perl, '{"bar" => {"Test_Page" => 1}, "her" => {"Test_Page" => 1}}', 'Tags index' );

clear($t);

sub clear (Tags $t) {
    my $c = {};
    $t.write_tags_count( $c );
    $t.write_tags_index( $c );
    $t.write_page_tags('Test_Page', '');
}
