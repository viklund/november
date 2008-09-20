use v6;
use November__Storage;  # RAKUDO: :: in module names doesn't fully work

# RAKUDO: :: in class names doesn't fully work
class November__Storage__File is November__Storage {
    my $.content_path        is rw;
    my $.modifications_path  is rw;
    my $.recent_changes_path is rw;
    my $.page_tags_path      is rw;
    my $.tags_count_path     is rw;
    my $.tags_index_path     is rw;

    method init {
        $.content_path = 'data/articles/';
        $.modifications_path = 'data/modifications/';
        $.recent_changes_path = 'data/recent-changes';
        $.page_tags_path = 'data/page_tags/';
        $.tags_count_path = 'data/tags_count';
        $.tags_index_path = 'data/tags_index';
    }

    method wiki_page_exists($page) {
        return file_exists( $.content_path ~ $page );
    }

    method read_recent_changes {
        return [] unless file_exists( $.recent_changes_path );
        return eval( slurp( $.recent_changes_path ) );
    }

    method write_recent_changes ( $recent_changes ) {
        my $fh = open($.recent_changes_path, :w);
        $fh.say($recent_changes.perl);
        $fh.close;
    }

    method read_page_history($page) {
        my $file = $.content_path ~ $page;
        return [] unless file_exists( $file );
        my $page_history = eval( slurp($file) );
        return $page_history;
    }

    method write_page_history( $page, $page_history ) {
        my $file = $.content_path ~ $page;
        my $fh = open($file, :w);
        $fh.say( $page_history.perl );
        $fh.close;
    }

    method read_modification($modification_id) {
        my $file = $.modifications_path ~ $modification_id;
        # RAKUDO: use :e
        return [] unless file_exists( $file );
        return eval( slurp($file) );
    }

    method write_modification ( $modification_id, $modification ) {
        my $data = $modification.perl;
        r_remove($data);

        my $file =  $.modifications_path ~ $modification_id;
        my $fh = open( $file, :w );
        $fh.say( $data );
        $fh.close();
    }

    method add_tags ($page, $tags) {

        # RAKUDO: return with modificaton parsed wrong
        return 1 if $tags ~~ m/^ \s* $/;
        my $count = self.read_tags_count;

        my @tags = tags_parse($tags);
        for @tags -> $t {
            # RAKUDO: Increment not implemented in class 'Undef'
            if $count{$t} {
                $count{$t}++;
            } 
            else {
                $count{$t} = 1;
            }
        }

        self.write_tags_count($count);

        my $index = self.read_tags_index;

        for @tags -> $t {
            # I think it`s must be Hash of Arrays, but right now look like 
            # with Hash of Hashes it`s simply to realize.
            unless $index{$t} {
                $index{$t} = {};
            }
            unless $index{$t}{$page} {
                $index{$t}{$page} = 1;
            }

        }

        self.write_tags_index($index);
    }

    method remove_tags($page, $tags) {
        
        # RAKUDO: return with modificaton parsed wrong
        return 1 if $tags ~~ m/^ \s* $/;

        my $count = self.read_tags_count;

        my @tags = tags_parse($tags);
        for @tags -> $t {
            # RAKUDO: Decrement not implemented in class 'Undef'
            if $count{$t} && $count{$t} > 0 {
                $count{$t}--;
            } 
            else {
                $count{$t} = 0;
            }
        }

        self.write_tags_count($count);

        my $index = self.read_tags_index;

        for @tags -> $t {
            # I think it`s must be Hash of Arrays, but right now look like with
            # Hash of Hashes it`s simply to realize.
            if $index{$t} && $index{$t}{$page} {
                    $index{$t}{$page} = 0;
            }
        }
        self.write_tags_index($index);
    }

    method read_page_tags($page) {
        my $file = $.page_tags_path ~ $page;
        # RAKUDO: use :e
        return '' unless file_exists( $file );
        return slurp($file);
    }

    method write_page_tags ($page, $tags) {
        my $file =  $.page_tags_path ~ $page;
        my $fh = open( $file, :w );
        $fh.say( $tags );
        $fh.close();
    }
   
    method read_tags_count {
        my $file = $.tags_count_path;
        # RAKUDO: use :e
        return {} unless file_exists($file);
        return eval( slurp($file) );
    }

    method write_tags_count (Hash $counts) {
        my $file =  $.tags_count_path;
        my $fh = open( $file, :w );
        $fh.say( $counts.perl );
        $fh.close();
    }

    method read_tags_index {  
        my $file = $.tags_index_path;
        # RAKUDO: use :e
        return {} unless file_exists($file);
        return eval( slurp($file) );
    }

    method write_tags_index (Hash $index) {
        my $file =  $.tags_index_path;
        my $fh = open( $file, :w );
        $fh.say( $index.perl );
        $fh.close();
    }

    method get_tag_count ($tag)  {
        my $counts = self.read_tags_count;
        unless $counts {
            # TODO: I think we must say warn there, but look like it`s do not 
            # implemented in Rakudo now. Or may be it`s not {warn "foo"} today. 
            return 1;
        }
        return $counts{$tag};
            
    }
}
