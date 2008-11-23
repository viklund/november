use v6;
class Dispatcher;

has @.rules;
has $.default is rw;

#multi method add ($rule) {
method add ($rule) {
    die "Only complete rules allowed" unless $rule.?is_complete;
    @!rules.push($rule);
}

#multi method add (@tokens, $way){
method add_rule (@tokens, $way) {
    use Dispatcher::Rule;
    my $rule = Dispatcher::Rule.new( tokens => @tokens.list, way => $way );
    @!rules.push($rule);
}

# I think a Hash might be better here, but Rakudo converts all hash keys
# into Str
method add_rules(@rules) {
    use Dispatcher::Rule;
    # RAKUDO: this method returns an Iterator, workaround:
    my $r;
    for @rules.list -> $tokens, $way {
        $r = self.add_rule([$tokens.list], $way);
    }
    return $r;
}

method dispatch (@chunks) {
    # RAKUDO: grep make closure
    #my @matched =  @!rules.grep: { .match(@chunks) };    
    # so workaround:

    my @matched;
    for @!rules -> $r {
        @matched.push($r) if $r.match(@chunks);
    }
    #say "Applicable:" ~ @applyable;

    if @matched {
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
