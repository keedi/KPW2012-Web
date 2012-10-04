#!/usr/bin/env perl

use 5.010;
use utf8;

use Mojolicious::Lite;

use Text::MultiMarkdown;
use Validator::Custom;

my $m = Text::MultiMarkdown->new(
    tab_width     => 2,
    use_wikilinks => 0,
);

my $config = plugin 'Config';
my %DEFAULT_STASH = (
    active => q{},
    %$config,
);
app->defaults(%DEFAULT_STASH);

my $vc = Validator::Custom->new;

helper markdown => sub {
    my ( $self, $text ) = @_;
    return unless $text;
    my $html = $m->markdown($text);
    return $html;
};

helper login => sub {
    my ( $self, $username, $password, $remember ) = @_;

    return unless $username;
    return unless $password;
    return unless $self->app->config->{users};
    return unless $self->app->config->{users}{data};

    my $email = $username;
    if ($username =~ /\@/) {
        for my $_username ( keys %{ $self->app->config->{users}{data} } ) {
            if ( $email eq $self->app->config->{users}{data}{$_username}{email} ) {
                $username = $_username;
                last;
            }
        }
    }
    else {
        $email = $self->app->config->{users}{data}{$username}{email};
    }

    $self->session(
        user         => $self->app->config->{users}{data}{$username},
        expiration   => $remember ?  $self->app->config->{expire}{remember} : $self->app->config->{expire}{default},
    );

    $self->app->log->debug("login success");

    return 1;
};

any '/' => 'index';

get '/logout' => sub {
    my $self = shift;

    $self->session(expires => 1);
    $self->redirect_to('/');
};

app->secret( app->defaults->{secret} );
app->start;

__DATA__

@@ section-home.html.ep
    <section id="section-home" class="page-section">
      <div class="content row">
        <div class="row">
          <div class="col_8 last">
            <h1>Korean <span class="text-color">Perl</span> Workshop 2012</h1>
            <h2>
              on <span class="text-color">Sat. Oct. 20th, 2012</span>
              <br />
              <span class="text-color">Register</span> Now!
            </h2>
          </div>
        </div>
        <div class="row">
          <div class="col_4 last">
            <a class="large-circular-down-arrow" href="#section-register" id="subnav"></a>
          </div>
        </div>
      </div>
    </section>


@@ section-register.html.ep
    <section id="section-register" class="page-section">
      <header class="row">
        <div class="col_6 last"> <h1>Register.</h1> </div>
      </header>
      <div class="content">
        <form action="/register" method="post">
          <div class="row">
            <div class="col_6 pre_4">
              <p>
              
                KPW 2012의 참가비는 <span class="text-color">1만원</span>입니다.
                아래 등록 양식을 작성하신 후 참가비를 납부해주세요.
                납부 완료후 확인이 끝나면 <span class="text-color">"확정"</span>
                명단에 들어갑니다.  납부가 완료되지 않으면
                <span class="text-color">"대기"</span> 명단에 들어갑니다.
              </p>
              <p>
                <span class="text-color">우리은행: 461-162011-02-101 (김도형)</span>
              </p>
            </div>
          </div>
          <div class="row">
            <div class="col_4">
              <label for="id_email">Email</label>
            </div>
            <div class="col_6 suf_2 last">
              <div class="form-holder">
                <input type="text" name="email" id="id_email" placeholder="등록 확인 메일을 전송할 주소" />
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col_4">
              <label for="id_subject">Name</label>
            </div>
            <div class="col_6 suf_2 field-holder last">
              <div class="form-holder">
                <input id="id_name" type="text" name="name" maxlength="150" placeholder="입금자명과 동일"/>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col_4">
              <label for="id_subject">Twitter</label>
            </div>
            <div class="col_6 suf_2 field-holder last">
              <div class="form-holder">
                <input id="id_twitter" type="text" name="twitter" maxlength="150" placeholder="트위터 주소"/>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col_4">
              <label for="id_message">Message</label>
            </div>
            <div class="col_6 suf_2 field-holder last">
              <div class="form-holder">
                <textarea id="id_message" rows="10" cols="40" name="message" placeholder="행사에 바라는 점"></textarea>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col_1 pre_9">
              <a href="#" class="submit-button suf_1">Submit</a>
            </div>
          </div>
        </form>
      </div>
    </section>


