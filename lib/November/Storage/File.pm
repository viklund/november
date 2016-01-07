use v6;

use November::Storage;
use November::Utils;
use MONKEY-SEE-NO-EVAL;

class November::Storage::File is November::Storage {

    has $.storage_root is rw;
    #my $r = $.config.server_root;

    # RAKUDO: initial attr value do not fully works 
    # given November::Config.server_root { # and use $_ inside. 
    # But we can`t do that now because "my".
    has $.content_path        is rw; # = $r ~ 'data/articles/';
    has $.modifications_path  is rw; # = $r ~ 'data/modifications/';
    has $.recent_changes_path is rw; # = $r ~ 'data/recent-changes';
    has $.index_path          is rw; # = $r ~ 'data/index';

    submethod BUILD(:$storage_root) {
        $!storage_root = $storage_root;

        $!content_path        = $!storage_root ~ 'articles/';
        $!modifications_path  = $!storage_root ~ 'modifications/';
        $!recent_changes_path = $!storage_root ~ 'recent-changes';
        $!index_path          = $!storage_root ~ 'index';
    }

    method wiki_page_exists($page) {
        return ($.content_path ~ $page).IO ~~ :e;
    }

    method read_recent_changes {
        return [] unless $.recent_changes_path.IO ~~ :e;
        return EVAL( slurp( $.recent_changes_path ) );
    }

    method write_recent_changes ($recent_changes) {
        my $fh = open($.recent_changes_path, :w);
        $fh.say($recent_changes.perl);
        $fh.close;
    }

    method read_page_history($page) {
        my $file = $.content_path ~ $page;
        return [] unless $file.IO ~~ :e;
        my $page_history = EVAL( slurp($file) );
        return $page_history;
    }

    method write_page_history($page, $page_history) {
        my $file = $.content_path ~ $page;
        my $fh = open($file, :w);
        $fh.say( $page_history.perl );
        $fh.close;
    }

    method read_modification($modification_id) {
        my $file = $.modifications_path ~ $modification_id;
        return [] unless $file.IO ~~ :e;
        return EVAL( slurp($file) );
    }

    method write_modification ($modification) {
        my $modif = $modification;
        $modif.push(time.Int);
        my $data = $modif.perl;
        r_remove($data);

        my $modification_id = get_unique_id;

        my $file =  $.modifications_path ~ $modification_id;
        my $fh = open( $file, :w );
        $fh.say( $data );
        $fh.close();

        return $modification_id;
    }

    method add_to_index ($page) {
        my $index = self.read_index;
        # RAKUDO: @ $index not impemented yet :(
        # unless any( @ $index) eq $page {
        unless any($index.values) eq $page {
            $index.push($page);
            my $fh = open($.index_path, :w);
            $fh.say($index.perl);
            $fh.close;
        }
    }

    method read_index {
        return EVAL( slurp($.index_path) );
    }
}

# vim:ft=perl6
