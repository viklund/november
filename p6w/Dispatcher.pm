use v6;
class Dispatcher;

use Dispatcher::Rule;

has @.rules;
has $.default is rw;

multi method add (Dispatcher::Rule $rule) {
    die "Only complete rules allowed" unless $rule.?is_complete;
    @!rules.push($rule);
}

multi method add (@tokens, $action){
    my $rule = Dispatcher::Rule.new( tokens => @tokens.list, action => $action );
    @!rules.push($rule);
}

# I think a Hash might be better here, but Rakudo converts all hash keys
# into string now
method add_rules(@rules) {
    # RAKUDO: rakudo doesn't know return values in for loops yet
    my $r;
    for @rules.list -> $tokens, $action {
        $r = self.add([$tokens.list], $action);
    }
    return $r;
}

method dispatch (@chunks) {
    my @matched =  @!rules.grep: { .match(@chunks) };    

    if @matched {
        # RAKUDO: [*-1] not implemented yet, but [-1] works like in p5
        my $result = @matched[-1].apply;
        .clear for @!rules; 
        return $result;
    }
    elsif defined $.default {
        $.default();
    }
    else {
        return Failure;
    }
}

# vim:ft=perl6
