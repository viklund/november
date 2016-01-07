use v6;

use Test;
use November;
use Test::CGI;
use November::Config;
use November::URI;

my @markups = < Text::Markup::Wiki::MediaWiki >;
my @skins   = < CleanAndSoft >;

my %gets    = {
    #''                  =>  'View main page',
    '/view/Main_Page'   =>  'View specific page',
    '/view/Snrsdfda'    =>  'View unexisting page',
    '/in'               =>  'Log in page',
    '/out'              =>  'Log out page',
    '/recent'           =>  'Recent changes',
    '/all'              =>  'All pages',
    '/all?tag=november' =>  'All pages, specific tag',
};

plan @markups * @skins * %gets;

for @markups X @skins -> $m, $s {
    my $c = November::Config.new( markup => ::($m), skin => $s );
    my $w = November.new( config => $c );
    for %gets.kv -> $page, $description {
        my $uri = November::URI.new( uri => 'http://testserver' ~ $page );
        my $cgi = Test::CGI.new( uri => $uri );
        $cgi.parse_params( $page );
        lives-ok( { $w.handle_request( $cgi ) }, "$m, $s, $description" );
    }
}

# vim:ft=perl6