@@ section-schedule.html.ep
    <section id="section-schedule" class="page-section-scroll">
      <header class="row">
        <div class="col_6 last">
          <h1>Schedule.</h1>
        </div>
      </header>
      <div class="content">
        % for my $text (@$schedules) {
          <div class="row">
            <div class="col_8 pre_1">
              <%== markdown $text %>
            </div> <!-- col_5 -->
          </div> <!-- row -->
        % }
        <div class="spacer"></div>
      </div>
    </section>


@@ section-attender.html.ep
    <section id="section-attender" class="page-section-scroll">
      <header class="row">
        <div class="col_6 last">
        <h1>Attenders.</h1>
        </div>
      </header>
      <div class="content">

        <div class="row">
          <div class="col_8 pre_1">
            <p>
              프로필 사진은 <a href="http://en.gravatar.com/" alt="Gravatar">Gravatar</a>에
              등록된 사진으로 표시됩니다.
              지금 바로 <a href="http://en.gravatar.com/" alt="Gravatar">Gravatar</a>에
              여러분의 전자우편 주소와 프로필 사진을 등록하세요! :-)
            </p>
          </div>
        </div> <!-- row -->

        <div class="row">
          <div class="col_8 pre_1">
            <h2>Confirmed.</h2>
          </div>
        </div> <!-- row -->

        <div class="row">
          % for (qw/ keedi ja3ck /) {
            <div class="col_2">
              <div class="profile confirmed">
                <p> <img class="profile-confirmed-image" src="/img/<%= $_ %>.jpg" alt="<%= $_ %>" /> <br/> <%= $_ %><p/>
              </div>
            </div>
          % }
        </div>

        <div class="row">
          <div class="col_8 pre_1">
            <h2>Waiting.</h2>
          </div>
        </div> <!-- row -->

        <div class="row">
          % for (qw/ JEEN_LEE yongbin aanoaa rumidier /) {
            <div class="col_1">
              <div class="profile waiting">
                <p> <img class="profile-waiting-image" src="/img/<%= $_ %>.jpg" alt="<%= $_ %>" /> <br/> <%= $_ %><p/>
              </div>
            </div>
          % }
        </div>

        <div class="spacer"></div>
      </div>
    </section>


@@ section-contact.html.ep
    <section id="section-contact" class="page-section">
      <header class="row">
        <div class="col_6 last"> <h1>Contact.</h1> </div>
      </header>
      <div class="content">
        <form action="/contact" method="post">
          <div class="row">
            <div class="col_6 pre_4">
              <p>
                <span class="text-color">KPW 2012</span>이나
                <span class="text-color">Seoul.pm</span>에 대해
                궁금한 점이 있거나 전하고 싶은 말이 있다면 알려주세요.
                저희는 여러분의 소중한 의견을 듣고 싶습니다.
              </p>
            </div>
          </div>
          <div class="row">
            <div class="col_4">
              <label for="id_email">Email</label>
            </div>
            <div class="col_6 suf_2 last">
              <div class="form-holder">
                <input type="text" name="email" id="id_email" placeholder="답장을 받을 메일 주소" />
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col_4">
              <label for="id_subject">Subject</label>
            </div>
            <div class="col_6 suf_2 field-holder last">
              <div class="form-holder">
                <input id="id_subject" type="text" name="subject" maxlength="150" placeholder="제목을 입력하세요." />
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col_4">
              <label for="id_message">Message</label>
            </div>
            <div class="col_6 suf_2 field-holder last">
              <div class="form-holder">
                <textarea id="id_message" rows="10" cols="40" name="message" placeholder="내용을 입력하세요."></textarea>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col_1 pre_9">
              <a href="#" class="submit-button suf_1">Submit</a>
            </div>
          </div>
        </form>
      </div>

      %= include 'layouts/footer'

    </section>


