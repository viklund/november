#!/usr/bin/perl -w
use strict;

package November;

use HTTP::Server::Simple::CGI;
use HTML::EscapeEvil;
use File::Slurp;
use DateTime;
use Data::Dumper;
use HTML::Template;
use Digest::MD5 qw(md5_base64);

use base qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    'view'           => \&view_page,
    'edit'           => \&edit_page,
    'view_history'   => \&view_history,
    'view_diff'      => \&view_diff,
    'log_in'         => \&log_in,
    'log_out'        => \&log_out,
    'recent_changes' => \&list_recent_changes,
    'all_pages'      => \&list_all_pages,
);

my $SKIN_USED = 'CleanAndSoft';

my $TEMPLATE_PATH = "skins/$SKIN_USED/";
my $CONTENT_PATH = 'data/articles/';
my $RECENT_CHANGES_PATH = 'data/recent-changes';
my $MODIFICATIONS_PATH = 'data/modifications/';
my $USERFILE_PATH = 'data/users';
my $PUGS_PATH = '/Users/masak/svn-work/hobbies/pugs';

my $PAGE_TAGS_PATH  = 'data/page_tags/';
my $TAGS_COUNT_PATH = 'data/tags_count';
my $TAGS_INDEX_PATH = 'data/tags_index';

my $PUGS_PREFIX = 'pugs';

my %sessions;

sub status_ok        { return "HTTP/1.0 200 OK\r\n\r\n"; }
sub status_not_found { return "HTTP/1.0 404 Not found\r\n\r\n"; }

sub handle_request {
    my ($self, $cgi) = @_;

    my $path = $cgi->path_info();
    if ( $path =~ m{^/\w+\.(?:css|png)$} ) {
        print status_ok(),
              read_file( $TEMPLATE_PATH . $path );
        return;
    }

    my $action = $cgi->param('action') || 'view';
    my $handler = $dispatch{$action};

    if (ref($handler) eq "CODE") {
        $handler->($cgi);
    }
    else {
        print unknown_action($cgi);
    }
}

sub unknown_action {
    my ($cgi) = @_;

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'unknown_action.tmpl');

    $template->param(ACTION => $cgi->param('action'));
    $template->param(LOGGED_IN => logged_in($cgi));

    return status_not_found(),
           $template->output();
}

sub escape {
    my ($string) = @_;

    return '' if !defined $string;
    my $escapeevil = HTML::EscapeEvil->new(allow_entity_reference => 0);
    $escapeevil->parse($string);
    return $escapeevil->filtered_html;
}

sub exists_wiki_page {
    my ($page) = @_;

    if ( my ($path) = $page =~ m[ ^ $PUGS_PREFIX \b (.*) $ ]x ) {
        return -e $PUGS_PATH.$path;
    }
    return $page && -e $CONTENT_PATH.$page;
}

# Pretty-printing of page names. A more self-explanatory (but still succinct)
# name for this subroutine would be a good thing -- suggestions welcome.
sub pp {
    my ($name) = @_;

    $name =~ s/_/ /g;

    return $name;
}

sub make_link {
    my ($page, $title) = @_;

    $title ||= pp($page);
    return exists_wiki_page( $page )
           ? qq|<a href="/?page=$page">$title</a>|
           : qq|<a href="/?page=$page&action=edit" class="nonexistent">$title</a>|;
}

sub make_external_link {
    my ($url, $title) = @_;

    $title ||= $url;
    return qq|<a href="$url">$title</a>|;
}

sub make_old_href {
    my ($page, $revision) = @_;

    return "/?page=$page&revision=$revision";
}

sub make_diff_href {
    my ($page, $old_revision, $new_revision) = @_;

    return sprintf('/?page=%s&action=view_diff&old_revision=%s&new_revision=%s',
                   $page, $old_revision, $new_revision);
}

