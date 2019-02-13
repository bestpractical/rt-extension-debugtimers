use strict;
use warnings;
package RT::Extension::DebugTimers;

our $VERSION = '0.02';

RT->AddStyleSheets('debug-timers.css');

=head1 NAME

RT-Extension-DebugTimers - Add detailed timers to debug performance

=head1 DESCRIPTION

This extension provides timing and user information in RT's logs
to help determine which requests by which users may be experiencing slow
load times. It also enables a page timer in the footer on all RT pages.

=head1 RT VERSION

Works with RT 4.4

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::DebugTimers');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 When to log time information

To log timing and request information for only requests that take over
some number of seconds, add:

    Set($LongRequestThreshold, 3);

to C<RT_SiteConfig.pm>. The default value is 40 seconds.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-DebugTimers@rt.cpan.org|mailto:bug-RT-Extension-DebugTimers@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-DebugTimers>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
