package Koha::Plugin::Fi::NatLib::Marc21Sync::App::Crontab;
use Modern::Perl; use utf8; use open qw(:utf8);

use File::Temp ();
use Mojo::UserAgent ();
use IPC::Cmd ();
use Cwd ();


## ----------------------------------------
## Plugin CRONTAB element
## ----------------------------------------

sub cronjob_nightly {
    my ( $self ) = @_;

    $self->set_log("") unless $self->{config}{log_preserve};

    # we will not do anything if nightly cron is not enabled
    return
        unless $self->{config}{nightly_cron_enabled};

    # 4: Debug, 3: Notice, 2: Info, 1: Warn, 0: Error
    $self->log("Nightly cronjob STARTED.") if $self->{config}{log_level} >= 2;

    ###

    ##
    ## Download files:
    ##

    my $base_temp_dir = File::Temp->newdir( CLEANUP => 1 ); # let's have a temporary directory
    my $temp_dir = $base_temp_dir."/data";
    mkdir $temp_dir
        or die "Cannot create $temp_dir: $!";

    my $download_set = $self->{config}{download_set}; # our download set (check Marc21Sync.pm for details)
    my $ua = Mojo::UserAgent->new;

    for my $line ( split /\n/, $download_set ) {
        my ($dir, $files) = split /:\s*/, $line;
        my @files = split /\s+/, $files;
        for my $file ( @files ) {
            my $url = "https://marc21.kansalliskirjasto.fi/$dir/$file.xml";
            my $filename = "$dir-$file.xml";
            my $fullpath = "$temp_dir/$filename";
            eval {
                $ua->get($url)->res->content->asset->move_to($fullpath);
            };
            if ( $@ ) {
                $self->log("Failed to download $url (to $fullpath): [$@].");
            } else {
                $self->log("Downloaded $url to $fullpath.") if $self->{config}{log_level} >= 3;
            }
        }
    }

    ##
    ## Parse and store them:
    ##

    my $script_path = $self->{plugin}->mbf_path('utils/upsert_marc_fields.pl');
    my $old_currdir = Cwd::getcwd();
    chdir $base_temp_dir
        or die "Cannot chdir to $base_temp_dir: $!";

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = IPC::Cmd::run(
        verbose => 0,
        command => [ 'perl', $script_path, '--flags=intranet,opac,editor', '--insert', '--update' ]
    );
    unless ($success) {
        $self->log("Error when executing utils/upsert_marc_fields.pl for default framework." . ($error_message ? 'Message: '.$error_message : ''));
        $self->log( "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
    } elsif ( $self->{config}{log_level} >= 2 ) {
        $self->log("Success when executing utils/upsert_marc_fields.pl for default framework.");
        $self->log( "STDOUT:\n" . join( "", @$stdout_buf ) ) if @$stdout_buf;
        $self->log( "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
        $self->log( "FULL:\n" . join( "", @$full_buf ) ) if @$full_buf;
    }

    ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = IPC::Cmd::run(
        verbose => 0,
        command => [ 'perl', $script_path, '--framework=*-', '--flags=intranet,opac', '--insert', '--update' ]
    );
    unless ($success) {
        $self->log("Error when executing utils/upsert_marc_fields.pl for all frameworks." . ($error_message ? 'Message: '.$error_message : ''));
        $self->log( "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
    } elsif ( $self->{config}{log_level} >= 2 ) {
        $self->log("Success when executing utils/upsert_marc_fields.pl for all frameworks.");
        $self->log( "STDOUT:\n" . join( "", @$stdout_buf ) ) if @$stdout_buf;
        $self->log( "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
        $self->log( "FULL:\n" . join( "", @$full_buf ) ) if @$full_buf;
    }

    chdir $old_currdir
        or die "Cannot chdir to $base_temp_dir: $!";

    ###

    $self->log("Nightly cronjob ENDED.") if $self->{config}{log_level} >= 2;

    return;
}

1;
