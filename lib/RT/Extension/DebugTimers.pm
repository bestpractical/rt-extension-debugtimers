use strict;
use warnings;
package RT::Extension::DebugTimers;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-DebugTimers - Add detailed timers to debug performance

=head1 DESCRIPTION

This extension provides timers for when a request takes longer than an allotted
value.

=head1 RT VERSION

Works with RT 4.4

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::DebugTimers');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Specificy the threshold at which any request equalling or surpassing should be
logged in seconds: Default value for loggging is any request that takes longer
than 50 seconds.

     Set($LogRequestThreshold, 20);

=cut

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
