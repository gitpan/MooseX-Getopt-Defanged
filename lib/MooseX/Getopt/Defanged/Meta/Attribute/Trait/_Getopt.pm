package MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt;

use 5.010;
use utf8;

use Moose::Role;
use Moose::Util::TypeConstraints;

use version; our $VERSION = qv('v1.14.0');


use MooseX::Getopt::Defanged::Exception::InvalidSpecification
    qw< throw_invalid_specification >;


subtype '_MooseX_Getopt_Defanged_Aliases' => as 'ArrayRef[Str]';

coerce '_MooseX_Getopt_Defanged_Aliases'
    => from 'Str'
    => via { [$_] };


# This will be the key as returned by Getopt::Long.  By default, the
# attribute's regular name will be used, but you can override that using this.
has getopt_name => (
    isa         => 'Str',
    is          => 'ro',
    required    => 0,
    reader      => 'get_getopt_name',
    writer      => 'set_getopt_name',
);

# Alternate names for the option.
has getopt_aliases => (
    isa         => '_MooseX_Getopt_Defanged_Aliases',
    is          => 'ro',
    required    => 0,
    reader      => 'get_getopt_aliases',
    writer      => 'set_getopt_aliases',
);

# Override the standard attribute type.
has getopt_type => (
    isa         => 'Str',
    is          => 'ro',
    required    => 0,
    reader      => 'get_getopt_type',
    writer      => 'set_getopt_type',
);

# Override of what this Role will normally derive for this attribute for the
# specification, but without the name part.
has getopt_specification => (
    isa         => 'Str',
    is          => 'ro',
    required    => 0,
    reader      => 'get_getopt_specification',
    writer      => 'set_getopt_specification',
);

# Is this option required to show up on the command line?  I.e. it's not an
# option but an argument.
has getopt_required => (
    isa         => 'Bool',
    is          => 'ro',
    required    => 0,
    default     => sub { 0 },
    reader      => 'is_getopt_required',
    writer      => 'set_getopt_required',
);


no Moose::Role;


sub get_actual_option_name {
    my ($self) = @_;

    if ( my $override = $self->get_getopt_name() ) {
        return $override;
    } # end if

    my $name = $self->name();
    if ($name =~ m< \A _ >xms) {
        throw_invalid_specification
            qq<Will not create option for private attribute "$name".  If you really want to have an option be private, specify a value for "getopt_name" on the attribute.>;
    } # end if

    $name =~ s< _ ><->xmsg;

    return $name;
} # end get_actual_option_name()


# The option name plus any aliases, separated by pipes, as per Getopt::Long.
sub get_option_name_plus_aliases {
    my ($self) = @_;

    if ( my $aliases = $self->get_getopt_aliases() ) {
        return join q<|>, $self->get_actual_option_name(), @{$aliases};
    } # end if

    return $self->get_actual_option_name();
} # end get_option_name_plus_aliases()


# Retrieve the name of the type of attribute this is, whether the default
# Moose one or the one overridden using via getopt_type.
sub get_type_name {
    my ($self) = @_;

    my $type_name = $self->get_getopt_type();
    if ( not $type_name and $self->has_type_constraint() ) {
        $type_name = $self->type_constraint()->name();
    } # end if

    if (not $type_name) {
        throw_invalid_specification
                'Cannot figure out the type of the "'
            .   $self->name()
            .   '" attribute.';
    } # end if

    return $type_name;
} # end get_type_name()


# Figure out the part of the Getopt::Long specification that isn't the option
# name and aliases.
#
# Expects an instance of MooseX::Getopt::Defanged::OptionTypeMetadata as a parameter.
sub get_type_specification {
    my ($self, $type_metadata) = @_;

    if ( my $override = $self->get_getopt_specification() ) {
        return $override;
    } # end if

    my $type_name = $self->get_type_name();

    my $specification = $type_metadata->get_default_specification($type_name)
        // throw_invalid_specification
            qq<Cannot find a Getopt::Long specification for the "$type_name" type.>;

    return $specification;
} # end get_type_specification()


# Get the complete Getopt::Long specification for this option; name, aliases,
# type information, everything.
#
# Expects an instance of MooseX::Getopt::Defanged::OptionTypeMetadata as a parameter.
sub get_full_specification {
    my ($self, $type_metadata) = @_;

    return
            $self->get_option_name_plus_aliases()
        .   $self->get_type_specification($type_metadata);
} # end get_full_specification()


# Retrieve the value of this attribute from the MooseX::Getopt::Defanged consumer, or the
# default value as specified by the value generator on the type metadata.
#
# Expects an object with this attribute (i.e. an consumer of the MooseX::Getopt::Defanged
# role) and an instance of MooseX::Getopt::Defanged::OptionTypeMetadata as the last
# parameter.
sub get_value_or_default {
    my ($self, $getopt_consumer, $type_metadata) = @_;

    if ( defined ( my $value = $self->get_value($getopt_consumer) ) ) {
        return $value;
    } # end if

    my $type_name = $self->get_type_name();
    my $default_value_generator =
        $type_metadata->get_default_value_generator($type_name)
        or return;

    return $default_value_generator->();
} # end get_value_or_default()


1;

__END__

=encoding utf8

=for stopwords

=head1 NAME

MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt - Moose trait for attributes that are to act as options for L<MooseX::Getopt::Defanged>.


=head1 SYNOPSIS

None, don't use this module directly.  See the documentation on
L<MooseX::Getopt::Defanged> for how to specify options.


=head1 VERSION

This document describes
MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt version 1.14.0.


=head1 DESCRIPTION

This module is part of the implementation of L<MooseX::Getopt::Defanged> and
should not be directly used.


=head1 INTERFACE

None, don't use this module directly.


=head1 DIAGNOSTICS

If you give invalid attribute specifications, you'll get
L<MooseX::Getopt::Defanged::Exception::InvalidSpecification>s out of here.


=head1 CONFIGURATION AND ENVIRONMENT

See L<MooseX::Getopt::Defanged>.


=head1 DEPENDENCIES

perl 5.10

L<Moose::Role>

L<Moose::Util::TypeConstraints>


=head1 TODO

Add support for a custom validation CODE reference.


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
