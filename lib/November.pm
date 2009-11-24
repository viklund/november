use v6;

use Session;
use Cache;
use Digest;

class November does Session does Cache {

    use CGI;
    use Tags;
    use HTML::Template;
    use Dispatcher;
    use Utils;
    use Config;
    use November::Storage::File;
    use Text::Markup::Wiki::MediaWiki;

    has November::Storage $.storage;
    has CGI     $.cgi;
    has Config  $.config;

    submethod BUILD( :$config = Config.new ) {
        $!config = $config;
        $!storage = November::Storage::File.new(
            storage_root => $!config.server_root ~ 'data/'
        );
    }

    method handle_request(CGI $cgi) {
        $!cgi = $cgi;

        my $d = Dispatcher.new( default => { self.error_page } );

        $d.add: [
            [''],                     { self.view_page },
            ['view', /^ <-[?/]>+ $/], { self.view_page(~$^page) },
            ['edit', /^ <-[?/]>+ $/], { self.edit_page(~$^page) },
            ['in'],                   { self.log_in },
            ['out'],                  { self.log_out },
            ['register'],             { self.register },
            ['recent'],               { self.list_recent_changes },
            ['history'],              { self.view_page_history(~$^page) },
            ['all'],                  { self.list_all_pages },
        ];

        my @chunks = $cgi.uri.chunks.list;
        $d.dispatch(@chunks);
    }

    method view_page($page is rw='Main_Page') {
        $page .= subst('%20', '_', :g);

        unless $.storage.wiki_page_exists($page) {
            self.not_found($page);
            return;
        }

        # TODO: we need plugin system (see topics in mail-list)
        my $t = Tags.new;

        my $title = $page.trans( ['_'] => [' '] );

        my $content;
        my $cached_page = self.get-cache-entry( $page );
        if ( $cached_page ) {
            $content = $cached_page;
        }
        else {
            my $markup = $.config.markup;

            $content = $markup.format(
                        # MediaWiki markup can't handle trailing spaces, gh-16
                        $.storage.read_page( $page ).subst(/[\s|\n]+$/, ''),
                        link_maker    => { self.make_link($^p, $^t) },
                        extlink_maker => { self.make_extlink($^p, $^t)}
            );

            self.set-cache-entry( $page, $content );
        }

        self.response( 'view.tmpl',
            {
            TITLE    => $title,
            PAGE     => $page,
            CONTENT  => $content,
            PAGETAGS => $t.page_tags($page),
            RECENTLY => self.get_changes( page => $page, :limit(8) ),

            TAGS     => $t.all_tags,
            }
        );

    }

    method edit_page($page is rw) {
        $page .= subst('%20', '_', :g);
        my $sessions = self.read_sessions();

        return self.not_authorized() unless self.logged_in();

        my $already_exists
                        = $.storage.wiki_page_exists($page);
        my $action      = $already_exists ?? 'Editing' !! 'Creating';
        my $old_content = $already_exists ?? $.storage.read_page($page) !! '';
        my $title = $action ~ ' ' ~ $page.trans( ['_'] => [' '] );

        # The 'edit' action handles both showing the form and accepting the
        # POST data. The difference is the presence of the 'articletext'
        # parameter -- if there is one, the action is considered a save.
        if $.cgi.params<articletext> || $.cgi.params<tags> {
            my $summary    = $.cgi.params<summary>;
            my $new_text   = $.cgi.params<articletext>;
            my $tags       = $.cgi.params<tags>;
            my $session_id = $.cgi.cookie<session_id>;
            my $author     = $sessions{$session_id}<user_name>;

            if $.cgi.params<preview> {
                # It's only a preview, should just send it back formatted
                return self.show_preview( $page, $summary, $new_text, $tags );
            }

            $.storage.save_page($page, $new_text, $author, $summary);
            self.remove-cache-entry( $page );

            # TODO: we need plugin system (see topics in mail-list)
            my $t = Tags.new();
            $t.update_tags($page, $tags);

            $.cgi.redirect('/view/' ~ $page );
            return;
        }

        # TODO: we need plugin system (see topics in mail-list)
        my $t = Tags.new;
        self.response( 'edit.tmpl',
            {
            PAGE     => $page,
            TITLE    => $title,
            CONTENT  => $old_content,
            PAGETAGS => $t.read_page_tags($page),
            }
        );
    }

    method show_preview( $page is rw, $summary, $new_text, $tags ) {
        $page .= subst('%20', '_', :g);
        my $title = $page.trans( ['_'] => [' '] );

        my $markup = $.config.markup;

        my $content = $markup.format(
                    # MediaWiki markup can't handle trailing spaces, gh-16
                    $new_text.subst(/[\s|\n]+$/, ''),
                    link_maker    => { self.make_link($^p, $^t) },
                    extlink_maker => { self.make_extlink($^p, $^t)}
        );

        # Should really use the $tags parameter here, this will do for now...
        #my $t = Tags.new();
        #my $tags = $t.tags_parse( $tags );

        self.response( 'edit.tmpl',
            {
            ACTION   => 'Editing',
            PAGE     => $page,
            TITLE    => $title,
            SUMMARY  => $summary,
            CONTENT  => $new_text,
            PREVIEW  => $content,
            PAGETAGS => $tags,
            }
        );
    }

