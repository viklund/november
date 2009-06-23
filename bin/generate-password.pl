use v6;

use Digest;

if ( @*ARGS.elems != 2 ) {
    say 'This program expects two arguments, the first one should be the';
    say 'username of the new user and the second one should be the passphrase';
    say 'of the new user.';
    say "\nThank You";
    exit 1;
}

my ($username, $passphrase) = @*ARGS;

say "The hashed passphrase for $username is:";
say "  ", digest( digest( $username, 'sha256' ) ~ $passphrase, 'sha256');

# vim: ft=perl6
