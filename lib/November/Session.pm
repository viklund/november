unit role November::Session;

method sessionfile-path {
    return $.config.server_root  ~ 'data/sessions';
}

method add_session($id, %stuff) {
    my $sessions = self.read_sessions();
    $sessions{$id} = %stuff;
    self.write_sessions($sessions);
}

method remove_session($id) {
    my $sessions = self.read_sessions();
    $sessions.delete($id);
    self.write_sessions($sessions);
}

method read_sessions {
    use MONKEY-SEE-NO-EVAL;
    return {} unless self.sessionfile-path.IO ~~ :e;
    my $string = slurp( self.sessionfile-path );
    my $stuff = EVAL( $string );
    return $stuff;
}

method write_sessions( $sessions ) {
    my $fh = open( self.sessionfile-path, :w );
    $fh.say( $sessions.perl );
    $fh.close;
}

method new_session($user_name) {
    use November::Utils;
    my $session_id = get_unique_id;
    self.add_session( $session_id, { user_name => $user_name } );
    return $session_id;
}

# vim:ft=perl6
