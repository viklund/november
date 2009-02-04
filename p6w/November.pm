use CGI;
use Tags;
use HTML::Template;
use Text::Markup::Wiki::MediaWiki;
use Session;
use Dispatcher;
use Utils;
use Config;

class November does Session {
    use November::Storage::File;  

    has $.template_path = Config.server_root ~ 'skins/' ~ Config.skin ~ '/';
    has $.userfile_path = Config.server_root ~ 'data/users';

    has November::Storage $.storage;
    has CGI     $.cgi;

    # RAKUDO: BUILD do not implemented yet
    method init {
        $!storage = November::Storage::File.new();
    }

    method handle_request(CGI $cgi) {
        $!cgi = $cgi;

        my $action = $cgi.params<action> // 'view';

        my $d = Dispatcher.new( default => { self.not_found } );

        $d.add_rules(
            [
            [''],                { self.view_page },
            ['view', /^ \w+ $/], { self.view_page(~$^page) },
            ['edit', /^ \w+ $/], { self.edit_page(~$^page) },
            ['in'],              { self.log_in },
            ['out'],             { self.log_out },
            ['recent'],          { self.list_recent_changes },
            ['all'],             { self.list_all_pages },
            ]
        );

        my @chunks = $cgi.uri.chunks.list;
        $d.dispatch(@chunks);
    }

    method view_page($page='Main_Page') {

        unless $.storage.wiki_page_exists($page) {
            self.not_found($page);
            return;
        }

        my $minimal = Text::Markup::Wiki::MediaWiki.new;

        # TODO: we need plugin system (see topics in mail-list)
        my $t = Tags.new;

        my $title = $page.trans( ['_'] => [' '] );
        
        self.response( 'view.tmpl', 
            { 
            TITLE    => $title,
            PAGE     => $page,
            CONTENT  => $minimal.format($.storage.read_page( $page ),
                                 link_maker    => { self.make_link($^p, $^t) },
                                 extlink_maker => { self.make_extlink($^p, $^t) }
            ),
            PAGETAGS => $t.page_tags($page), 
            RECENTLY => self.get_changes( page => $page, :limit(8) ),

            TAGS     => $t.all_tags,
            }
        );

    }

    method edit_page($page) {
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
            my $new_text   = $.cgi.params<articletext>;
            my $tags       = $.cgi.params<tags>;
            my $session_id = $.cgi.cookie<session_id>;
            my $author     = $sessions{$session_id}<user_name>;
            $.storage.save_page($page, $new_text, $author);

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
        return {} unless $.userfile_path ~~ :e;
        return eval( slurp( $.userfile_path ) );
    }

    method not_found($page?) {
        #TODO: that should by 404 when no $page 
        self.response('not_found.tmpl', 
            { 
            'PAGE' => $page || 'Action Not found'
            }
        );
    }

    method log_in {
        if my $user_name = $.cgi.params<user_name> {
            my $password = $.cgi.params<password>;

            my %users = self.read_users();

            # Yes, this is cheating. Stand by for a real MD5 hasher.
            if (defined %users{$user_name} 
                and $password eq %users{$user_name}<plain_text>) {
    #            if Digest::MD5::md5_base64(
    #                   Digest::MD5::md5_base64($user_name) ~ $password
    #               ) eq %users{$user_name}<password> {

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


    method list_recent_changes {
        self.response('recent_changes.tmpl',
            {
            'CHANGES'   => self.get_changes(limit => 50),
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

        # @recent_changes = @recent_changes[0..$limit] if $limit;
        # RAKUDO: array slices do not implemented yet, so:
        my @changes;
        for $recent_changes.list -> $modification_id {
            my $modification = $.storage.read_modification($modification_id);
            my $count = push @changes, {
                'PAGE' => self.make_link($modification[0],$modification[0]),
                'TIME' => time_to_period_str($modification[3])
                          || $modification_id,
                'AUTHOR' => $modification[2] || 'somebody' 
                };
            # RAKUDO: last not implemented yet :(
            return @changes if $limit && $count == $limit;
        }
        return @changes;
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
        my $template = HTML::Template.from_file($.template_path ~ $tmpl);
        
        $template.with_params(
            {
            WEBROOT   => Config.web_root,
            LOGGED_IN => self.logged_in,
            SKIN      => Config.skin,
            TMPL_PATH => $.template_path,
            %params
            }
        );

        $.cgi.send_response($template.output, %opts);
    }

    method make_link($page, $title) {
        my $root = Config.web_root;
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
