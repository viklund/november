class November::Storage;

method wiki_page_exists($page)                               { ... }

method read_recent_changes()                                 { ... }
method write_recent_changes($recent_changes)                 { ... }

method read_page_history($page)                              { ... }
method write_page_history($page, $page_history)              { ... }

method read_modification($modification_id)                   { ... }
method write_modification($modification)                     { ... }

# RAKUDO: IO::Dir::open not implemented yet,
# so we use index -- workaround for all_pages
method add_to_index($page)                                   { ... }
method read_index()                                          { ... }


method save_page($_: $page, $new_text, $author, $summary) {
    .add_to_index($page) unless .wiki_page_exists($page); 
    my $modif_id = .write_modification([$page, $new_text, $author, $summary]);
    .add_page_history($page, $modif_id);
    .add_recent_change($modif_id); 
}

method add_page_history ($page, $modification_id) {
    my $page_history = self.read_page_history($page);
    $page_history.unshift($modification_id);
    self.write_page_history($page, $page_history);
}

method add_recent_change($modification_id) {
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

# vim:ft=perl6
