class Dispatcher {
    use Dispatcher::Rule;

    has @.rules;
    has $.default is rw;

    multi method add (Dispatcher::Rule $rule) {
        die "Only complete rules allowed" unless $rule.?is_complete;
        @!rules.push($rule);
    }

    multi method add (@pattern, $action) {
        my $rule = Dispatcher::Rule.new( pattern => @pattern, action => $action );
        @!rules.push($rule);
    }

    # I think a Hash might be better here, but Rakudo converts all hash keys
    # into string now
    method add_rules(@rules) {
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
