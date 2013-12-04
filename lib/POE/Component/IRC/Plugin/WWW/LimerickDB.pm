package POE::Component::IRC::Plugin::WWW::LimerickDB;

use warnings;
use strict;

our $VERSION = '0.0102';

use POE;
use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
use POE::Component::WWW::LimerickDB;

sub _make_default_args {
    return (
        response_event   => 'irc_limerick',
        trigger          => qr/^limerick/i,
        new_line         => ' / ',
        max_length       => 350,
    );
}

sub _make_poco {
    my $self = shift;
    return POE::Component::WWW::LimerickDB->spawn(
        debug    => $self->{debug},
        obj_args => { new_line => $self->{new_line}, },
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;

    if ( $in_ref->{error} ) {
        return [ $in_ref->{error} ];
    }

    unless ( length $in_ref->{out}{text} ) {
        return [ "No such limerick" ];
    }
    
    my $limerick = substr $in_ref->{out}{text}, 0, $self->{max_length};
    if ( length $limerick != length $in_ref->{out}{text} ) {
        $limerick .= '...';
    }

    if ( $limerick =~ /\n/ ) {
        my @bits = split /\n/, $in_ref->{out}{text};
        return [ "#$in_ref->{out}{number}: $bits[0]", @bits[1 .. $#bits] ];
    }
    else {
        return [ "#$in_ref->{out}{number}: $limerick" ];
    }
}

sub _message_into_response_event { 'out' }

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    my ( $method, $args ) = ( 'get_cached', [ 'random', 2 ] );
    my $num = $data_ref->{what};
    $num =~ tr/0-9//cd;
    if ( length $num ) {
        ( $method, $args ) = ( 'get_limerick', [ $num ] );
    }

    $self->{poco}->get( {
            event       => '_poco_done',
            method      => $method,
            args        => $args,
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}

1;
__END__

=head1 NAME

POE::Component::IRC::Plugin::WWW::LimerickDB - display random limericks on IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::WWW::LimerickDB);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'LimerickBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'LimerickBot',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'limerick' =>
                POE::Component::IRC::Plugin::WWW::LimerickDB->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }


    <Zoffix> LimerickBot, limerick 288
    <LimerickBot> #288: There once was a priest from Morocco  / Who's motto was really quite
                    macho  / He said "To be blunt  / God decreed we eat cunt.  / Why else
                    would it look like a taco?"

    <Zoffix> LimerickBot, limerick
    <LimerickBot> #339: If profane and chock-full of inanity  / they will love and promote you
                    to vanity.  / Poignant phrases eschewed,  / you will likely conclude  /
                    that censorship leads to insanity

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
fetch random limericks from L<http://limerickdb.com/>.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'limerick' => POE::Component::IRC::Plugin::WWW::LimerickDB->new
    );

    # juicy flavor
    $irc->plugin_add(
        'limerick' =>
            POE::Component::IRC::Plugin::WWW::LimerickDB->new(
                new_line         => ' / ',
                max_length       => 350,
                auto             => 1,
                response_event   => 'irc_limerick',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^limerick/i,
                triggers         => {
                    public  => qr/^limerick/i,
                    notice  => qr/^limerick/i,
                    privmsg => qr/^limerick/i,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::WWW::LimerickDB> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. The possible
arguments/values are as follows:

=head3 C<new_line>

    ->new( new_line => ' / ' );

B<Optional>. Specifies the character to use to represent new lines in lamericks. Specifying
the actual new line here (C<\n>) makes the plugin spit out the limerick in several lines.
B<Defaults to:> C<' / '>

=head3 C<max_length>

    ->new( max_length => 350 );

B<Optional>. Specifies the maximum length of the limerick. If the length exceeds the
number you specify here the limerick will be cut off and C<...> will be appended to the end.
B<Defaults to:> C<350>

=head3 C<auto>

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emited by the plugin to retrieve the results (see
EMITED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 C<response_event>

    ->new( response_event => 'event_name_to_recieve_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITED EVENTS
section for more information. B<Defaults to:> C<irc_limerick>

=head3 C<banned>

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) making the request matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 C<root>

    ->new( root => [ qr/\Qjust.me.and.my.friend.net\E$/i ] );

B<Optional>. As opposed to C<banned> argument, the C<root> argument
B<allows> access only to people whose usermasks match B<any> of
the regexen you specify in the arrayref the argument takes as a value.
B<By default:> it is not specified. B<Note:> as opposed to C<banned>
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 C<trigger>

    ->new( trigger => qr/^limerick/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex, irrelevant of the type of the message, will be considered as requests. See also
B<addressed> option below which is enabled by default as well as
B<trigggers> option which is more specific. B<Note:> the
    trigger will be B<removed> from the message, therefore make sure your
    trigger doesn't match the actual data that needs to be processed.
B<If after stripping the trigger any digits are left in the input then those are interpreted
as a limerick number and it will be fetched, otherwise a random limerick is fetched>.
B<Defaults to:> C<qr/^limerick/i>

=head3 C<triggers>

    ->new( triggers => {
            public  => qr/^limerick/i,
            notice  => qr/^limerick/i,
            privmsg => qr/^limerick/i,
        }
    );

B<Optional>. Takes a hashref as an argument which may contain either
one or all of keys B<public>, B<notice> and B<privmsg> which indicates
the type of messages: channel messages, notices and private messages
respectively. The values of those keys are regexes of the same format and
meaning as for the C<trigger> argument (see above).
Messages matching this
regex will be considered as requests. The difference is that only messages of type corresponding to the key of C<triggers> hashref
are checked for the trigger. B<Note:> the C<trigger> will be matched
irrelevant of the setting in C<triggers>, thus you can have one global and specific "local" triggers. See also
B<addressed> option below which is enabled by default as well as
B<trigggers> option which is more specific. B<Note:> the
    trigger will be B<removed> from the message, therefore make sure your
    trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^limerick/i>

=head3 C<addressed>

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig EXAMPLE>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to make a request. Note: this argument has no effect on
C</notice> and C</msg> requests. B<Defaults to:> C<1>

=head3 C<listen_for_input>

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable functionality only via C</notice> and C</msg> messages.
B<Defaults to:> C<[ qw(public  notice  privmsg) ]>

=head3 C<eat>

    ->new( eat => 0 );

B<Optional>. If set to a false value plugin will return a
C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head3 C<debug>

    ->new( debug => 1 );

B<Optional>. Takes either a true or false value. When C<debug> argument
is set to a true value some debugging information will be printed out.
When C<debug> argument is set to a false value no debug info will be
printed. B<Defaults to:> C<0>.

=head1 EMITED EVENTS

=head2 C<response_event>

    $VAR1 = {
        "out" => [
                    "#5: There is something about satyriasis  / That arouses psychiatrists' biases.  / But we're both very pleased  / we're this way diseased,  / as the damsel who's waiting to try us is."
                ],
        "_what" => "",
        "_channel" => "#zofbot",
        "_type" => "public",
        "_who" => "Zoffix!n=Zoffix\@unaffiliated/zoffix",
        "_message" => "LimerickBot, limerick",
        "method" => "get_cached",
        "args" => [
            "random",
            2
        ],
    };


The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_limerick>) will recieve input
every time request is completed. The input will come in C<$_[ARG0]>
on a form of a hashref.
The possible keys/values of that hashrefs are as follows:

=head3 C<out>

    "out" => [
            "#78: There once was a nun from Siberia  / who was blessed with a virgin interior,  / until a young monk  / climbed into her bunk,  / and soon she was Mother Superior."
    ],

Unless an error occured the C<out> key will contain an arrayref element(s) of which
are the limerick fetched. The arrayref will contain more than one element only when
C<new_line> argument to constructor was set to the actual new line character (C<\n>) in
which case, each element of the arrayref will be a separate line of the limerick.

=head3 C<error>

    "error" => "Network error: 500 Timeout"

If an error occured, the C<error> key will be present and it will contain the message
explaning the error.

=head3 C<_who>

    { '_who' => 'Zoffix!Zoffix@i.love.debian.org', }

The C<_who> key will contain the user mask of the user who sent the request.

=head3 C<_what>

    { '_what' => '299', }

The C<_what> key will contain user's message after stripping the C<trigger>
(see CONSTRUCTOR).

=head3 C<_message>

    { '_message' => "LimerickBot, limerick", }

The C<_message> key will contain the actual message which the user sent; that
is before the trigger is stripped.

=head3 C<_type>

    { '_type' => 'public', }

The C<_type> key will contain the "type" of the message the user have sent.
This will be either C<public>, C<privmsg> or C<notice>.

=head3 C<_channel>

    { '_channel' => '#zofbot', }

The C<_channel> key will contain the name of the channel where the message
originated. This will only make sense if C<_type> key contains C<public>.

=head3 C<method> and C<args>

    "method" => "get_cached",
    "args" => [
        "random",
        2
    ],

The C<method> and C<args> keys are pretty much here only because it was much easier to
leave them in than remove them. Just ignore them, if you really want to know what those
are take a look at L<POE::Component::WWW::LimerickDB> which is what this plugin uses
under the hood.

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-www-limerickdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-WWW-LimerickDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::WWW::LimerickDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-WWW-LimerickDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-WWW-LimerickDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-WWW-LimerickDB>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-WWW-LimerickDB>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