sub format_html {
    my ($text) = @_;

    while ( $text =~ m{ \[\[   # starting marker
                        (\w*)  # alphanumerics and underscores
                        \]\]   # ending marker
                      }x ) {
        my $page = $1;
        my $link = make_link($page);

        $text =~ s{ \[\[ \w* \]\] }{$link}x;
    }

    while ( $text =~ m{ \[     # starting marker
                        (\S+)  # a URL
                        \s+
                        (.*?)  # a link title
                        \]     # ending marker
                      }x ) {
        my $url = $1;
        my $title = $2;
        my $link = make_external_link($url, $title);

        $text =~ s{ \[ \S+ \s+ .*? \] }{$link}x;
    }

    while ( $text =~ m{ ==        # starting marker
                        ([^\n]+)  # anything but a newline
                        ==        # ending marker
                      }msx ) {
        my $heading = $1;
        my $html = "<h2>$heading</h2>";

        $text =~ s{ == [^\n]+ == }{$html}msx;
    }

    while ( $text =~ m{ \&\#039;\&\#039;  # starting marker
                        ([^\n]+?)         # anything but a newline
                        \&\#039;\&\#039;  # ending marker
                      }msx ) {
        my $contained_text = $1;
        my $html = "<em>$contained_text</em>";

        $text =~ s{ \&\#039;\&\#039; [^\n]+ \&\#039;\&\#039; }{$html}msx;
    }

    while ( $text =~ m{ \*         # starting marker
                        ([^\n]+)   # anything but a newline
                        $          # end-of-line
                      }msx ) {
        my $contained_text = $1;
        my $html = "<li>$contained_text</li>";

        $text =~ s{ \* [^\n]+ $ }{$html}msx;
    }

    # NB: This only works when there's only one list on the page.
    $text =~ s{ <li> (.*) </li> }{<ul><li>$1</li></ul>}msx;

    $text =~ s{ \&amp;mdash; }{&mdash;}msxg;

    # Add paragraph tags
    $text =~ s{\n\s*\n}{\n<p>}xg;

    return $text;
}

sub read_page_history {
    my ($page) = @_;

    my $file = $CONTENT_PATH . $page;
    return [] unless -e $file;
    my $page_history = eval( read_file($file) );
    return $page_history;
}

sub write_page_history {
    my ($page, $page_history_ref) = @_;

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    write_file( $CONTENT_PATH . $page, Dumper( $page_history_ref ) );
}

sub read_page {
    my ($page) = @_;

    my $latest_change = read_modification(latest_revision($page));
    return $latest_change->[1];
}

sub latest_revision {
    my ($page) = @_;

    my $page_history = read_page_history($page);
    return unless @$page_history;
    my $latest_revision = shift @$page_history;
    return $latest_revision;
}

sub read_old_page {
    my ($page, $revision) = @_;

    my $page_history = read_page_history($page);
    return unless @$page_history;
    return "" if $revision < 1;
    # we count from the end, so that the oldest revision is number 1
    my $latest_change = read_modification($page_history->[-$revision]);
    return $latest_change->[1];
}

sub modify_page {
    my ($page, $article_text, $tags, $author) = @_;

    my $modification_id = DateTime->now()->epoch();

    my @page_history = @{read_page_history($page)};
    unshift @page_history, $modification_id;
    write_page_history( $page, \@page_history );

    write_modification( $modification_id, [$page, $article_text, $author] );
    add_recent_change( $modification_id, $page, $article_text, $author );

    my $old_tags = read_page_tags($page); 
    remove_tags($page, $old_tags);
    add_tags($page, $tags);

    write_page_tags($page, $tags);
}

sub read_recent_changes {
    return [] unless -e $RECENT_CHANGES_PATH;
    return eval( read_file( $RECENT_CHANGES_PATH ) );
}

sub write_recent_changes {
    my ($recent_changes_ref) = @_;

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    write_file( $RECENT_CHANGES_PATH, Dumper( $recent_changes_ref ) );
}

sub read_modification {
    my ($modification_id) = @_;
    my $file = $MODIFICATIONS_PATH . $modification_id;
    return [] unless -e $file;
    return eval( read_file($file) );
}

sub write_modification {
    my ($modification_id, $modification_ref) = @_;

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    write_file( $MODIFICATIONS_PATH . $modification_id,
                Dumper( $modification_ref ) );
}

sub add_tags {
    my ($page, $tags) = @_;

    return if $tags =~ m/^\s*$/;

    my $count = read_tags_count();
    $tags = tags_parse($tags);

    for my $t (@$tags) {
        if ( $count->{$t} ) {
            $count->{$t}++;
        } 
        else {
            $count->{$t} = 1;
        }
    }

    write_tags_count($count);

    my $index = read_tags_index();

    for my $t (@$tags) {
            unless ( $index->{$t} ) {
                $index->{$t} = {};
            }
            unless ( $index->{$t}{$page} ) {
                $index->{$t}{$page} = 1;
            }
    }
    
    write_tags_index($index);
}

sub remove_tags {
    my ($page, $tags) = @_;

    return if $tags =~ m/^\s*$/;

    my $count = read_tags_count();
    $tags = tags_parse($tags);

    for my $t (@$tags) {
        if ( $count->{$t} && $count->{$t} > 0 ) {
            $count->{$t}--;
        } 
        else {
            $count->{$t} = 0;
        }
    }

    write_tags_count($count);
    
    my $index = read_tags_index();

    for my $t (@$tags) {
        if ( $index->{$t} && $index->{$t}{$page} ) {
            $index->{$t}{$page} = 0;
        } 
    }
    
    write_tags_index($index);
}

sub read_page_tags {
    my $page = shift; 
    my $file = $PAGE_TAGS_PATH . $page;

    return '' unless -e $file;
    return read_file($file);
}

sub write_page_tags {
    my ($page, $tags) = @_;
    my $file = $PAGE_TAGS_PATH . $page;
    write_file( $file, $tags );
}

sub read_tags_count {
    my $file = $TAGS_COUNT_PATH;
    return {} unless -e $file;
    return eval( read_file($file) );
}

sub write_tags_count {
    my $counts = shift; 
    my $file = $TAGS_COUNT_PATH;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    write_file( $file, Dumper($counts) );
}

sub read_tags_index {
    my $file = $TAGS_INDEX_PATH;
    return {} unless -e $file;
    return eval( read_file($file) );
}

sub write_tags_index {
    my $index = shift;
    my $file = $TAGS_INDEX_PATH;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    write_file( $file, Dumper($index) );
}

sub get_tag_count {
    my $tag = shift; 
    my $counts = read_tags_count();
    unless ($counts) {
        warn "Can`t read tags count";
        return 1;
    }
    return $counts->{$tag};
}

sub add_recent_change {
    my ($modification_id, $page, $contents, $author) = @_;

    my @recent_changes = @{read_recent_changes()};
    unshift @recent_changes, # put most recent first
            $modification_id;
    write_recent_changes( \@recent_changes );
}

sub not_found {
    my ($cgi, $page) = @_;

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'not_found.tmpl');

    $template->param(TITLE     => pp($page));
    $template->param(LOGGED_IN => logged_in($cgi));

    print status_not_found(),
          $template->output();

    return;
}

