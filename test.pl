# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::JavaScript::LiteObject;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
%A = (a=>1, z=>26);
%B = (b=>2, y=>25);
@F = (\%A, \%B);
@attrib = ('a', 'b', 'y', 'z');
$results = jsodump(protoName=>"example", dataRef=>\@F, attributes=>\@attrib);
$A{b} = $A{y} = $B{a} = $B{z} = undef;
if( $results eq jsodump(protoName=>"example", dataRef=>\@F) ){
    print "ok 2\n"; }
else{
    print "not ok 2\n"; }
