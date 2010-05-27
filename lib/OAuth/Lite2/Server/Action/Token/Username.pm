package OAuth::Lite2::Server::Action::Token::Username;

use strict;
use warnings;

use base 'OAuth::Lite2::Server::Action::Token';
use OAuth::Lite2::Server::Error;

sub handle_request {
    my ($self, $ctx) = @_;

    my $dh  = $ctx->data_handler;
    my $req = $ctx->request;

    my $client_id = $req->param("client_id");
    OAuth::Lite2::Server::Error::MissingParam->throw("client_id")
        unless $client_id;

    my $client_secret = $req->param("client_secret");
    OAuth::Lite2::Server::Error::MissingParam->throw("client_secret")
        unless $client_secret;

    my $username = $req->param("username");
    OAuth::Lite2::Server::Error::MissingParam->throw("username")
        unless $username;

    my $password = $req->param("password");
    OAuth::Lite2::Server::Error::MissingParam->throw("password")
        unless $password;

    my $client = $dh->get_client_user(
        client_id     => $client_id,
        client_secret => $client_secret,
    );

    my $user = $dh->get_user(
        username => $username,
        password => $password,
    );

    my $scope = $req->param("scope");

    my $auth_info = $dh->create_or_update_auth_info(
        client_id => $client_id,
        scope     => $scope,
        user      => $user,
    );

    my $secret_type = $req->param("secret_type");

    my $access_token = $dh->create_or_update_access_token(
        auth_id     => $auth_info->id,
        secret_type => $secret_type,
    );

    return $access_token;
}

1;
