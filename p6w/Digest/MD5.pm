use v6;

# The following pseudocode lifted from Wikipedia.
#
# //Note: All variables are unsigned 32 bits and wrap modulo 2^32 when calculating
# var int[64] r, k
# 
# //r specifies the per-round shift amounts
# r[ 0..15] := {7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22} 
# r[16..31] := {5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20}
# r[32..47] := {4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23}
# r[48..63] := {6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21}
# 
# //Use binary integer part of the sines of integers (Radians) as constants:
# for i from 0 to 63
#     k[i] := floor(abs(sin(i + 1)) × (2 pow 32))
# 
# //Initialize variables:
# var int h0 := 0x67452301
# var int h1 := 0xEFCDAB89
# var int h2 := 0x98BADCFE
# var int h3 := 0x10325476
# 
# //Pre-processing:
# append "1" bit to message
# append "0" bits until message length in bits ≡ 448 (mod 512)
# append bit /* bit, not byte */ length of unpadded message as 64-bit
#   little-endian integer to message
# 
# //Process the message in successive 512-bit chunks:
# for each 512-bit chunk of message
#     break chunk into sixteen 32-bit little-endian words w[i], 0 ≤ i ≤ 15
# 
#     //Initialize hash value for this chunk:
#     var int a := h0
#     var int b := h1
#     var int c := h2
#     var int d := h3
# 
#     //Main loop:
#     for i from 0 to 63
#         if 0 ≤ i ≤ 15 then
#             f := (b and c) or ((not b) and d)
#             g := i
#         else if 16 ≤ i ≤ 31
#             f := (d and b) or ((not d) and c)
#             g := (5×i + 1) mod 16
#         else if 32 ≤ i ≤ 47
#             f := b xor c xor d
#             g := (3×i + 5) mod 16
#         else if 48 ≤ i ≤ 63
#             f := c xor (b or (not d))
#             g := (7×i) mod 16
#  
#         temp := d
#         d := c
#         c := b
#         b := b + leftrotate((a + f + k[i] + w[g]) , r[i])
#         a := temp
# 
#     //Add this chunk's hash to result so far:
#     h0 := h0 + a
#     h1 := h1 + b 
#     h2 := h2 + c
#     h3 := h3 + d
#
# var int digest := h0 append h1 append h2 append h3 //(expressed as little-endian)
#
#   //leftrotate function definition
#   leftrotate (x, c) 
#       return (x << c) or (x >> (32-c)); 


class Digest::MD5 {

    # The empty string should give d41d8cd98f00b204e9800998ecf8427e
    sub md5_base64($text) {
        my @r;
        my @k;

        @r = (7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
              5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
              4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
              6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21);

        for 0 .. 63 -> $i {
            @k[$i] = floor(abs(sin( $i + 1 ))) * (2 ** 32);
        }

        my $h0 = '67452301';
        my $h1 = 'EFCDAB89';
        my $h2 = '98BADCFE';
        my $h3 = '10325476';

        my @m = string_to_bits($text);
        my $l = @m.elems;

        push @m, 1;
        while @m.elems % 512 != 448 {
            push @m, 0;
        }
        push @m, int_to_bits($l, 64);

        for chunks(@m, 512) -> @chunk {
            my @w = to_words(@chunk, 32);

            my $a = $h0;
            my $b = $h1;
            my $c = $h2;
            my $d = $h3;

            for 0 .. 63 -> $i {
                my $f;
                my $g;
                if 0 <= $i <= 15 {
                    $f = ($b +& $c) +| (+^$b +& $d);
                    $g = $i;
                }
                elsif 16 <= $i <= 31 {
                    $f = ($d +& $b) +| (+^$d +& $c);
                    $g = (5 * $i + 1) % 16;
                }
                elsif 32 <= $i <= 47 {
                    $f = $b +^ $c +^ $d;
                    $g = (3 * $i + 5) % 16;
                }
                elsif 48 <= $i <= 63 {
                    $f = $c +^ ($b +| +^$d);
                    $g = (7 * $i) % 16;
                }

                my $temp = $d;
                $d = $c;
                $c = $b;
                $b += left_rotate( $a + $f + @k[$i] + @w[$g], @r[$i] );
                $a = $temp;
            }

            $h0 += $a;
            $h1 += $b;
            $h2 += $c;
            $h3 += $d;
        }

        # RAKUDO: Would be nicer to use map and [~].
        return to_base64($h0)
             ~ to_base64($h1)
             ~ to_base64($h2)
             ~ to_base64($h3);
    }

    sub leftrotate($x, $c) {
        return ($x +< $c) +| ($x +> (32 - $c));
    }

    sub string_to_bits($s) {
        my @bits;
        for 0 .. $s.chars -> $pos {
            push @bits, int_to_bits( Future::ord( substr($s, $pos, 1) ), 8 );
        }
        return @bits;
    }

    sub int_to_bits($i, $n) {
        my @bits;
        for 0 .. $n {
            push @bits, $i % 2;
            $i +> 1;
        }
        return @bits;
    }

    sub chunks(@a, $l) {
        my @chunks;
        while @a {
            my @c;
            for ^$l {
                push @c, @a.pop;
            }
            push @chunks, @c;
        }
        return @chunks;
    }

    sub to_words(@a, $l) {
        my @chunks = chunks(@a, $l);
        my @words;
        for @chunks -> @chunk {
            my $word = 0;
            for @chunk -> $bit {
                $word *= 2;
                $word += $bit;
            }
            push @words, $word;
        }
        return @words;
    }
}