sub logged_in {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $session_id = $cgi->cookie('session_id');
    return $session_id && exists $sessions{$session_id};
}

sub view_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page     = $cgi->param('page') || 'Main_Page';
    my $revision = $cgi->param('revision');

    return not_found($cgi, $page) if !exists_wiki_page($page);

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'view.tmpl');

    $template->param(PAGE      => $page);
    $template->param(TITLE     => pp($page));
    $template->param(VIEW_PAGE => 1) unless $revision;

    my $contents;
    if ( my ($path) = $page =~ m[ ^ $PUGS_PREFIX \b (.*) $ ]x ) {
        if ( -d (my $file = $PUGS_PATH.$path) ) {
            $contents = join '<br/>',
                        map { my $name = substr($_, length($file)+1);
                              make_link( $page.'/'.$name,
                                         $name.(-d $_ ? '/' : '') ); }
                        glob($file.'/*');
        }
        else {
            my $raw_contents = read_file($PUGS_PATH.$path);
            $contents = '<pre>'.escape($raw_contents).'</pre>';
        }
    }
    else {
        my $raw_contents = defined $revision
           ? read_old_page($page, $revision)
           : read_page($page);
        $contents = format_html(escape($raw_contents));
    }
    $template->param(CONTENT => $contents);


    my @page_tags = @{ tags_parse( read_page_tags($page) ) };
    my %tags = %{ read_tags_count() };
    
    use List::Util qw| max min |;
    my $min = min( values %tags );
    my $max = max( values %tags );

    my $page_tags;
    if (@page_tags) {
        @page_tags = map { '<a class="t' 
            . tag_count_normalize( get_tag_count($_), $min, $max ) 
            . '" href="?action=all_pages&tag=' . $_ .'">' 
            . $_ . '</a>' } @page_tags;

        $page_tags = join(', ', @page_tags);
    }

    $template->param('PAGETAGS' => $page_tags);

    # Disable this for now.
