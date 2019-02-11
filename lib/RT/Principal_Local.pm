package RT::Principal;

use strict;
use warnings;
no warnings 'redefine';

our $_ACL_CACHE;

sub HasRight {

    my $self = shift;
    my %args = ( Right        => undef,
                 Object       => undef,
                 EquivObjects => undef,
                 @_,
               );

    # RT's SystemUser always has all rights
    if ( $self->id == RT->SystemUser->id ) {
        return 1;
    }

    if ( my $right = RT::ACE->CanonicalizeRightName( $args{'Right'} ) ) {
        $args{'Right'} = $right;
    } else {
        $RT::Logger->error(
               "Invalid right. Couldn't canonicalize right '$args{'Right'}'");
        return undef;
    }

    return undef if $args{'Right'} eq 'ExecuteCode'
        and RT->Config->Get('DisallowExecuteCode');

    $args{'EquivObjects'} = [ @{ $args{'EquivObjects'} } ]
        if $args{'EquivObjects'};

    if ( $self->__Value('Disabled') ) {
        $RT::Logger->debug(   "Disabled User #"
                            . $self->id
                            . " failed access check for "
                            . $args{'Right'} );
        return (undef);
    }

    if ( eval { $args{'Object'}->id } ) {
        push @{ $args{'EquivObjects'} }, $args{'Object'};
    } else {
        $RT::Logger->crit("HasRight called with no valid object");
        return (undef);
    }

    {
        my $cached = $_ACL_CACHE->{
            $self->id .';:;'. ref($args{'Object'}) .'-'. $args{'Object'}->id
        };
        return $cached->{'SuperUser'} || $cached->{ $args{'Right'} }
            if $cached;
    }

    unshift @{ $args{'EquivObjects'} },
        $args{'Object'}->ACLEquivalenceObjects;
    unshift @{ $args{'EquivObjects'} }, $RT::System;

    # If we've cached a win or loss for this lookup say so

# Construct a hashkeys to cache decisions:
# 1) full_hashkey - key for any result and for full combination of uid, right and objects
# 2) short_hashkey - one key for each object to store positive results only, it applies
# only to direct group rights and partly to role rights
    my $full_hashkey = join (";:;", $self->id, $args{'Right'});
    foreach ( @{ $args{'EquivObjects'} } ) {
        my $ref_id = $self->_ReferenceId($_);
        $full_hashkey .= ";:;".$ref_id;

        my $short_hashkey = join(";:;", $self->id, $args{'Right'}, $ref_id);
        my $cached_answer = $_ACL_CACHE->{ $short_hashkey };
        return $cached_answer > 0 if defined $cached_answer;
    }

    {
        my $cached_answer = $_ACL_CACHE->{ $full_hashkey };
        return $cached_answer > 0 if defined $cached_answer;
    }

    my ( $hitcount, $via_obj ) = $self->_HasRight(%args);

    $_ACL_CACHE->{ $full_hashkey } = $hitcount ? 1 : -1;
    $_ACL_CACHE->{ join ';:;',  $self->id, $args{'Right'}, $via_obj } = 1
        if $via_obj && $hitcount;

    return ($hitcount);
}




1;

