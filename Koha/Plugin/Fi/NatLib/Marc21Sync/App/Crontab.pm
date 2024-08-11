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
                $self->logf('ERROR', "Failed to download $url (to $fullpath): [$@].");
            } else {
                $self->logf('NOTICE', "Downloaded $url to $fullpath.");
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
        $self->logf( 'ERROR', "Error when executing utils/upsert_marc_fields.pl for default framework." . ($error_message ? 'Message: '.$error_message : '') );
        $self->logf( 'ERROR', "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
    } else {
        $self->logf( 'INFO', "Success when executing utils/upsert_marc_fields.pl for default framework." );
        $self->logf( 'INFO', "STDOUT:\n" . join( "", @$stdout_buf ) ) if @$stdout_buf;
        $self->logf( 'INFO', "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
        $self->logf( 'INFO', "FULL:\n" . join( "", @$full_buf ) ) if @$full_buf;
    }

    ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = IPC::Cmd::run(
        verbose => 0,
        command => [ 'perl', $script_path, '--framework=*-', '--flags=intranet,opac', '--insert', '--update' ]
    );
    unless ($success) {
        $self->logf( 'ERROR', "Error when executing utils/upsert_marc_fields.pl for all frameworks." . ($error_message ? 'Message: '.$error_message : '') );
        $self->logf( 'ERROR', "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
    } else {
        $self->logf( 'INFO', "Success when executing utils/upsert_marc_fields.pl for all frameworks." );
        $self->logf( 'INFO', "STDOUT:\n" . join( "", @$stdout_buf ) ) if @$stdout_buf;
        $self->logf( 'INFO', "STDERR:\n" . join( "", @$stderr_buf ) ) if @$stderr_buf;
        $self->logf( 'INFO', "FULL:\n" . join( "", @$full_buf ) ) if @$full_buf;
    }

    chdir $old_currdir
        or die "Cannot chdir to $base_temp_dir: $!";

    return;
}

1;