#    my $cloud_tags;
#    my @all_tags = keys %tags;
#
#    if (@all_tags) {
#        for (@all_tags) {
#            $cloud_tags .= '<a class="t' 
#                . tag_count_normalize( get_tag_count($_), $min, $max ) 
#                . '" href="?action=all_pages&tag=' . $_ .'">' 
#                . $_ . '</a>'
#        }
#    }
#
    $template->param('TAGS' => undef);
    
    $template->param(LOGGED_IN => logged_in($cgi));

    print status_ok(),
        $template->output();

    return;
}

sub redirect_to_view_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page = $cgi->param('page') or return;

    print $cgi->redirect("http://localhost:8080/?page=$page");

    return;
}

sub edit_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    return not_authorized($cgi) unless logged_in($cgi);

    my $page = $cgi->param('page') or return not_found($cgi, '');

    my $already_exists = exists_wiki_page($page);
    my $action         = $already_exists ? 'Editing'              : 'Creating';
    my $old_content    = $already_exists ? read_page($page)       : '';
    my $old_revision   = $already_exists ? latest_revision($page) : 0;

    # Hmmm... what happens, really, if someone includes a '</textarea>' in the
    # page source?

    if ( my $article_text = $cgi->param('articletext') ) {
        # Check if the page has been saved since editing begun, and pull the
        # brakes if it has.
        if ( $cgi->param('old-revision') < latest_revision($page) ) {
            my $template = HTML::Template->new(
                filename => $TEMPLATE_PATH.'page_too_old.tmpl');

            $template->param(PAGE => $page);
            $template->param(TITLE => pp($page));
            $template->param(LOGGED_IN => logged_in($cgi));

            print status_ok(),
                  $template->output();

            return;
        }

        my $session_id = $cgi->cookie('session_id');
        my $author = $sessions{$session_id}{user_name};
        my $tags = $cgi->param('tags');
        modify_page( $page, $article_text, $tags, $author );

        return view_page($cgi);
    }

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'edit.tmpl');

    $template->param(PAGE => $page);
    $template->param(ACTION => $action);
    $template->param(TITLE => pp($page));
    $template->param(PAGETAGS => read_page_tags($page));
    $template->param(CONTENT => $old_content);
    $template->param(OLD_REV => $old_revision);
    $template->param(LOGGED_IN => logged_in($cgi));

    print status_ok(),
          $template->output();
}

sub not_authorized {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'action_not_authorized.tmpl');

    $template->param(DISALLOWED_ACTION => 'edit pages');

    print status_ok(),
          $template->output();

    return;
}

sub view_history {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page = $cgi->param('page') or return not_found($cgi, '');
    return not_found($cgi, $page) if !exists_wiki_page($page);

    my @page_history = @{read_page_history($page)};

    my @changes;
    my $revision = @page_history;
    for my $modification_id (@page_history) {
        my $modification = read_modification($modification_id);
        push @changes, { view_link => make_old_href($page, $revision),
                         diff_link => make_diff_href($page, $revision-1, $revision),
                         time => $modification_id,
                         author => $modification->[2] || 'somebody' };
        --$revision;
    }

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'page_history.tmpl');

    $template->param(PAGE      => $page);
    $template->param(TITLE     => pp($page));
    $template->param(CHANGES   => \@changes);
    $template->param(LOGGED_IN => logged_in($cgi));

    print status_ok(),
          $template->output();
}

sub ins { my ($type, $change) = @_; $type eq '+' ? $change : '' };
sub del { my ($type, $change) = @_; $type eq '-' ? $change : '' };

sub view_diff {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page         = $cgi->param('page') or return not_found($cgi, '');
    my $old_revision = $cgi->param('old_revision');
    my $new_revision = $cgi->param('new_revision');

    return not_found($cgi, $page) if !exists_wiki_page($page);

    my @old_contents = split("\n", read_old_page($page, $old_revision));
    my @new_contents = split("\n", read_old_page($page, $new_revision));

    use Algorithm::Diff qw(diff);
    my @changes = map { {'indels' => [
                             map { { insertion => ins( $_->[0], $_->[2] ),
                                     deletion  => del( $_->[0x], $_->[2] ),
                                   } } @$_
                         ] }
                  } diff(\@old_contents, \@new_contents);

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'view_diff.tmpl');

    $template->param(PAGE      => $page);
    $template->param(TITLE     => pp($page));
    $template->param(HUNKS     => \@changes);
    $template->param(LOGGED_IN => logged_in($cgi));

    print status_ok(),
        $template->output();

    return;
}

