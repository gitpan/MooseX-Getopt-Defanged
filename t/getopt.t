#!/usr/bin/env perl

package MooseX::Getopt::Defanged::Test;

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.14.0');


use English qw< -no_match_vars >;
use Readonly;


use parent 'Test::Class';


use File::Spec::Functions qw< catdir >;


use MooseX::Getopt::Defanged qw< :all >;


use Test::Deep;
use Test::Moose;
use Test::More;


use lib catdir( qw< t getopt.d lib > );


Readonly::Scalar my $ROLE_NAME => 'MooseX::Getopt::Defanged';

Readonly::Scalar my $TEST_STRING    => 'blah';
Readonly::Scalar my $TEST_INTEGER   => 123;
Readonly::Scalar my $TEST_NUMBER    => 1.23;
Readonly::Scalar my $TEST_KEY       => 'key';

# Boolean attribute will be handled separately.
Readonly my @TEST_5_PARAMETERS => (
    {
        name            => 'str',
        command_line    => $TEST_STRING,
        expected        => $TEST_STRING,
    },
    {
        name            => 'int',
        command_line    => $TEST_INTEGER,
        expected        => $TEST_INTEGER,
    },
    {
        name            => 'num',
        command_line    => $TEST_NUMBER,
        expected        => $TEST_NUMBER,
    },
    {
        name            => 'arrayref',
        command_line    => [ $TEST_STRING, $TEST_STRING ],
        expected        => [ $TEST_STRING, $TEST_STRING ],
    },
    {
        name            => 'arrayref_str',
        command_line    => [ $TEST_STRING, $TEST_STRING ],
        expected        => [ $TEST_STRING, $TEST_STRING ],
    },
    {
        name            => 'arrayref_int',
        command_line    => [ $TEST_INTEGER, $TEST_INTEGER ],
        expected        => [ $TEST_INTEGER, $TEST_INTEGER ],
    },
    {
        name            => 'arrayref_num',
        command_line    => [ $TEST_NUMBER, $TEST_NUMBER ],
        expected        => [ $TEST_NUMBER, $TEST_NUMBER ],
    },
    {
        name            => 'hashref',
        command_line    => "$TEST_KEY=$TEST_STRING",
        expected        => { $TEST_KEY => $TEST_STRING },
    },
    {
        name            => 'hashref_str',
        command_line    => "$TEST_KEY=$TEST_STRING",
        expected        => { $TEST_KEY => $TEST_STRING },
    },
    {
        name            => 'hashref_int',
        command_line    => "$TEST_KEY=$TEST_INTEGER",
        expected        => { $TEST_KEY => $TEST_INTEGER },
    },
    {
        name            => 'hashref_num',
        command_line    => "$TEST_KEY=$TEST_NUMBER",
        expected        => { $TEST_KEY => $TEST_NUMBER },
    },
);


__PACKAGE__->runtests();


sub test_1_mooseness : Tests(1) {
    meta_ok($ROLE_NAME, "$ROLE_NAME has a meta class.");

    return;
} # end test_1_mooseness()


sub test_2_can_construct_minimal_consumer : Tests(7) {
    my $class_name = "${ROLE_NAME}::MinimalConsumer";
    use_ok($class_name);
    my $minimal_consumer = new_ok($class_name);

    meta_ok($minimal_consumer, 'Minimal consumer has a meta class.');
    does_ok(
        $minimal_consumer,
        $ROLE_NAME,
        "Minimal consumer does $ROLE_NAME.",
    );

    can_ok($minimal_consumer, 'parse_command_line');
    can_ok($minimal_consumer, 'get_remaining_argv');
    can_ok($minimal_consumer, 'get_option_type_metadata');

    return;
} # end test_2_can_construct_minimal_consumer()


sub test_3_can_parse_command_line_for_minimal_consumer : Tests(3) {
    my $minimal_consumer = new_ok("${ROLE_NAME}::MinimalConsumer");

    my @argv = qw< foo bar >;
    my $argv_ref = [ @argv ];

    $minimal_consumer->parse_command_line($argv_ref);

    cmp_deeply(
        $argv_ref,
        \@argv,
        'Command line parsing for minimal consumer did not change the argv reference.',
    );
    cmp_deeply(
        [ $minimal_consumer->get_remaining_argv() ],
        \@argv,
        'Command line parsing for minimal consumer left the remaining argv with the same contents as the original.',
    );

    return;
} # end test_3_can_parse_command_line_for_minimal_consumer()


sub test_5_can_parse_command_line_for_consumer_of_all_types : Tests(30) {
    my $class_name = "${ROLE_NAME}::ConsumerOfAllTypes";
    use_ok($class_name);
    my $consumer = new_ok($class_name);

    meta_ok($consumer, 'Consumer of all types has a meta class.');
    does_ok(
        $consumer,
        $ROLE_NAME,
        "Consumer of all types does $ROLE_NAME.",
    );

    my @extra_command_line_parameters = qw< foo bar >;
    my @argv = (
        @extra_command_line_parameters,
        qw< --bool --maybe-bool >,
    );
    foreach my $parameter (@TEST_5_PARAMETERS) {
        (my $name = $parameter->{name}) =~ s/ _ /-/xmsg;
        my $values = $parameter->{command_line};
        my @values = ref $values ? @{$values} : ($values);

        push @argv, "--$name", @values, "--maybe-$name", @values;
    } # end foreach

    my $argv_ref = [ @argv ]; # Needs to be a copy so that change can be detected.

    $consumer->parse_command_line($argv_ref);

    cmp_deeply(
        $argv_ref,
        \@argv,
        'Command line parsing for consumer of all types did not change the argv reference.',
    );
    cmp_deeply(
        [ $consumer->get_remaining_argv() ],
        \@extra_command_line_parameters,
        'Command line parsing for consumer of all types left the correct remaining argv.',
    );

    ok($consumer->bool(), 'The --bool option got set.');
    ok($consumer->maybe_bool(), 'The --maybe-bool option got set.');

    foreach my $parameter (@TEST_5_PARAMETERS) {
        my $name = $parameter->{name};
        (my $option_name = $name) =~ s/ _ /-/xmsg;
        my $expected = $parameter->{expected};

        my $accessor_name = "get_$name";
        cmp_deeply(
            $consumer->$accessor_name(),
            $expected,
            "Got correct value for the --$option_name option.",
        );

        $accessor_name = "get_maybe_$name";
        cmp_deeply(
            $consumer->$accessor_name(),
            $expected,
            "Got correct value for the --maybe-$option_name option.",
        );
    } # end foreach

    return;
} # end test_5_can_parse_command_line_for_consumer_of_all_types()

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 encoding=utf8 :
