package AmuseWikiFarm::Exception;

use strict;
use warnings;

=encoding utf8

=head1 NAME

AmuseWikiFarm::Exception - Catalyst miniapp to handle exceptions.

=head1 DESCRIPTION

Used internally. It always serve a response status of 400 with a
customized message.

The purpose is to avoid noisy crashes generated by the application.

=head1 CREDITS

Implemented from:

L<https://github.com/perl-catalyst/catalyst-runtime/blob/unicode-exception-issue/t/unicode-exception-bug.t>

=cut

sub new {
    my ($class, $message) = @_;
    $message ||= 'Bad request';
    my $self = { message => $message };
    bless $self, $class;
}

sub throw { die shift->new(@_) };

sub as_psgi {
    my ($self, $env) = @_;
    return [400, ['content-type'=>'text/plain'], [ $self->{message} ]];
}

1;
