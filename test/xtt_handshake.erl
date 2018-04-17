%%%-------------------------------------------------------------------
%%% @author iguberman
%%% @copyright (C) 2018, Xaptum, Inc.
%%% @doc
%%%
%%% @end
%%% Created : 19. Mar 2018 7:11 PM
%%%-------------------------------------------------------------------
-module(xtt_handshake).
-author("iguberman").

%% API
-export([test_params/0,
  client_test/0,
  client_handshake/0,
  client_TPM_handshake/0]).

-include_lib("eunit/include/eunit.hrl").
-include("xtt.hrl").

%% Defaults
-define(XTT_VERSION, ?XTT_VERSION_ONE).
-define(XTT_SUITE, ?XTT_X25519_LRSW_ED25519_AES256GCM_SHA512).
-define(EXAMPLE_DATA_DIR, "example_data").

-define(XTT_SERVER_PORT, 4445).
-define(XTT_SERVER_HOST, "localhost").

example_data_dir()->
  filename:join([xtt_erlang:priv_dir(), ?EXAMPLE_DATA_DIR]).

test_params() ->
 #{
    server => ?XTT_SERVER_HOST,
    port => ?XTT_SERVER_PORT,
    xtt_version => ?XTT_VERSION_ONE,
    xtt_suite  => ?XTT_X25519_LRSW_ED25519_AES256GCM_SHA512,
    data_dir => example_data_dir()
 }.

test_paramsTPM() ->
  #{
    server => ?XTT_SERVER_HOST,
    port => ?XTT_SERVER_PORT,
    xtt_version => ?XTT_VERSION_ONE,
    xtt_suite  => ?XTT_X25519_LRSW_ED25519_AES256GCM_SHA512,
    data_dir => example_data_dir(),
    use_tpm => true,
    tpm_host => "localhost",
    tpm_port => "2321",
    tpm_password => <<>>
  }.

test_handshake(Params)->
  application:ensure_all_started(lager),
  ensure_xtt_server_started(?XTT_SERVER_HOST, ?XTT_SERVER_PORT),
  Result = xtt_erlang:xtt_client_handshake(Params),
  io:format("Handshake complete with result ~b!~n", [Result]).

client_handshake()->
  Params = test_params(),
  io:format("Staring client test with params ~p~n", [Params]),
  test_handshake(Params).

client_TPM_handshake()->
  Params = test_paramsTPM(),
  io:format("Staring client TPM test with params ~p~n", [Params]),
  test_handshake(Params).

client_test()->
  client_handshake(),
  timer:sleep(10000),
  client_TPM_handshake().

ensure_xtt_server_started(ServerHost, ServerPort)->
  %% Check if running or
  %% Find xtt install dir and run
  %%os:cmd(?XTT_INSTALL_DIR ++ "/xtt_server " ++ integer_to_list(ServerPort)),
  ok.




