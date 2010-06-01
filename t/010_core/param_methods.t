use strict;
use warnings;

use Test::More tests => 84;

use OAuth::Lite2::ParamMethods qw(AUTH_HEADER FORM_BODY URI_QUERY);
use Try::Tiny;


my ($auth, $body, $query, $unknown);

TEST_FACTORY: {

    $auth = OAuth::Lite2::ParamMethods->get_request_builder(AUTH_HEADER);
    isa_ok($auth, "OAuth::Lite2::ParamMethod::AuthHeader");

    $body = OAuth::Lite2::ParamMethods->get_request_builder(FORM_BODY);
    isa_ok($body, "OAuth::Lite2::ParamMethod::FormEncodedBody");

    $query = OAuth::Lite2::ParamMethods->get_request_builder(URI_QUERY);
    isa_ok($query, "OAuth::Lite2::ParamMethod::URIQueryParameter");

    $unknown = OAuth::Lite2::ParamMethods->get_request_builder(10);
    ok(!$unknown);

    # TODO TEST get_param_parser($req)
};


TEST_AUTH_HEADER: {

    # ==============================
    # GET/DELETE (no content method)
    # ==============================
    # Without OAuth Params
    my $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {},
    );
    is($req->uri, q{http://example.org/resource});
    is($req->header("Authorization"), q{Token token="access_token_value"});
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # With OAuth Params
    $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {
            nonce     => q{s8djwd},
            timestamp => q{137131200},
            algorithm => q{hmac-sha256},
            signature => q{wOJIO9A2W5mFwDgiDvZbTSMK/PY=},
        },
    );
    is($req->uri, q{http://example.org/resource});
    is($req->header("Authorization"), q{Token token="access_token_value", algorithm="hmac-sha256", nonce="s8djwd", signature="wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D", timestamp="137131200"});
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # With Extra Params
    $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {},
        params       => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource?buz=hoge&foo=bar});
    is($req->header("Authorization"), q{Token token="access_token_value"});
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # 'content' should be ignored
    $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {},
        content      => q{content!},
        params       => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource?buz=hoge&foo=bar});
    is($req->header("Authorization"), q{Token token="access_token_value"});
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # ==============================
    # POST/PUT (content method)
    # ==============================
    # With Extra Params
    $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        oauth_params => {},
        params       => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource});
    is($req->header("Authorization"), q{Token token="access_token_value"});
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/x-www-form-urlencoded});
    is($req->content, q{buz=hoge&foo=bar});

    # With Extra Params And Content
    $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        oauth_params => {},
        content      => q{<content>value</content>},
        params       => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource});
    is($req->header("Authorization"), q{Token token="access_token_value"});
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/x-www-form-urlencoded});
    is($req->content, q{buz=hoge&foo=bar});

    # With Extra Params, Content and Content-Type which is not form-urlencoded
    $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        headers      => [ 'Content-Type' => 'application/xml' ],
        oauth_params => {},
        content      => q{<content>value</content>},
        params       => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource});
    is($req->header("Authorization"), q{Token token="access_token_value"});
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/xml});
    is($req->content, q{<content>value</content>});

    # Without both of params and content
    $req = $auth->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        headers      => [ 'Content-Type' => 'application/xml' ],
        oauth_params => {},
    );
    is($req->uri, q{http://example.org/resource});
    is($req->header("Authorization"), q{Token token="access_token_value"});
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/xml});
    is($req->content, q{});