@@ index.html.ep
% layout 'onepage',
%   csses => [ qw( /css/boilerplate.css /css/onepage.css  ) ],
%   jses  => [ qw( jquery.nav.js jquery.scrollTo.js onepage.js ) ];
%
% title 'Korean Perl Workshop 2012';
%= include 'section-home'
%= include 'section-register'
%= include 'section-schedule'
%= include 'section-attender'
%= include 'section-contact'


@@ layouts/onepage.html.ep
<!DOCTYPE html>
<!--[if lt IE 7]> <html class="no-js lt-ie9 lt-ie8 lt-ie7" lang="en"> <![endif]-->
<!--[if IE 7]>    <html class="no-js lt-ie9 lt-ie8" lang="en"> <![endif]-->
<!--[if IE 8]>    <html class="no-js lt-ie9" lang="en"> <![endif]-->
<!--[if gt IE 8]><!-->
<html class="no-js" lang="en">
  <!--<![endif]-->
  <head>
    <meta charset="utf-8">
    <title><%= $project_name %> - <%= title %></title>
    <meta name="author" content="<%= $meta->{author} %>" />
    <meta name="keywords" content="<%= $meta->{keywords} %>" />
    <meta name="description" content="<%= $meta->{description} %>" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    %= include 'layouts/head-load'
  </head>

  <body>
    %= include 'layouts/nav'
    %= include 'layouts/sponsors'
    %= include 'layouts/header'
    <%= content %>
    %= include 'layouts/body-load'
  </body>
</html>


@@ layouts/head-load.html.ep
    <!--

      Site design is stolen from William Dady's homepage.

      Visit http://williamdady.com/ and look around his beautiful site. :)

    -->

    <link rel="icon" href="/favicon.ico" type="image/x-icon" />
    <link rel="apple-touch-icon-precomposed" sizes="144x144" href="/img/apple-touch-icon-144x144-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="114x114" href="/img/apple-touch-icon-114x114-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="72x72" href="/img/apple-touch-icon-72x72-precomposed.png">
    <link rel="apple-touch-icon-precomposed" href="/img/apple-touch-icon-precomposed.png">

    <link rel="stylesheet" href="/font-awesome/css/font-awesome.css">
    % for my $css (@$csses) {
      <link type="text/css" rel="stylesheet" href="<%= $css %>"> 
    % }
    <script src="/js/modernizr.js"></script>


@@ layouts/body-load.html.ep
    <!-- Le javascript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->

    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/jquery-ui.min.js"></script>

    % for my $js (@$jses) {
      <script type="text/javascript" src="/js/<%= $js %>"></script>
    % }

    % if ($google_analytics) {
      <!-- google analytics -->
      <script type="text/javascript">
        var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
        document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
      </script>
      <script type="text/javascript">
        try {
          var pageTracker = _gat._getTracker("<%= $google_analytics %>");
          pageTracker._trackPageview();
        } catch(err) {}
      </script>
    % }


@@ layouts/header.html.ep
            <!-- nothing now -->
            <div id="forkme">
              <a href="https://github.com/seoulpm/KPW2012-Web">
                <img
                  style="z-index: 99; position: absolute; top: 0; left: 0; border: 0;"
                  src="https://s3.amazonaws.com/github/ribbons/forkme_left_red_aa0000.png"
                  alt="Fork me on GitHub">
              </a>
            </div>


