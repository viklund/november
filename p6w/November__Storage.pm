use v6;

class November__Storage {
    method wiki_page_exists($page)                               { ... }

    method read_recent_changes()                                 { ... }
    method write_recent_changes( $recent_changes )               { ... }

    method read_page_history($page)                              { ... }
    method write_page_history( $page, $page_history )            { ... }

    method read_modification($modification_id)                   { ... }
    method write_modification( $modification_id, $modification ) { ... }

    method read_page_tags ($page)                                { ... }
    method write_page_tags ($page, $tags)                        { ... }

    method add_tags ($page, $tags)                               { ... }
    method remove_tags ($page, $tags)                            { ... }

    method read_tags_count                                       { ... }
    method write_tags_count (Hash $count)                        { ... }

    method read_tags_index                                       { ... }
    method write_tags_index (Hash $index)                        { ... }

    method get_tag_count ($page)                                { ... }


    method save_page($page, $new_text, $author, $tags) {
        my $modification_id = get_unique_id();

        my $page_history = self.read_page_history($page);
        $page_history.unshift( $modification_id );
        self.write_page_history( $page, $page_history );

        self.write_modification( $modification_id, 
                                 [ $page, $new_text, $author] );
        
        my $old_tags = self.read_page_tags($page); 
        self.remove_tags($page, $old_tags);
        self.add_tags($page, $tags);

        self.write_page_tags($page, $tags);
    }

    method add_recent_change( $modification_id ) {
        my $recent_changes = self.read_recent_changes();
        $recent_changes.unshift($modification_id);
        self.write_recent_changes( $recent_changes );
    }

    method read_page($page) {
        my $page_history = self.read_page_history($page);
        return "" unless $page_history;
        my $latest_change = self.read_modification( $page_history.shift );
        return $latest_change[1];
    }
}