#    my $p_req = Plack::Request->new;
#    my ($token, $params) = $auth->parse($p_req);

};
#
TEST_FORM_BODY: {
    # ==============================
    # GET/DELETE (no content method)
    # ==============================
    # GET throws error
    my $error = try {
        $body->build_request(
            url          => q{http://example.org/resource},
            method       => q{GET},
            token        => q{access_token_value},
            oauth_params => {},
        );
        return undef;
    } catch {
        return $_->message;
    };
    like($error, qr/FormEncodedBody/);

    # DELETE throws error
    $error = try {
        $body->build_request(
            url          => q{http://example.org/resource},
            method       => q{DELETE},
            token        => q{access_token_value},
            oauth_params => {},
        );
        return undef;
    } catch {
        return $_->message;
    };
    like($error, qr/FormEncodedBody/);

    # invalid content-type throws error
    $error = try {
        $body->build_request(
            url          => q{http://example.org/resource},
            method       => q{POST},
            token        => q{access_token_value},
            oauth_params => {},
            headers      => [ "Content-Type" => "application/xml" ],
            content      => q{<content>value</content>},
        );
        return undef;
    } catch {
        return $_->message;
    };
    like($error, qr/FormEncodedBody/);

    # Content should be ignored
    my $req = $body->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        oauth_params => {},
        content      => q{<content>value</content>},
        params       => { foo => 'bar', buz => 'hoge' },
    );

    is($req->uri, q{http://example.org/resource});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/x-www-form-urlencoded});
    is($req->content, q{buz=hoge&foo=bar&oauth_token=access_token_value});

    # With OAuth Params
    $req = $body->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        oauth_params => {
            nonce     => q{s8djwd},
            timestamp => q{137131200},
            algorithm => q{hmac-sha256},
            signature => q{wOJIO9A2W5mFwDgiDvZbTSMK/PY=},
        },
        content      => q{<content>value</content>},
        params       => { foo => 'bar', buz => 'hoge' },
    );

    is($req->uri, q{http://example.org/resource});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/x-www-form-urlencoded});
    is($req->content, q{algorithm=hmac-sha256&buz=hoge&foo=bar&nonce=s8djwd&oauth_token=access_token_value&signature=wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D&timestamp=137131200});
};

TEST_URI_QUERY: {
    # ==============================
    # GET/DELETE (no content method)
    # ==============================
    # Without OAuth Params
    my $req = $query->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {},
    );
    is($req->uri, q{http://example.org/resource?oauth_token=access_token_value});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # With OAuth Params
    $req = $query->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {
            nonce     => q{s8djwd},
            timestamp => q{137131200},
            algorithm => q{hmac-sha256},
            signature => q{wOJIO9A2W5mFwDgiDvZbTSMK/PY=},
        },
    );
    is($req->uri, q{http://example.org/resource?algorithm=hmac-sha256&nonce=s8djwd&oauth_token=access_token_value&signature=wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D&timestamp=137131200});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # With Extra Params
    $req = $query->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {},
        params       => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource?buz=hoge&foo=bar&oauth_token=access_token_value});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # With Both Extra Params And OAuth Params
    $req = $query->build_request(
        url          => q{http://example.org/resource},
        method       => q{GET},
        token        => q{access_token_value},
        oauth_params => {
            nonce     => q{s8djwd},
            timestamp => q{137131200},
            algorithm => q{hmac-sha256},
            signature => q{wOJIO9A2W5mFwDgiDvZbTSMK/PY=},
        },
        params       => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource?algorithm=hmac-sha256&buz=hoge&foo=bar&nonce=s8djwd&oauth_token=access_token_value&signature=wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D&timestamp=137131200});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{GET});
    ok(!$req->content);

    # Post Body Without OAuth Params
    $req = $query->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        oauth_params => {},
        params => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource?oauth_token=access_token_value});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/x-www-form-urlencoded});
    is($req->content, q{buz=hoge&foo=bar});

    # Post Body With OAuth Params
    $req = $query->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        oauth_params => {
            nonce     => q{s8djwd},
            timestamp => q{137131200},
            algorithm => q{hmac-sha256},
            signature => q{wOJIO9A2W5mFwDgiDvZbTSMK/PY=},
        },
        params => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource?algorithm=hmac-sha256&nonce=s8djwd&oauth_token=access_token_value&signature=wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D&timestamp=137131200});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/x-www-form-urlencoded});
    is($req->content, q{buz=hoge&foo=bar});

    # Post Body With OAuth Params
    $req = $query->build_request(
        url          => q{http://example.org/resource},
        method       => q{POST},
        token        => q{access_token_value},
        oauth_params => {
            nonce     => q{s8djwd},
            timestamp => q{137131200},
            algorithm => q{hmac-sha256},
            signature => q{wOJIO9A2W5mFwDgiDvZbTSMK/PY=},
        },
        headers      => [ "Content-Type" => "application/xml" ],
        content      => q{<content>value</content>},
        params => {
            foo => 'bar',
            buz => 'hoge',
        },
    );
    is($req->uri, q{http://example.org/resource?algorithm=hmac-sha256&nonce=s8djwd&oauth_token=access_token_value&signature=wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D&timestamp=137131200});
    ok(!$req->header("Authorization"));
    is(uc $req->method, q{POST});
    is($req->header("Content-Type"), q{application/xml});
    is($req->content, q{<content>value</content>});

};
