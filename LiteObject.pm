package Data::JavaScript::LiteObject;
local $^W = 0; #cheat, to bypass warning about uninitialized var below...
*{"${@{[caller()]}}::jsodump"} = \&{"Data::JavaScript::LiteObject::jsodump"};
use strict;
use vars qw($VERSION);
$VERSION = '1.00';

sub jsodump {
    my %opts = (@_);
    my(@keys, $obj, @objs, $EOL, $EOI, @F);

    unless( $opts{protoName} && $opts{dataRef} ){
	warn("// Both protoName and dataRef must be supplied");
	return; }


    if( $opts{explode} ){
	$EOI = $EOL = "\n\t"; }
    else{
	$EOI = '';
	$EOL = " "; }


    if( ref($opts{dataRef}) eq "ARRAY" ){
	my %F;
	for(my $i=0; $i < scalar @{$opts{dataRef}}; $i++){
		$F{"$opts{protoName}$i"} = $opts{dataRef}->[$i]; }
	$opts{dataRef} = \%F; }
    if( ref($opts{dataRef}) eq "HASH" ){
	if( ref($opts{attributes}) eq "ARRAY" ){
	    @keys = @{$opts{attributes}}; }
	else{
	    @keys = sort { $a cmp $b } keys %{$opts{dataRef}->{(each%{$opts{dataRef}})[0]}}; }
    }
    else{
	warn("// Unknown reference type"); return; }

    push @F, "function $opts{protoName} (", join(', ', @keys) ,") {\n\t";
    push @F, map("this.$_ = $_;$EOL", @keys);    
    push @F, "}\n";

    foreach $obj ( sort{ $a cmp $b } keys %{$opts{dataRef}} ){
	push @F, "$obj = new $opts{protoName}($EOI";
	my $k=1;
	foreach my $key ( @keys ) {
	    my $delim = $k++ < scalar @keys ? ',' : '';
	    
	    if( ref($opts{dataRef}->{$obj}->{$key}) eq "ARRAY" ){
		push @F, "new Array(",
		 join(',', map(datum($_), @{$opts{dataRef}->{$obj}->{$key}})) ,")$delim$EOL"; }
	    else{
		push @F, datum($opts{dataRef}->{$obj}->{$key}), "$delim$EOL"; }
	}
	push @F, ");\n";
	push @objs, $obj;
    }

    if( defined($opts{listObjects}) ){
	push @F, "$opts{listObjects} = new Array($EOI",
	 join(",$EOL", map("'$_'", @objs)), ");\n"; }

    if( $opts{lineIN} ){
	local $. = $opts{lineIN}+1;
	@F = split(/\n/, join('', @F));
	foreach my $line ( @F ){
	    $.++;
	    if( ($.-$opts{lineIN}) %5 == 0){
		$.++;
		$line =~ s%$%\n// $.\n%; }
	    else{
		$line =~ s%$%\n%; }
	}
	${$opts{lineOUT}} = $.;
	unshift @F, "// ".($opts{lineIN}+1)."\n";
    }
    return @F;
}

sub datum {
    my $val = shift();
    if( $val !~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ ){
	$val =~ s/'/\\'/g;
	return qq('$val'); }
    return $val;
}

1;
__END__

=head1 NAME

Data::JavaScript::LiteObject - Perl package to provide lightweight data dumping

=head1 SYNOPSIS

    use Data::JavaScript:LiteObject;

    jsodump("user", \%users);

=head1 DESCRIPTION

This module was inspired by L<Data::JavaScript>, which while incredibly
versatile, seems rather brute force and inelegant for certain forms
of data. Specifically a series of objects of the same class, which it
seems is a likely use for this kind of feature. So this module was
created to provide a lightweight means of producing configurable, clean
and compact output.

B<LiteObject> is used to format and output an array or hash of objects;
that is hash references. The referenced hashes may contain values that
are scalars, or references to arrays containing scalars.

B<LiteObject> contains one function; jsodump; which takes a list of named
parameters. Two of which are required, the rest being optional.

=head2 Required parameters

=over 4

=item C<protoName>

The name to be used for the prototype object function.

=item C<dataRef>

A reference to an array or hash of hashes to dump.

=back

=head2 Optional parameters

=over 4

=item C<attributes>

A reference to an array containing a list of the object attributes
(hash keys). This is useful if every object does not necessarily
posses a value for each attributes; C<exists> fails. e.g.

        %A = (a=>1, z=>26);
        %B = (b=>2, y=>25);

        jsodump("example", \(%A, %B), \('a', 'b', 'y', 'z'));

This could also be used to explicitly prevent certain data from being dumped.

=item C<explode>

The default; false; produces output with one I<object> per line.
If true, the output is one I<attribute> per line.

=item C<lineIN>

If true, output is numbered every 5 lines. The value provided
should be the number of lines printed before this output.
For example if a CGI script included:

    C<print q(<html>
	    <head>
	    <title>Pthbb!!</title>
	    <script language=javascript>);>
    jsdump(protoName=>"object", dataRef=>\@objects, lineIN=>4);

The client might see:

    <html>
    <head>
    <title>Pthbb!!</title>
    <script language=javascript>
    // 5
    function object (x, y, z) {
            this.x = x; this.y = y; this.z = z; }
    object0 = new object(1, 0, 0 );
    object1 = new object(0, 1, 0 );
    // 10
    object2 = new object(0, 0, 1 );

making it easier to read and/or debug.

=item C<lineOUT>

A scalar reference. jsodump will set it's value to the number of the last
line of numbered output produced when lineIN is specified. This way you
may pass the scalar to a subsequent call to jsdump as the value of lineIn
for continuous numbering.
For example:

    C<jsdump(protoName=>"object", dataRef=>\@objects, lineIN=>4, lineOUT=>\$.);>

    ...

    C<jsdump(protoName=>"object", dataRef=>\@objects, lineIN=>$.);>

=item C<listObjects>

If true, the parameters value is used as the name of an array to be output
contaning a list of all the objects dumped. This way, your client side
code need not know as much about the data, but simply to traverse an
array of your choosing.

For example:

    C<jsdump(protoName=>"object", dataRef=>\@objects, listObjects=>"objects");>

would return

    objects = new Array('object0', 'object1', 'object2');

=back

=head1 CAVEATS

All of the objects in a given hash or array reference should contain
the same keys. Explicit undefined values should be used for instances
of an object that do not posess a certain value.
For example:

    C<%hash0 = (alpha=>undef, beta=>1);>
    C<%hash1 = (beta=>1);>

%hash0 is safe, since exists($hash0{alpha}) is true.
However exists($hash1{alpha}) is false, and %hash1 would cause problems.

Deep structures are not dumped. That is anything beyond a scalar or
a scalar within an Array as an attribute value. It is not entirely
clear that it's necessary, but if you require it L<SEE ALSO>

=head1 BUGS

Nothing that am I aware of.

=head1 SEE ALSO

L<Data::JavaScript>

=head1 AUTHOR

Jerrad Pierce I<belg4mit@mit.edu>, I<webmaster@pthbb.org>.
F<http://pthbb.org/>

=cut
