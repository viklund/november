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
        # The following line of code is in relatively high flux, due to
        # changes in the Spec and Rakudo when it comes to handling of
        # typed arrays etc. For a long time, it said 'Object @pattern',
        # in order to prevent autothreading on the elements of @pattern.
        # (Object, as opposed to Any, causes signature bindings not to
        # autothread.) However, (a) this typing might not be needed, because
        # 'Object' might actually be the default, and (b) in current
        # versions of Rakudo, writing 'Object @pattern' wrongly causes
        # the Array not to bind, despite the fact that any Array should.
        for @rules -> @pattern, $action {
            self.add(@pattern, $action);
        }
        return @.rules.elems;
    }

    method dispatch (@chunks) {
        my @matched =  @!rules.grep: { .match(@chunks) };    
        
        if @matched {
            my $result = @matched[*-1].apply;
            .clear for @!rules; 
            return $result;
        }
        elsif defined $.default {
            $.default().();
        }
        else {
            return Failure;
        }
    }
}

# vim:ft=perl6
