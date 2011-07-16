use v6;

# RAKUDO: Needed because of [perl #73912]
class November { ... }

use November::Session;
use November::Cache;
use Digest;

class November does November::Session does November::Cache {

    use November::Request;
    use November::Tags;
    use HTML::Template;
    use Dispatcher;
    use November::Utils;
    use November::Config;
    use November::Storage::File;
    use Text::Markup::Wiki::MediaWiki;

    has November::Storage $.storage;
    has November::Config  $.config;
    has November::Request $.request;
    has Dispatcher $!dispatcher;

    submethod BUILD( :$config = November::Config.new ) {
        $!config = $config;
        $!storage = November::Storage::File.new(
            storage_root => $!config.server_root ~ 'data/'
        );

        $!dispatcher = Dispatcher.new( default => { self.not_found } );
        $!dispatcher.add: [
            [''],                     { self.view_page },
            ['view', /^ <-[?/]>+ $/], { self.view_page(~$^page) },
            ['edit', /^ <-[?/]>+ $/], { self.edit_page(~$^page) },
            ['in'],                   { self.log_in },
            ['out'],                  { self.log_out },
            ['register'],             { self.register },
            ['recent'],               { self.list_recent_changes },
            ['history', /^ <-[?/]>+ $/], { self.view_page_history(~$^page) },
            ['all'],                  { self.list_all_pages },
        ];
    }

    method handle_request(%env) {
        $!request = November::Request.new(:%env);
        #note "REQUEST: ", $!request.perl;

        my @chunks = $!request.uri.chunks.list;
        #note "Dispatching on {@chunks.perl}";
        return $!dispatcher.dispatch(@chunks);
    }

