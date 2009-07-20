package MooseX::Getopt::Defanged::OptionTypeMetadata;

use 5.010;
use utf8;

use Moose;
use Moose::Util::TypeConstraints qw< find_type_constraint >;
use MooseX::AttributeHelpers;
use MooseX::Accessors::ReadWritePrivate;
use MooseX::StrictConstructor;


use version; our $VERSION = qv('v1.14.1');


use MooseX::Getopt::Defanged::Exception::InvalidSpecification
    qw< throw_invalid_specification >;


has _default_specifications => (
    metaclass   => 'Collection::Hash',
    isa         => 'HashRef[Str]',
    is          => 'ro',
    required    => 1,
    init_arg    => undef,   # Cannot be specified in constructor call.
    default     => \&_get_initial_default_specifications,
    provides    => {
        set     => 'set_default_specification',
        delete  => 'delete_default_specification',
    },
    reader      => '_get_default_specifications',
);

has _default_value_generators => (
    metaclass   => 'Collection::Hash',
    isa         => 'HashRef[CodeRef]',
    is          => 'ro',
    required    => 1,
    init_arg    => undef,   # Cannot be specified in constructor call.
    default     => \&_get_initial_default_value_generators,
    provides    => {
        set     => 'set_default_value_generator',
    },
    reader      => '_get_default_value_generators',
);


__PACKAGE__->meta()->make_immutable();


sub _get_initial_default_specifications {
    my %base_defaults = (
        'Bool'                  => q<>,
        'Str'                   => '=s',
        'Int'                   => '=i',
        'Num'                   => '=f',
        'ArrayRef'              => '=s{1,}',
        'ArrayRef[Str]'         => '=s{1,}',
        'ArrayRef[Int]'         => '=i{1,}',
        'ArrayRef[Num]'         => '=f{1,}',
        'HashRef'               => '=s%',
        'HashRef[Str]'          => '=s%',
        'HashRef[Int]'          => '=i%',
        'HashRef[Num]'          => '=f%',
    );

    my %defaults;
    while ( my ($type, $specification) = each %base_defaults ) {
        $defaults{$type} = $specification;
        $defaults{"Maybe[$type]"} = $specification;
    } # end while

    return \%defaults;
} # end _get_initial_default_specifications()


sub _get_initial_default_value_generators {
    my $array_ref_generator = sub { [] };
    my $hash_ref_generator = sub { {} };
    my %base_defaults = (
        'ArrayRef'              => $array_ref_generator,
        'ArrayRef[Str]'         => $array_ref_generator,
        'ArrayRef[Int]'         => $array_ref_generator,
        'ArrayRef[Num]'         => $array_ref_generator,
        'HashRef'               => $hash_ref_generator,
        'HashRef[Str]'          => $hash_ref_generator,
        'HashRef[Int]'          => $hash_ref_generator,
        'HashRef[Num]'          => $hash_ref_generator,
    );

    my %defaults;
    while ( my ($type, $generator) = each %base_defaults ) {
        $defaults{$type} = $generator;
        $defaults{"Maybe[$type]"} = $generator;
    } # end while

    return \%defaults;
} # end _get_initial_default_specifications()


sub get_default_specification {
    my ($self, $type_name) = @_;

    my $specifications = $self->_get_default_specifications();

    return $specifications->{$type_name}
        if exists $specifications->{$type_name};

    my $current_type = find_type_constraint($type_name)
        or throw_invalid_specification qq<There's no "$type_name" type.>;

    while ( $current_type = $current_type->parent() ) {
        my $current_name = $current_type->name();
        return $specifications->{$current_name}
            if exists $specifications->{$current_name};
    } # end while

    return;
} # end get_default_specification()


sub get_default_value_generator {
    my ($self, $type_name) = @_;

    my $value_generators = $self->_get_default_value_generators();

    return $value_generators->{$type_name}
        if exists $value_generators->{$type_name};

    my $current_type = find_type_constraint($type_name)
        or throw_invalid_specification qq<There's no "$type_name" type.>;

    while ( $current_type = $current_type->parent() ) {
        my $current_name = $current_type->name();
        return $value_generators->{$current_name}
            if exists $value_generators->{$current_name};
    } # end while

    return;
} # end get_default_value_generator()


no Moose;
no Moose::Util::TypeConstraints;


1;

__END__

=encoding utf8

=for stopwords metadata

=head1 NAME

MooseX::Getopt::Defanged::OptionTypeMetadata - Bookkeeping of option type metadata L<MooseX::Getopt::Defanged>.


=head1 SYNOPSIS

    package Some::Program;

    use Moose;

    with qw< MooseX::Getopt::Defanged >;


    sub run {
        my ($self, $argv_ref) = @_;

        $self->_configure($argv_ref);

        ...
    } # end run()


    sub _configure {
        my ($self, $argv_ref) = @_;

        my $metadata = $self->get_option_type_metadata();
        $metadata->set_default_specification(Bool   => '!');
        $metadata->set_default_specification(Int    => '=o');
        $metadata->set_default_specification(Str    => ':s');
        $metadata->set_default_specification(MyType => '=s{2,3}');

        $metadata->set_default_value_generator(Int => sub { 5 });

        $self->parse_command_line($argv_ref);

        ...

        return;
    } # end _configure()


=head1 VERSION

This document describes MooseX::Getopt::Defanged::OptionTypeMetadata version
1.14.1.


=head1 DESCRIPTION

This is a holder of metadata about L<Moose> types for
L<MooseX::Getopt::Defanged>.  For example, it keeps track of what the default
L<Getopt::Long> specification should be for a given type.

This contains default mappings for the following types:

    Type                   Specification
    -------------          -------------
    Bool                   «empty»
    Str                    =s
    Int                    =i
    Num                    =f
    ArrayRef               =s{1,}
    ArrayRef[Str]          =s{1,}
    ArrayRef[Int]          =i{1,}
    ArrayRef[Num]          =f{1,}
    HashRef                =s%
    HashRef[Str]           =s%
    HashRef[Int]           =i%
    HashRef[Num]           =f%

Also, for each type, "Maybe[«type»]" uses the same specification.


=head1 INTERFACE

=over

=item C<get_default_specification($type)>

Given a type name, returns the default L<Getopt::Long> specification for the
type, if there is one.


=item C<< set_default_specification($type => $specification) >>

Sets the default L<Getopt::Long> specification for options of the given type.
Use this to override the defaults or to specify a default for a type you
created via L<Moose>'s C<subtype> mechanism.


=item C<delete_default_specification($type)>

Removes any default specification for the given type (because the empty string
is a valid specification).


=item C<get_default_value_generator($type)>

Given a type name, returns a code reference that can provide a default value
for an option of the given type, if there is one.


=item C<< set_default_value_generator( $type => sub { ... } ) >>

Sets the generator of default values for options of the given type.  The
subroutine will get no arguments.  Use this to override the defaults or to
specify a default for a type you created via L<Moose>'s C<subtype> mechanism.


=back


=head1 DIAGNOSTICS

If you specify an attribute type that this class doesn't understand, a
L<MooseX::Getopt::Defanged::Exception::InvalidSpecification> will be thrown
with the message C<There's no "$type_name" type.>.


=head1 CONFIGURATION AND ENVIRONMENT

See L<MooseX::Getopt::Defanged>.


=head1 DEPENDENCIES

perl 5.10

L<Moose>

L<Moose::Util::TypeConstraints>

L<MooseX::Accessors::ReadWritePrivate>

L<MooseX::AttributeHelpers>

L<MooseX::StrictConstructor>


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2008-2009, Elliot Shank


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 encoding=utf8 :
