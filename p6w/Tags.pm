use v6;

class Tags {
    method page_tags($page) {};
    method cloud_tags() {};
    my $.page_tags_path      = 'data/page_tags/';
    my $.tags_count_path     = 'data/tags_count';
    my $.tags_index_path     = 'data/tags_index';

    method tags_parse ($tags) {
        my @tags = $tags.lc.split(/ \s* ( ',' | \n ) \s* /);
        # split in p6 don`t trim
        @tags = grep { $_ ne "" }, @tags;
        return @tags;
    }

    method tag_count_normalize ($count, $min, $max) {
        my $step = ($count - $min) / (($max - $min) || 1);
        ceiling( ( log($step + 1 ) * 10 ) / log 2 ); 
    }
    
    method add_tags ($page, $tags) {

        # RAKUDO: return with modificaton parsed wrong
        return 1 if $tags ~~ m/^ \s* $/;
        my $count = self.read_tags_count;

        my @tags = self.tags_parse($tags);
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

        my @tags = self.tags_parse($tags);
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
        return '' unless $file ~~ :e;
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
        return {} unless $file ~~ :e;
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
        return {} unless $file ~~ :e;
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

    method save_tags ($page, $tags) {
        my $old_tags = self.read_page_tags($page); 
        self.remove_tags($page, $old_tags);
        self.add_tags($page, $tags);

        self.write_page_tags($page, $tags);
    }

    method page_tags ( $page ) {
        my $page_tags = self.read_page_tags($page);
        my @page_tags = self.tags_parse($page_tags); 
        my $tags = self.read_tags_count;
        
        my $min = $tags.values.min; 
        my $max = $tags.values.max;

        # does exist clearest way to check @tags... mb @t ~~ [] ?
        if @page_tags[0] {
            # ugly, we must use template instead
            @page_tags = map { '<a class="t' 
                ~ self.tag_count_normalize(self.get_tag_count($_), 
                                      $min, 
                                      $max ) 
                ~ '" href="?action=toc&tag=' ~ $_ ~'">' 
                ~ $_ ~ '</a>'}, @page_tags;

            $page_tags = @page_tags.join(', ');
        }
        return $page_tags;
    }

    method cloud_tags () {
        my $tags_str = '';
        my $tags = self.read_tags_count;
        
        my $min = $tags.values.min; 
        my $max = $tags.values.max;

        if $tags {
            for $tags.keys -> $tag {
                # ugly, we must use template instead
                if $tags{$tag} > 0 {
                    $tags_str ~= '<a class="t' 
                        ~ self.tag_count_normalize( $tags{$tag}, $min, $max ) 
                        ~ '" href="?action=toc&tag=' ~ $tag ~ '">' 
                        ~ $tag ~ '</a> ';
                }
            }
        }
        return $tags_str;
    }

    method update_tags ($page, $tags) {

        my $old_tags = self.read_page_tags($page);

        self.remove_tags($page, $old_tags);
        self.add_tags($page, $tags);
        self.write_page_tags($page, $tags);
    }
}

# vim:ft=perl6