    method view_page($page is copy = 'Main_Page') {
        $page .= subst('%20', '_', :g);

        unless $.storage.wiki_page_exists($page) {
            return self.no_such_page($page);
        }

        # TODO: we need plugin system (see topics in mail-list)
        my $t = November::Tags.new(:$.config);

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

        my $page_tags = $t.page_tags($page);
        note "View w/ tags: {$page_tags.perl}";
        return self.response( 'view.tmpl',
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

    method edit_page($page is copy) {
        $page .= subst('%20', '_', :g);
        my $sessions = self.read_sessions();

        return self.not_authorized() unless self.logged_in();

        my $already_exists
                        = $.storage.wiki_page_exists($page);
        my $action      = $already_exists ?? 'Editing' !! 'Creating';
        my $old_content = $already_exists ?? $.storage.read_page($page) !! '';
        my $title = $page.trans( ['_'] => [' '] );

        my %params = {
            ACTION   => $action,
            PAGE     => $page,
            TITLE    => $title,
            CONTENT  => $old_content,
        }

        # The 'edit' action handles both showing the form and accepting the
        # POST data. The difference is the presence of the 'articletext'
        # parameter -- if there is one, the action is considered a save.
        if $.request.params<articletext> || $.request.params<tags> {
            my $summary    = $.request.params<summary>;
            my $new_text   = $.request.params<articletext>;
            my $tags       = $.request.params<tags>;
            my $session_id = $.request.cookie<session_id>;
            my $author     = $sessions{$session_id}<user_name>;

            if $.request.params<preview> {
                # It's only a preview, just send it back formatted
                %params<SUMMARY> = $summary;
                %params<CONTENT> = $new_text;
                %params<PAGETAGS> = $tags;
                return self.show_preview(%params);
            }

            $.storage.save_page($page, $new_text, $author, $summary);
            self.remove-cache-entry( $page );

            # TODO: we need plugin system (see topics in mail-list)
            my $t = November::Tags.new(:$.config);
            $t.update_tags($page, $tags);

            return self.redirect('/view/' ~ $page );
        }

        # TODO: we need plugin system (see topics in mail-list)
        my $t = November::Tags.new(:$.config);
        %params<PAGETAGS> = $t.read_page_tags($page);
        return self.response( 'edit.tmpl', %params );
    }

    method show_preview(%params is rw) {
        my $page = %params<PAGE>.subst('%20', '_', :g);
        my $title = $page.trans( ['_'] => [' '] );

        my $markup = $.config.markup;

        %params<PREVIEW> = $markup.format(
                    # MediaWiki markup can't handle trailing spaces, gh-16
                    %params<CONTENT>.subst(/[\s|\n]+$/, ''),
                    link_maker    => { self.make_link($^p, $^t) },
                    extlink_maker => { self.make_extlink($^p, $^t)}
        );

        # Should really use the $tags parameter here, this will do for now...
        #my $t = November::Tags.new(:$.config);
        #my $tags = $t.tags_parse( $tags );

        return self.response( 'edit.tmpl', %params );
    }

    method logged_in() {
        my $sessions = self.read_sessions();
        my $session_id = $.request.cookie<session_id>;
        # RAKUDO: 'defined' should maybe be 'exists', although here it doesn't
        # matter.
        defined $session_id && defined $sessions{$session_id}
    }

    method not_authorized {
        return self.response( 'action_not_authorized.tmpl',
            { DISALLOWED_ACTION => 'edit pages' }
        );
    }

    method read_users {
        return {} unless $.config.userfile_path.IO ~~ :e;
        return eval( slurp( $.config.userfile_path ) );
    }

    method no_such_page($page?) {
        return self.not_found unless $page;
        return self.response('no_such_page.tmpl',
            {
            'PAGE' => $page || 'Action Not found'
            }
        );
    }

    method register {
        if my $user_name = $.request.params<user_name> {
            my $password = $.request.params<password>;
            my $passagain = $.request.params<passagain>;
            
            my Str @errors;
            
            if !defined $password || $password eq '' {
                push @errors, 'Please provide a password.';
            }
            
            if $password && $password.chars < 6 {
                push @errors, 'Please provide at least six characters for '
                              ~ 'your password.';
            }
            
            if $password & $passagain && $password ne $passagain {
                push @errors, 'The password and confirmation must match.';
            }
            my %users = self.read_users();
            if defined %users{$user_name} {
                push @errors, 'This username is taken. Please choose another.';
            }

            if @errors {
                # TODO: Send @errors to template.
                return self.response('register_failed.tmpl');
            }
            my $phash = digest(digest($user_name, 'sha256') ~ $password, 'sha256');
            # TODO: Add the user to the users file.
        }
        return self.response('register.tmpl');
    }
    
    method log_in {
        #note "Log in called";
        if my $user_name = $.request.params<user_name> {
            my $password = $.request.params<password>;

            my %users = self.read_users();

            # Yes, this is cheating. Stand by for a real MD5 hasher.
            if defined %users{$user_name}
                and digest(digest($user_name, 'sha256') ~ $password,
                          'sha256'
                   ) eq %users{$user_name}<password> {

                my $session_id = self.new_session($user_name);
                my $session_cookie = "session_id=$session_id";
                # Stuff this back into $.request so logged_in() sees it
                $.request.cookie<session_id> = $session_id;

                #note "Log in OK: $session_cookie";
                return self.response('login_succeeded.tmpl',
                    opts => { cookie => $session_cookie }
                );
            }

            #note "Log in FAILED [$user_name,$password]";
            return self.response('login_failed.tmpl');
        }
        return self.response('log_in.tmpl');
    }

    method log_out {
        if defined $.request.cookie<session_id> {
            my $session_id = $.request.cookie<session_id>;
            self.remove_session( $session_id );

            my $session_cookie = "session_id=";

            return self.response('logout_succeeded.tmpl',
                opts => { :cookie($session_cookie) }
            );
        }

        return self.response('logout_succeeded.tmpl');
    }

    method error_page($message = "An internal error occurred. Apologies.") {
        return self.response( 'error.tmpl',
            { MESSAGE => $message ~ "<pre>{self.perl}</pre>" }
        );
    }

    method list_recent_changes {
        return self.response('recent_changes.tmpl',
            {
            'CHANGES'   => self.get_changes(limit => 50),
            }
        );
    }

    method view_page_history($page is copy = 'Main_Page') {
        $page .= subst('%20', '_', :g);

        unless $.storage.wiki_page_exists($page) {
            self.no_such_page($page);
            return;
        }

        my $title = $page.trans( ['_'] => [' '] );

        return self.response('page_history.tmpl',
            {
            'TITLE'     => $title,
            'CHANGES'   => self.get_changes(:$page, limit => 50),
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

        my $t = November::Tags.new(:$.config);
        my %params;
        %params<TAGS> = $t.all_tags if $t;

        my $index;

        my $tag = $.request.params<tag>;
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

        return self.response('list_all_pages.tmpl', %params);
    }

    method redirect($uri, :%opts = {}) {
        #note "REDIRECT: $uri";
        return [
            %opts<status> || 302,
            [Location => $uri],
            []
        ];
    }

    # RAKUDO: Instead of %params? we do %params = {}, because the former
    #         doesn't quite work. [perl #79642]
    method response ($tmpl, %params = {}, :%opts = {}) {
        #note "RESPONSE: $tmpl";
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

        my @headers = ('Content-Type' => 'text/html; charset=utf-8');
        if %opts && %opts<cookie> {
            push @headers, 'Set-Cookie' => "%opts<cookie>; path=/;";
        }
        return [
            200,
            [ @headers ],
            [ $template.output ]
        ];
    }

    method not_found (:$message = 'Not Found') {
        return [
            404,
            ['Content-Type' => 'text/plain'],
            [$message]
        ];
    }

    method make_link($page is copy, $title is copy) {
        $title ||= $page.subst('_', ' ', :g);
        $page .= subst(' ', '_', :g);
        my $root = $!config.web_root;

        if $page ~~ m/':'/ {
            return qq|<a href="{ $root ~ $page }">{$title}</a>|;
        } else {
            return sprintf('<a href="%s/%s/%s" %s >%s</a>',
                            $root,
                            $.storage.wiki_page_exists($page)
                                ?? ('view', $page, '')
                                !! ('edit', $page, ' class="nonexistent"'),
                            $title);
        }
    }

    method make_extlink($url, $title is copy) {
        $title ||= $url;
        return qq|<a href="$url">{$title}</a>|;
    }
}

# vim:ft=perl6
