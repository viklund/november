class Dispatcher {
    use Dispatcher::Rule;

    has @.rules;
    has $.default is rw;

    multi method add (Dispatcher::Rule $rule) {
        die "Only complete rules allowed" unless $rule.?is_complete;
        @!rules.push($rule);
    }

    multi method add (@pattern, Code $code) {
        my $rule = Dispatcher::Rule.new( pattern => @pattern, code => $code );
        @!rules.push($rule);
    }

    multi method add (@rules) {
        # RAKUDO: rakudo doesn't know return values in for loops yet
        my $r;
        # RAKUDO: Larry -- "the default parameter to a block is now Object and 
        # not Any" but this is NIY 
        for @rules -> Object @pattern, $action {
            $r = self.add(@pattern, $action);
        }
        return $r;
    }

    method dispatch (@chunks) {
        my @matched =  @!rules.grep: { .match(@chunks) };    
        
        if @matched {
            my $result = @matched[*-1].apply;
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
}

# vim:ft=perl6
