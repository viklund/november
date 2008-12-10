use v6;
class Dispatcher;

use Dispatcher::Rule;

has @.rules;
has $.default is rw;

#multi method add ($rule) {
method add ($rule) {
    die "Only complete rules allowed" unless $rule.?is_complete;
    @!rules.push($rule);
}

#multi method add (@tokens, $action){
method add_rule (@tokens, $action) {
    my $rule = Dispatcher::Rule.new( tokens => @tokens.list, action => $action );
    @!rules.push($rule);
}

# I think a Hash might be better here, but Rakudo converts all hash keys
# into Str
method add_rules(@rules) {
    # RAKUDO: rakudo doesn't know return values in for loops yet
    my $r;
    for @rules.list -> $tokens, $action {
        $r = self.add_rule([$tokens.list], $action);
    }
    return $r;
}

method dispatch (@chunks) {
    my @matched =  @!rules.grep: { .match(@chunks) };    

    if @matched {
        my $result = @matched.end.apply;
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
