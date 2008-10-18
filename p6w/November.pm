use v6;

use CGI;
use Tags;
use HTML__Template;            # RAKUDO: :: in module names doesn't fully work
use Text__Markup__Wiki__Minimal;
use November__Storage__File;   # RAKUDO: :: in module names doesn't fully work

sub get_unique_id {
    # hopefully pretty unique ID
    return int(time%1000000/100) ~ time%100
}

role Session {
    has $.sessionfile_path  is rw;

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
}

class November does Session {

    has $.template_path;
    has $.userfile_path;

    # RAKUDO: :: in module names doesn't fully work
    has November__Storage $.storage;
    has CGI     $.cgi;

    method init {
        # RAKUDO: set the attributes when declaring them
        $!template_path = 'skin/';
        $!userfile_path = 'data/users';

        # RAKUDO: :: in module names doesn't fully work
        $!storage = November__Storage__File.new();
        Session::init(self);
    }

    method handle_request(CGI $cgi) {
        $!cgi = $cgi;

        my $action = $cgi.param<action> // 'view';

        # Maybe we should consider turning this given into a lookup hash.
        # RAKUDO: 'when' doesn't break out by default yet, #57652
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

        unless $.storage.wiki_page_exists($page) {
            self.not_found;
            return;
        }

        my $template = HTML__Template.new(
            filename => $.template_path ~ 'view.tmpl');

        $template.param('TITLE'     => $page);
        $template.param('CONTENT'   => Text__Markup__Wiki__Minimal.new.format(
                                           $.storage.read_page($page),
                                           { self.make_link($^page) }
                                       ));

        # TODO: we need plugin system (see topics in mail-list)
        my $t = Tags.new();
        my $page_tags = $t.page_tags( $page );
        $template.param('PAGETAGS' => $page_tags);
        my $cloud_tags = $t.cloud_tags();
        $template.param('TAGS' => $cloud_tags);
        
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
        defined $session_id && defined $sessions{$session_id}
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
        if $.cgi.param<articletext> || $.cgi.param<tags> {
            my $new_text = $.cgi.param<articletext>;
            my $tags = $.cgi.param<tags>;
            my $session_id = $.cgi.cookie<session_id>;
            my $author = $sessions{$session_id}<user_name>;
            $.storage.save_page($page, $new_text, $author);

            # TODO: we need plugin system (see topics in mail-list)
            my $t = Tags.new();
            $t.update_tags($page, $tags);

            return self.view_page();
        }

        my $template = HTML__Template.new(
            filename => $.template_path ~ 'edit.tmpl');

        $template.param('PAGE'      => $page);
        $template.param('TITLE'     => $title);
        $template.param('CONTENT'   => $old_content);

        # TODO: we need plugin system (see topics in mail-list)
        my $t = Tags.new;
        $template.param('PAGETAGS' => $t.read_page_tags($page));

        $template.param('LOGGED_IN' => True);

        $.cgi.send_response(
            $template.output(),
        );
    }

    method not_authorized() {
        my $template = HTML__Template.new(
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
        return {} unless $.userfile_path ~~ :e;
        return eval( slurp( $.userfile_path ) );
    }

    method not_found() {
        my $template = HTML__Template.new(
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

                my $template = HTML__Template.new(
                    filename => $.template_path ~ 'login_succeeded.tmpl');

                $.cgi.send_response(
                    $template.output(),
                    { cookie => $session_cookie }
                );

                return;
            }

            my $template = HTML__Template.new(
                filename => $.template_path ~ 'login_failed.tmpl');

            $.cgi.send_response(
                $template.output(),
            );

            return;
        }

        my $template = HTML__Template.new(
            filename => $.template_path ~ 'log_in.tmpl');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method log_out {
        if defined $.cgi.cookie<session_id> {

            my $session_id = $.cgi.cookie<session_id>;
            self.remove_session( $session_id );

            my $session_cookie = "session_id=";

            my $template = HTML__Template.new(
                filename => $.template_path ~ 'logout_succeeded.tmpl');

            $.cgi.send_response(
                $template.output(),
                { :cookie($session_cookie) }
            );

            return;
        }

        my $template = HTML__Template.new(
            filename => $.template_path ~ 'logout_succeeded.tmpl');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method make_link($page) {
        return sprintf('<a href="?action=%s&page=%s"%s>%s</a>',
                       $.storage.wiki_page_exists($page)
                         ?? ('view', $page, '')
                         !! ('edit', $page, ' class="nonexistent"'),
                       $page);
    }

    method list_recent_changes {

        # RAKUDO: Seemingly impossible to get the right number of list
        # containers using an array variable @recent_changes here.
        my $recent_changes = $.storage.read_recent_changes();

        my @changes;
        for $recent_changes.values -> $modification_id {
            my $modification = $.storage.read_modification($modification_id);
            push @changes, {
                'page' => self.make_link($modification[0]),
                'time' => $modification_id,
                'author' => $modification[2] || 'somebody' };
        }

        my $template = HTML__Template.new(
                filename => $.template_path ~ 'recent_changes.tmpl');

        $template.param('CHANGES'   => @changes);
        $template.param('LOGGED_IN' => self.logged_in());

        $.cgi.send_response(
            $template.output()
        );

        return;
    }
}

# vim:ft=perl6
