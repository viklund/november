use v6;

use CGI;
use HTML::Template;

sub file_exists( $file ) {
    # RAKUDO: use ~~ :e
    my $exists = False;
    try {
        my $fh = open( $file );
        $exists = True;
    }
    return $exists;
}

sub get_unique_id {
    # hopefully pretty unique ID
    return int(time%1000000/100) ~ time%100
}

role Session {
    has $.sessionfile_path  is rw;
    has $.sessions          is rw;

    method init {
        # RAKUDO: set the attributes when declaring them
        $.sessionfile_path = 'data/sessions';
    }

    method add_session( $id, %stuff) {
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
        return {} unless file_exists( $.sessionfile_path );
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
}

class Storage {
    method wiki_page_exists($page)                               { ... }

    method read_recent_changes()                                 { ... }
    method write_recent_changes( $recent_changes )               { ... }

    method read_page_history($page)                              { ... }
    method write_page_history( $page, $page_history )            { ... }

    method read_modification($modification_id)                   { ... }
    method write_modification( $modification_id, $modification ) { ... }

    method save_page($page, $new_text, $author) {
        my $modification_id = get_unique_id();

        my $page_history = self.read_page_history($page);
        $page_history.unshift( $modification_id );
        self.write_page_history( $page, $page_history );

        self.write_modification( $modification_id, 
                                 [ $page, $new_text, $author] );

        self.add_recent_change( $modification_id );
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

class Storage::File is Storage {
    my $.content_path        is rw;
    my $.modifications_path  is rw;
    my $.recent_changes_path is rw;

    method init {
        $.content_path = 'data/articles/';
        $.modifications_path = 'data/modifications/';
        $.recent_changes_path = 'data/recent-changes';
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
        my $file =  $.modifications_path ~ $modification_id;
        my $fh = open( $file, :w );
        $fh.say( $modification.perl );
        $fh.close();
    }
}

class Wiki does Session {

    my $.template_path       is rw;
    my $.userfile_path       is rw;

    has Storage $.storage    is rw;
    has CGI     $.cgi        is rw;

    method init {
        # RAKUDO: set the attributes when declaring them
        $.template_path = 'skin/';
        $.userfile_path = 'data/users';

        # Multiple dispatch doesn't work
        $.storage = Storage::File.new();
        $.storage.init();
        #Storage::File::init(self);
        Session::init(self);
    }

    method handle_request(CGI $cgi) {
        $.cgi = $cgi;

        my $action = $cgi.param<action> // 'view';

        # Maybe we should consider turning this given into a lookup hash.
        # RAKUDO: 'when' doesn't break out by default yet
        given $action {
            when 'view'           { self.view_page();           return; }
            when 'edit'           { self.edit_page();           return; }
            when 'log_in'         { self.log_in();              return; }
            when 'log_out'        { self.log_out();             return; }
            when 'recent_changes' { self.list_recent_changes(); return; }
        }

        self.not_found();
    }

    method view_page() {
        my $page = $.cgi.param<page> // 'Main_Page';

        if !$.storage.wiki_page_exists($page) {
            my $template = HTML::Template.new(
                filename => $.template_path ~ 'not_found.tmpl');

            $template.param('PAGE' => $page);

            $.cgi.send_response(
                $template.output(),
            );
            return;
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'view.tmpl');

        $template.param('TITLE'     => $page);
        $template.param('CONTENT'   => self.format_html(
                                           $.storage.read_page($page)
                                       ));
        $template.param('LOGGED_IN' => self.logged_in());

        $.cgi.send_response(
            $template.output(),
        );
    }

    method logged_in() {
        my $sessions = self.read_sessions();
        my $session_id = $.cgi.cookie<session_id>;
        # RAKUDO: 'defined' should maybe be 'exists', although here it doesn't
        # matter.
        return defined $session_id && defined $sessions{$session_id};
    }

    method edit_page() {
        my $page = $.cgi.param<page> // 'Main_Page';

        my $sessions = self.read_sessions();

        return self.not_authorized() unless self.logged_in();

        my $already_exists
                        = $.storage.wiki_page_exists($page);
        my $action      = $already_exists ?? 'Editing' !! 'Creating';
        my $old_content = $already_exists ?? $.storage.read_page($page) !! '';
        my $title = "$action $page";

        # The 'edit' action handles both showing the form and accepting the
        # POST data. The difference is the presence of the 'articletext'
        # parameter -- if there is one, the action is considered a save.
        if $.cgi.param<articletext> {
            my $new_text = $.cgi.param<articletext>;
            my $session_id = $.cgi.cookie<session_id>;
            my $author = $sessions{$session_id}<user_name>;
            $.storage.save_page($page, $new_text, $author);
            return self.view_page();
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'edit.tmpl');

        $template.param('PAGE'      => $page);
        $template.param('TITLE'     => $title);
        $template.param('CONTENT'   => $old_content);
        $template.param('LOGGED_IN' => True);

        $.cgi.send_response(
            $template.output(),
        );
    }

    method not_authorized() {
        my $template = HTML::Template.new(
            filename => $.template_path ~ 'action_not_authorized.tmpl');

        # TODO: file bug, without "'" it is interpreted as named args and not
        #       as Pair
        $template.param('DISALLOWED_ACTION' => 'edit pages');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method read_users {
        # RAKUDO: use :e
        return {} unless file_exists( $.userfile_path );
        return eval( slurp( $.userfile_path ) );
    }

    method quote($metachar) {
        # RAKUDO: Chained trinary operators do not do what we mean yet.
        return '&#039;' if $metachar eq '\'';
        return '&lt;'   if $metachar eq '<';
        return '&gt;'   if $metachar eq '>';
        return '&amp;'  if $metachar eq '&';
        return $metachar;
    }

    sub convenient_line_break($text, $length) {
        return $text.chars if $text.chars < $length;
        # RAKUDO: This should of course be done with rindex, once that's
        # in place.
        for reverse(0 .. $length), $length .. $text.chars -> $pos {
            return $pos if $text.substr( $pos, 1 ) eq ' ';
        }
        return $text.chars;
    }

    sub wrap($text, $length) {
        my $clb = convenient_line_break($text, $length);

        return $text if $clb >= $text.chars;

        my $rest_of_string = $text.substr($clb).subst(/^ \s+/, '');

        return $text.substr(0, $clb) ~ "\n" ~ wrap($rest_of_string, $length);
    }

    sub indent($text, $length) {
        return join("\n", map { ' ' x $length ~ $_ }, split("\n", $text));
    }

    method format_html($text is rw) {
        # RAKUDO: $text.split( /\n\n/ )
        my @pars = grep { $_ ne "" },
                   map { $_.subst( / ^ \n /, '' ) },
                   $text.split("\r\n\r\n");

        my @formatted;
        for @pars -> $par {
            if $par ~~ Wiki::Syntax::paragraph {
                # RAKDUO: Must match again. [perl #57858]
                $par ~~ Wiki::Syntax::paragraph;

                my $result;

                if $/<heading> {
                    # RAKDUO: Must match again. [perl #57858]
                    $par ~~ Wiki::Syntax::paragraph;

                    $result = '<h1>'
                        ~ $/<heading>.values[0].subst( / ^ \s+ /, '' ).subst(
                          / \s+ $ /, '')
                        ~ '</h1>';
                }
                else {
                    # RAKDUO: Must match again. [perl #57858]
                    $par ~~ Wiki::Syntax::paragraph;

                    $result = '<p>';

                    for $/<parchunk> -> $chunk {
                        my $text = $chunk.values[0];
                        given $chunk.keys[0] {
                            when 'twext'     { $result ~= $text }
                            when 'wikimark'  { my $page = substr($text, 2, -2);
                                               $result ~= self.make_link($page) }
                            when 'metachar'  { $result ~= self.quote($text) }
                            when 'malformed' { $result ~= $text }
                        }
                    }
                    $result ~= "</p>";

                    push @formatted, indent( wrap($result, 60), 12 );
                }
            }
            else {
                push @formatted, indent( '<p>Could not parse paragraph.</p>',
                                         12 );
            }
        }

        return join "\n\n", @formatted;
    }

    method make_link($page) {
        return sprintf('<a href="?action=%s&page=%s"%s>%s</a>',
                       $.storage.wiki_page_exists($page)
                         ?? ('view', $page, '')
                         !! ('edit', $page, ' class="nonexistent"'),
                       $page);
    }

    method not_found() {
        my $template = HTML::Template.new(
            filename => $.template_path ~ 'not_found.tmpl');

        $template.param('PAGE'      => 'Action Not found');
        $template.param('LOGGED_IN' => self.logged_in());

        $.cgi.send_response(
            $template.output(),
        );
        return;
    }

    method log_in {
        if my $user_name = $.cgi.param<user_name> {

            my $password = $.cgi.param<password>;

            my %users = self.read_users();

            # Yes, this is cheating. Stand by for a real MD5 hasher.
            if (defined %users{$user_name} 
               and $password eq %users{$user_name}<plain_text>) {
#            if Digest::MD5::md5_base64(
#                   Digest::MD5::md5_base64($user_name) ~ $password
#               ) eq %users{$user_name}<password> {

                my $session_id = self.new_session($user_name);
                my $session_cookie = "session_id=$session_id";

                my $template = HTML::Template.new(
                    filename => $.template_path ~ 'login_succeeded.tmpl');

                $.cgi.send_response(
                    $template.output(),
                    { cookie => $session_cookie }
                );

                return;
            }

            my $template = HTML::Template.new(
                filename => $.template_path ~ 'login_failed.tmpl');

            $.cgi.send_response(
                $template.output(),
            );

            return;
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'log_in.tmpl');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method log_out {
        # TODO: Fix 500 error on server
        if defined $.cgi.cookie('session_id') {

            my $session_id = $.cgi.cookie('session_id');
            self.remove_session( $session_id );

            my $session_cookie = "session_id=''";

            my $template = HTML::Template.new(
                filename => $.template_path ~ 'logout_succeeded.tmpl');

            $.cgi.send_response(
                $template.output(),
                { :cookie($session_cookie) }
            );

            return;
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'logout_succeeded.tmpl');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method list_recent_changes {

        # RAKUDO: Seemingly impossible to get the right number of list
        # containers using an array variable @recent_changes here.
        my $recent_changes = $.storage.read_recent_changes();

        my @changes;
        for $recent_changes.values -> $modification_id {
            my $modification = $.storage.read_modification($modification_id);
            push @changes, { 'page' => self.make_link( $modification[0] ),
                             'time' => $modification_id,
                             'author' => $modification[2] || 'somebody' };
        }

        my $template = HTML::Template.new(
                filename => $.template_path ~ 'recent_changes.tmpl');

        $template.param('CHANGES'   => @changes);
        $template.param('LOGGED_IN' => self.logged_in());

        $.cgi.send_response(
            $template.output()
        );

        return;
    }
}

grammar Wiki::Syntax {

    token paragraph { ^ <parchunk>+ $ };

    token parchunk { <twext> || <wikimark> || <metachar> || <malformed> };

    # RAKUDO: a token may not be called 'text' [perl #57864]
    token twext { [ <alnum> || <otherchar> || <sp> ]+ };

    token otherchar { <[ !..% (../ : ; ? @ \\ ^..` {..~ ]> };

    token sp { ' ' | \n };

    token wikimark { '[[' <twext> ']]' };

    token metachar { '<' || '>' || '&' || \' };

    token malformed { '[' || ']' }
}

