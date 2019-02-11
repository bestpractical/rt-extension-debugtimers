use strict;
use warnings;

package RT::Interface::Web;

sub HandleRequest {
    my $ARGS = shift;

    if (RT->Config->Get('DevelMode')) {
        require Module::Refresh;
        Module::Refresh->refresh;
    }

    $HTML::Mason::Commands::r->content_type("text/html; charset=utf-8");

    $HTML::Mason::Commands::m->{'rt_base_time'} = [ Time::HiRes::gettimeofday() ];

    # Roll back any dangling transactions from a previous failed connection
    $RT::Handle->ForceRollback() if $RT::Handle and $RT::Handle->TransactionDepth;

    MaybeEnableSQLStatementLog();

    # avoid reentrancy, as suggested by masonbook
    local *HTML::Mason::Commands::session unless $HTML::Mason::Commands::m->is_subrequest;

    $HTML::Mason::Commands::m->autoflush( $HTML::Mason::Commands::m->request_comp->attr('AutoFlush') )
        if ( $HTML::Mason::Commands::m->request_comp->attr_exists('AutoFlush') );

    ValidateWebConfig();

    DecodeARGS($ARGS);
    local $HTML::Mason::Commands::DECODED_ARGS = $ARGS;
    PreprocessTimeUpdates($ARGS);

    InitializeMenu();
    MaybeShowInstallModePage();

    MaybeRebuildCustomRolesCache();

    $HTML::Mason::Commands::m->comp( '/Elements/SetupSessionCookie', %$ARGS );
    SendSessionCookie();

    if ( _UserLoggedIn() ) {
        # make user info up to date
        $HTML::Mason::Commands::session{'CurrentUser'}
          ->Load( $HTML::Mason::Commands::session{'CurrentUser'}->id );
        undef $HTML::Mason::Commands::session{'CurrentUser'}->{'LangHandle'};
    }
    else {
        $HTML::Mason::Commands::session{'CurrentUser'} = RT::CurrentUser->new();
    }

    # attempt external auth
    $HTML::Mason::Commands::m->comp( '/Elements/DoAuth', %$ARGS )
        if @{ RT->Config->Get( 'ExternalAuthPriority' ) || [] };

    # Process session-related callbacks before any auth attempts
    $HTML::Mason::Commands::m->callback( %$ARGS, CallbackName => 'Session', CallbackPage => '/autohandler' );

    MaybeRejectPrivateComponentRequest();

    MaybeShowNoAuthPage($ARGS);

    AttemptExternalAuth($ARGS) if RT->Config->Get('WebRemoteUserContinuous') or not _UserLoggedIn();

    _ForceLogout() unless _UserLoggedIn();

    # attempt external auth
    $HTML::Mason::Commands::m->comp( '/Elements/DoAuth', %$ARGS )
        if @{ RT->Config->Get( 'ExternalAuthPriority' ) || [] };

    # Process per-page authentication callbacks
    $HTML::Mason::Commands::m->callback( %$ARGS, CallbackName => 'Auth', CallbackPage => '/autohandler' );

    if ( $ARGS->{'NotMobile'} ) {
        $HTML::Mason::Commands::session{'NotMobile'} = 1;
    }

    unless ( _UserLoggedIn() ) {
        _ForceLogout();

        # Authenticate if the user is trying to login via user/pass query args
        my ($authed, $msg) = AttemptPasswordAuthentication($ARGS);

        unless ($authed) {
            my $m = $HTML::Mason::Commands::m;

            # REST urls get a special 401 response
            if ($m->request_comp->path =~ m{^/REST/\d+\.\d+/}) {
                $HTML::Mason::Commands::r->content_type("text/plain; charset=utf-8");
                $m->error_format("text");
                $m->out("RT/$RT::VERSION 401 Credentials required\n");
                $m->out("\n$msg\n") if $msg;
                $m->abort;
            }
            # Specially handle /index.html and /m/index.html so that we get a nicer URL
            elsif ( $m->request_comp->path =~ m{^(/m)?/index\.html$} ) {
                my $mobile = $1 ? 1 : 0;
                my $next   = SetNextPage($ARGS);
                $m->comp('/NoAuth/Login.html',
                    next    => $next,
                    actions => [$msg],
                    mobile  => $mobile);
                $m->abort;
            }
            else {
                TangentForLogin($ARGS, results => ($msg ? LoginError($msg) : undef));
            }
        }
    }

    MaybeShowInterstitialCSRFPage($ARGS);

    # now it applies not only to home page, but any dashboard that can be used as a workspace
    $HTML::Mason::Commands::session{'home_refresh_interval'} = $ARGS->{'HomeRefreshInterval'}
        if ( $ARGS->{'HomeRefreshInterval'} );

    # Process per-page global callbacks
    $HTML::Mason::Commands::m->callback( %$ARGS, CallbackName => 'Default', CallbackPage => '/autohandler' );

    ShowRequestedPage($ARGS);
    LogRecordedSQLStatements(RequestData => {
        Path => $HTML::Mason::Commands::m->request_path,
    });

    # Process per-page final cleanup callbacks
    $HTML::Mason::Commands::m->callback( %$ARGS, CallbackName => 'Final', CallbackPage => '/autohandler' );
    $HTML::Mason::Commands::m->comp( '/Elements/Footer', %$ARGS );

    use RT::Util;
    my $time = Time::HiRes::tv_interval( $HTML::Mason::Commands::m->{'rt_base_time'});
    my $time_threshold = RT::Config->Get('LongRequestThreshold')|| 100;

    RT::Logger->error(
        "Leaving autohandler, time is: " . $time . "\n"
        . "User making the request: " . $HTML::Mason::Commands::session{'CurrentUser'}->Name . "\n"
        . "Request URL: " . $HTML::Mason::Commands::m->request_path . "\n"
    ) if $time >= $time_threshold;
}

1;
