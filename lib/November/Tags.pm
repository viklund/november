use v6;

use November::Config;

class November::Tags {
    has $.page_tags_path is rw;
    has $.tags_count_path is rw;
    has $.tags_index_path is rw;

    submethod BUILD(:$config = November::Config.new) {
        $!page_tags_path = $config.server_root ~ 'data/page_tags/';
        $!tags_count_path = $config.server_root ~ 'data/tags_count';
        $!tags_index_path = $config.server_root ~ 'data/tags_index';
    }

    method update_tags($_: Str $page, Str $new_tags) {
        my $old_tags = .read_page_tags($page).chomp;
        return 1 if $new_tags eq $old_tags;

        my @old_tags = .tags_parse: $old_tags;
        my @new_tags = .tags_parse: $new_tags;

        my @to_add    = @new_tags.grep: { $_ eq none(@old_tags) };
        my @to_remove = @old_tags.grep: { $_ eq none(@new_tags) };

        .remove_tags($page, @to_remove);
        .add_tags($page, @to_add);
        .write_page_tags($page, $new_tags);
    }

    method add_tags(Str $page, @tags) {

        my %count = self.read_tags_count;
        %count{$_}++ for @tags;
        self.write_tags_count(%count);

        my $index = self.read_tags_index;

        for @tags -> $t {
            unless $index{$t} {
                $index{$t} = [];
            }
            unless any($index{$t}.values) eq $page {
                $index{$t}.push($page);
                # RAKUDO: bug w/ var on both lhs and rhs
                my @tmp = grep { $_ ne '' }, $index{$t}.values;
                $index{$t} = @tmp;
            }
        }

        self.write_tags_index($index);
    }

    method remove_tags(Str $page, @tags) {
        
        my $count = self.read_tags_count;

        for @tags -> $t {
            $count{$t}--;
            
            $count{$t} :delete if $count{$t} <= 0; 
        }

        self.write_tags_count($count);

        my $index = self.read_tags_index;

        for @tags -> $t {
            # RAKUDO: @ not implemented yet
            #if $index{$t} && any(@ $index{$t}) eq $page {
            if $index{$t} && any($index{$t}.values) eq $page {
                    # RAKUDO: bug w/ var on both lhs and rhs
                    my @tmp = grep { $_ ne $page }, $index{$t}.values;
                    $index{$t} = @tmp;
            }
        }
        self.write_tags_index($index);
    }

    method read_page_tags(Str $page) {
        my $file = $.page_tags_path ~ $page;
        return '' unless $file.IO ~~ :e;
        return slurp($file);
    }

    method write_page_tags(Str $page, Str $tags) {
        my $file = $.page_tags_path ~ $page;
        my $fh = open( $file, :w );
        $fh.say($tags);
        $fh.close;
    }
   
    method read_tags_count() {
        my $file = $.tags_count_path;
        return {} unless $file.IO ~~ :e;
        return EVAL slurp $file;
    }

    method write_tags_count(Hash $counts) {
        my $file = $.tags_count_path;
        my $fh = open( $file, :w );
        $fh.say( $counts.perl );
        $fh.close;
    }

    method read_tags_index() {
        my $file = $.tags_index_path;
        return {} unless $file.IO ~~ :e;
        return EVAL slurp $file;
    }

    method write_tags_index(Hash $index) {
        my $file = $.tags_index_path;
        my $fh = open( $file, :w );
-        $fh.say( $index.perl );
        $fh.close;
    }

    method tags_parse(Str $tags) {
        return () if $tags ~~ m/^ \s* $/;
        my @tags = $tags.lc.split(/ \s* ( ',' | \n | '.' ) \s* /);
        grep { $_ ne "" }, @tags.uniq;
    }

    method norm_counts(@tags?) {
        my %counts = self.read_tags_count;

        my ($min, $max) = 0, 0;

        if %counts.keys {
            $min = +(%counts.values).min;
            $max = +(%counts.values).max;
        }

        my $norm_counts = {};

        for @tags || %counts.keys {
            $norm_counts{$_} = self.norm( +%counts{$_}, $min, $max ); 
        }
        return $norm_counts;
    }

    method norm($count, $min, $max) {
        my $step = ($count - $min) / (($max - $min) || 1);
        return ceiling( ( log($step + 1 ) * 10 ) / log 2 ); 
    }
    
    method page_tags(Str $page) {
        my @page_tags = self.tags_parse( self.read_page_tags: $page ); 
        return @page_tags.map: { {NAME => $_} };
    }

    method all_tags() {
        my $norm_counts = self.norm_counts; 
        return $norm_counts.keys.map: { {NAME => $_, COUNT => $norm_counts{$_}} };
    }
}

# vim:ft=perl6
