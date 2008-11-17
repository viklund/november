use v6;

role Session;

has $.sessionfile_path;

# RAKUDO: default value not implemented with keyword has
method init {
    $!sessionfile_path = 'data/sessions';
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
    return {} unless $.sessionfile_path ~~ :e;
    my $string = slurp( $.sessionfile_path );
    my $stuff = eval( $string );
    return $stuff;
}

method write_sessions( $sessions ) {
    my $fh = open( $.sessionfile_path, :w );
    $fh.say( $sessions.perl );
    $fh.close;
}

method new_session($user_name) {
    my $session_id = get_unique_id();
    self.add_session( $session_id, { user_name => $user_name } );
    return $session_id;
}

sub get_unique_id {
    # hopefully pretty unique ID
    return int(time%1000000/100) ~ time%100
}

# vim:ft=perl6
