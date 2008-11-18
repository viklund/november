use v6;
class Dispatcher;

has @.rules;
has $.default is rw;

#multi method add ($rule) {
method add ($rule) {
    die "Only complite rules accepteable there." unless $rule.?is_complite;
    @!rules.push($rule);
}

#multi method add (@tokens, $way){
method add_rule (@tokens, $way) {
    use Dispatcher::Rule;
    my $rule = Dispatcher::Rule.new( tokens => @tokens.values, way => $way );
    @!rules.push($rule);
}

method dispatch (@chunks) {
    # that make clsure:
    #my @matched =  @!rules.grep: { .match(@chunks) };    
    # so workaround:

    my @matched;
    for @!rules -> $r {
        @matched.push($r) if $r.match(@chunks);
    }
    #say "Applyable:" ~ @applyable;

    if @matched {
        my $result = @matched[-1].apply;
        .clear for @!rules; 
        return $result;
    }
    elsif $.default {
        $.default();
    }
    else {
        return False;
    }
}

# vim:ft=perl6