sub read_users {
    return [] unless -e $USERFILE_PATH;
    return eval( read_file( $USERFILE_PATH ) );
}

sub log_in {
    my ($cgi) = @_;
    return if !ref $cgi;

    if ( my $user_name = $cgi->param('user_name') ) {
        my $password = $cgi->param('password');

        my %users = %{read_users()};

        if ( md5_base64(md5_base64($user_name).$password)
             eq $users{$user_name}->{password} ) {

            my $template = HTML::Template->new(
                filename => $TEMPLATE_PATH.'login_succeeded.tmpl'
            );
            $template->param(LOGGED_IN => 1);

            my $session_id = md5_base64(time);
            my $session_cookie = $cgi->cookie(
                -name    => 'session_id',
                -value   => $session_id,
                -expires => '+1h'
            );

            $sessions{$session_id} = {
                'user_name' => $user_name,
            };

            print "HTTP/1.0 200 OK\r\n",
                  $cgi->header( -cookie => $session_cookie ),
                  $template->output();

            return;
        }

        my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'login_failed.tmpl');

        print status_ok(),
              $template->output();

        return;
    }

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'log_in.tmpl');

    print status_ok(),
        $template->output();

    return;
}

sub log_out {
    my ($cgi) = @_;
    return if !ref $cgi;

    if ( defined $cgi->cookie('session_id') ) {
        my $template = HTML::Template->new(
                filename => $TEMPLATE_PATH.'logout_succeeded.tmpl');

        my $session_id = $cgi->cookie('session_id');
        delete $sessions{$session_id};

        my $session_cookie = $cgi->cookie(
            -name    => 'session_id',
            -value   => '',
        );

        print "HTTP/1.0 200 OK\r\n",
              $cgi->header( -cookie => $session_cookie ),
              $template->output();

        return;
    }

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'logout_succeeded.tmpl');

    print status_ok(),
        $template->output();

    return;
}

sub list_recent_changes {
    my ($cgi) = @_;
    return if !ref $cgi;

    my @recent_changes = @{read_recent_changes()};

    my @changes;
    for my $modification_id (@recent_changes) {
        my $modification = read_modification($modification_id);
        push @changes, { page => make_link( $modification->[0] ),
                         time => $modification_id,
                         author => $modification->[2] || 'somebody' };
    }

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'recent_changes.tmpl');

    $template->param(CHANGES => \@changes);
    $template->param(LOGGED_IN => logged_in($cgi));

    print status_ok(),
          $template->output();
}

sub list_all_pages {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'view.tmpl');

    my %tags = %{ read_tags_count() };
    
    use List::Util qw| max min |;
    my $min = min( values %tags );
    my $max = max( values %tags );

    my $cloud_tags;
    my @all_tags = keys %tags;

    if (@all_tags) {
        for (@all_tags) {
            $cloud_tags .= '<a class="t' 
                . tag_count_normalize( get_tag_count($_), $min, $max ) 
                . '" href="?action=all_pages&tag=' . $_ .'">' 
                . $_ . '</a>'
        }
    }

    $template->param('TAGS' => $cloud_tags);

    my $tag = $cgi->param('tag');
    my @articles;

    if ($tag) {
        my %tags_index = %{ read_tags_index() };
        @articles = keys %{ $tags_index{$tag} };      
        $template->param(TITLE => qq[Articles with tag "$tag"]);
    } else {
        opendir(my $content_dir, $CONTENT_PATH)
            or die "can`t open $CONTENT_PATH -- $!";
        @articles = grep { $_ ne '.' && $_ ne '..' } readdir($content_dir);
        closedir($content_dir);
        $template->param(TITLE => "All pages");
    }
 
    my $list = '<ul>';
    for my $article (@articles) {
        $list .= "<li><a href='?action=view&page=$article'>$article</a></li>"; 
    }
    $list .= '</ul>';
    if ($tag) {
        $list .= '<a href="?action=all_pages">List all articles</a>';
    }

    $template->param(CONTENT => $list);
    $template->param(LOGGED_IN => logged_in($cgi));

    print status_ok(),
          $template->output();
}

sub tags_parse { [ split /\s*[,\n]\s*/, lc(shift) ] }

sub tag_count_normalize {
    my ($count, $min, $max) = @_;
    my $step = ($count - $min) / (($max - $min) || 1);
    use POSIX;
    ceil( ( log($step + 1 ) * 10 ) / log 2 ); 
}

1;