@@ layouts/footer.html.ep
      <footer>
        <div class="social-links">
          <ul>
            <li>
              <a href="https://twitter.com/seoulpm" target="_blank">
                <img src="img/twitter_button.png" alt="twitter button" />
              </a>
            </li>
            <li>
              <a href="http://www.facebook.com/groups/perl.kr/" target="_blank">
                <img src="img/facebook_button.png" alt="facebook button" />
              </a>
            </li>
          </ul>
        </div>
        <div class="row">
          <div class="col_4 pre_1">
            <p class="copyright">
              &copy; <%= $copyright %>. All Rights Reserved.
            </p>
          </div>
          <div class="col_4 pre_1">
            <p class="builtby">
              Built by
                <a href="http://mojolicio.us/">Mojolicious</a> &amp;
                <a href="http://www.perl.org/">Perl</a>
            </p>
          </div>
        </div>
      </footer>


@@ layouts/nav.html.ep
    <nav id="main-nav">
      <ul>
        % for my $link (@$header_links) {
          <li class="<%= $link->{active} ? 'active' : q{} %>">
            <a href="<%= $link->{url} %>">
              <div class="label"><p><%= $link->{title} %></p></div>
              <i class="navicon <%= $link->{icon} %>"></i>
            </a>
          </li>
        % }
      </ul>
    </nav>


@@ layouts/sponsors.html.ep
    <div id="sponsors">
      <h2> Sponsors </h2>
      <ul>
        % for my $link (@$sponsors) {
          <li>
            <a href="<%= $link->{url} %>" alt="<%= $link->{title} %>">
              <div class="sponsor-image" id="<%= $link->{icon} %>"></div>
            </a>
          </li>
        % }
      </ul>
    </div>


@@ layouts/error.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title><%= $project_name %> - <%= title %></title>
    %= include 'layouts/head-load'
  </head>

  <body>
    %= include 'layouts/nav'

    <div id="content">
      <div class="container">
        <div class="row">

          <div class="span2">
            %= include 'layouts/header'
          </div> <!-- span2 -->

          <div class="span10">
            <div class="error-container">
              <%= content %>
            </div> <!-- error-container >
          </div> <!-- span10 -->

        </div> <!-- /row -->
      </div>
    </div> <!-- /content -->

    %= include 'layouts/footer'
    %= include 'layouts/body-load'
  </body>
</html>


@@ not_found.html.ep
% layout 'error', csses => [ 'error.css' ], jses => [];
% title '404 Not Found';
<h2>404 Not Found</h2>

<div class="error-details">
  Sorry, an error has occured, Requested page not found!
</div> <!-- /error-details -->


@@ layouts/login.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title><%= $project_name %> - <%= title %></title>
    %= include 'layouts/head-load'
  </head>

  <body>
    %= include 'layouts/nav'

    <div id="login-container">
      <%= content %>
    </div> <!-- login-container -->

    %= include 'layouts/footer'
    %= include 'layouts/body-load'

    <script type="text/javascript">
      $('#login-container input').first().focus();
    </script>

</script>
  </body>
</html>


@@ login.html.ep
% layout 'login', csses => [ 'login.css' ], jses => [];
% title 'Login';
<div id="login-header">
  <h3> <i class="icon-lock"></i> Login </h3>
</div> <!-- /login-header -->

<div id="login-content" class="clearfix">

  <form action="/" method="post">
    <fieldset>
      <div class="control-group">
        <label class="control-label" for="username">Username</label>
        <div class="controls"> <input type="text" class="" id="username" name="username"> </div>
      </div>
      <div class="control-group">
        <label class="control-label" for="password">Password</label>
        <div class="controls"> <input type="password" class="" id="password" name="password"> </div>
      </div>
    </fieldset>

    <div id="remember-me" class="pull-left">
      <input type="checkbox" name="remember" id="remember" />
      <label id="remember-label" for="remember">Remember Me</label>
    </div>

    <div class="pull-right">
      <button type="submit" class="btn btn-warning btn-large"> Login </button>
    </div>
  </form>

</div> <!-- /login-content -->

<div id="login-extra">
  <p>Fotgot Password? <a href="mailto:keedi.k@gmail.com">Contact Us.</a></p>
</div> <!-- /login-extra -->