    method logged_in() {
        my $sessions = self.read_sessions();
        my $session_id = $.cgi.cookie<session_id>;
        # RAKUDO: 'defined' should maybe be 'exists', although here it doesn't
        # matter.
        defined $session_id && defined $sessions{$session_id}
    }

    method not_authorized {
        self.response( 'action_not_authorized.tmpl',
            { DISALLOWED_ACTION => 'edit pages' }
        );
    }

    method read_users {
        return {} unless $.config.userfile_path ~~ :e;
        return eval( slurp( $.config.userfile_path ) );
    }

    method not_found($page?) {
        #TODO: that should by 404 when no $page
        self.response('not_found.tmpl',
            {
            'PAGE' => $page || 'Action Not found'
            }
        );
    }

    method register {
        # Real work will come later.
        self.response('register.tmpl');
    }
    
    method log_in {
        if my $user_name = $.cgi.params<user_name> {
            my $password = $.cgi.params<password>;

            my %users = self.read_users();

            # Yes, this is cheating. Stand by for a real MD5 hasher.
            if defined %users{$user_name}
                and digest(digest($user_name, 'sha256') ~ $password,
                          'sha256'
                   ) eq %users{$user_name}<password> {

                my $session_id = self.new_session($user_name);
                my $session_cookie = "session_id=$session_id";

                self.response('login_succeeded.tmpl',
                    {},
                    { cookie => $session_cookie }
                );
                return;
            }

            self.response('login_failed.tmpl');
            return;
        }
        self.response('log_in.tmpl');
    }

    method log_out {
        if defined $.cgi.cookie<session_id> {
            my $session_id = $.cgi.cookie<session_id>;
            self.remove_session( $session_id );

            my $session_cookie = "session_id=";

            self.response('logout_succeeded.tmpl',
                {},
                { :cookie($session_cookie) }
            );
            return;
        }

        self.response('logout_succeeded.tmpl');
    }

    method error_page($message = "An internal error occurred. Apologies.") {
        self.response( 'error.tmpl', { MESSAGE => $message } );
    }

    method list_recent_changes {
        self.response('recent_changes.tmpl',
            {
            'CHANGES'   => self.get_changes(limit => 50),
            }
        );
    }

    method view_page_history($page is rw = 'Main_Page') {
        $page .= subst('%20', '_', :g);

        unless $.storage.wiki_page_exists($page) {
            self.not_found($page);
            return;
        }

        my $title = $page.trans( ['_'] => [' '] );

        self.response('page_history.tmpl',
            {
            'TITLE'     => $title,
            'CHANGES'   => self.get_changes($page, limit => 50),
            }
        );
    }

    method get_changes (:$page, :$limit) {
        # RAKUDO: Seemingly impossible to get the right number of list
        # containers using an array variable @recent_changes here.
        my $recent_changes;

        if $page {
            $recent_changes = $.storage.read_page_history($page);
        }
        else {
            $recent_changes = $.storage.read_recent_changes;
        }

        return map {
            my $modification = $.storage.read_modification($_);
            {
                'PAGE' => self.make_link($modification[0],$modification[0]),
                'TIME' => time_to_period_str($modification[4])
                          || $_,
                'AUTHOR' => $modification[2] || 'somebody'
            }
        }, $recent_changes[ $limit.defined
                            ?? ^($limit min $recent_changes.elems)
                            !! * ];
    }

    method list_all_pages {

        my $t = Tags.new();
        my %params;
        %params<TAGS> = $t.all_tags if $t;

        my $index;

        my $tag = $.cgi.params<tag>;
        if $tag and $t {
            # TODO: we need plugin system (see topics in mail-list)
            my $tags_index = $t.read_tags_index;
            $index = $tags_index{$tag};
            %params<TAG> = $tag;
        }
        else {
            $index = $.storage.read_index;
        }

        if $index {
            # RAKUDO: @($arrayref) not implemented yet, so:
            # my @list = map { { page => $_ } }, @($index);
            # does not work. Workaround:
            my @list = map { { PAGE => $_,
                               TITLE => $_.trans( ['_'] => [' '] )
                           } }, $index.values;
            %params<LIST> = @list;
        }

        self.response('list_all_pages.tmpl', %params);
    }

    # RAKUDO: die at hash merge if %params undef, so I use default value
    method response ($tmpl, %params?={}, %opts?) {
        my $template = HTML::Template.from_file($.config.template_path ~ $tmpl);

        $template.with_params(
            {
            WEBROOT   => $!config.web_root,
            LOGGED_IN => self.logged_in,
            SKIN      => $!config.skin,
            TMPL_PATH => $!config.template_path,
            %params
            }
        );

        $.cgi.send_response($template.output, %opts);
    }

    method make_link($page is copy, $title) {
        $page .= subst(' ', '_', :g);
        my $root = $!config.web_root;
        if $title {
            if $page ~~ m/':'/ {
                return qq|<a href="{ $root ~ $page }">$title</a>|;
            } else {
                return qq|<a href="$root/view/$page">$title</a>|;
            }
        } else {
            return sprintf('<a href="%s/%s/%s" %s >%s</a>',
                            $root,
                            $.storage.wiki_page_exists($page)
                                ?? ('view', $page, '')
                                !! ('edit', $page, ' class="nonexistent"'),
                            $page);
        }
    }

    method make_extlink($url, $title) {
        if $title {
            return qq|<a href="$url">$title</a>|;
        } else {
            return qq|<a href="$url">$url</a>|;
        }
    }
}

# vim:ft=perl6
