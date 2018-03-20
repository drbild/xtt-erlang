-module(xtt_erlang).

%% API exports
-export([xtt_client_handshake/1,
  xtt_client_handshake_context/2,
  xtt_build_client_init/1,
  xtt_build_error_msg/0]).

-export([priv_dir/0]).

-include("xtt.hrl").

-define(APPNAME, xtt_erlang).
-define(LIBNAME, 'xtt_erlang').

-define(TCP_OPTIONS, [binary, {packet, 2}, {keepalive, true}]).

init() ->
  SoName = filename:join([priv_dir(), ?LIBNAME]),
  erlang:load_nif(SoName, 0).

priv_dir() ->
  case code:priv_dir(?APPNAME) of
    {error, bad_name} ->
      case filelib:is_dir(filename:join(["..", priv])) of
        true ->
          filename:join(["..", priv]);
        _ -> "priv"
      end;
    Dir -> Dir
  end.


%%====================================================================
%% API functions
%%====================================================================

xtt_client_handshake(PropertyFileName) when is_list(PropertyFileName)->
  {ok, PropertiesBin} = file:read_file(PropertyFileName),
  xtt_client_handshake(convert_to_map(PropertiesBin));
xtt_client_handshake(#{ server := ServerName,
                        port := Port,
                        xtt_version := XttVersion,
                        xtt_suite := XttSuite} = ParameterMap) ->

  {RequestedClientId, IntendedServerId} = initialize_ids(ParameterMap),
  GroupContext = initialize_daa(ParameterMap),

  {ok, Socket} = gen_tcp:connect(ServerName, Port, ?TCP_OPTIONS),
  XttHandshakeContext = xtt_client_handshake_context(XttVersion, XttSuite),
  OutputBuffer = xtt_build_client_init(XttHandshakeContext),
  gen_tcp:send(Socket, OutputBuffer),
  {ok, RespBuffer} = gen_tcp:recv(Socket, 0),
  io:format("Finished client init!  Received buffer ~p from server ~p", [RespBuffer, ServerName]).


%%====================================================================
%% NIFs
%%====================================================================

xtt_client_handshake_context(_XttVersion, _XttSuite)->
  erlang:nif_error(?LINE).

xtt_build_client_init(_XttClientHandshakeContext)->
  erlang:nif_error(?LINE).

xtt_build_error_msg()->
  erlang:nif_error(?LINE).


%%====================================================================
%% Internal functions
%%====================================================================

convert_to_map(PropertiesBin) when is_binary(PropertiesBin)->
  ok.


initialize_ids(#{requested_client_id_file := RequestedClientIdFile, server_id_file := IntendedServerIdFile})->
  initialize_ids(RequestedClientIdFile, IntendedServerIdFile);
initialize_ids(#{data_dir := DataDir})->
  RequestedClientIdFile = filename:join([DataDir, ?REQUESTED_CLIENT_ID_FILE]),
  IntendedServerIdFile = filename:join([DataDir, ?SERVER_ID_FILE]),
  initialize_ids(RequestedClientIdFile, IntendedServerIdFile);
initialize_ids(#{})->
  RequestedClientIdFile = filename:join([?DEFAULT_DATA_DIR, ?REQUESTED_CLIENT_ID_FILE]),
  IntendedServerIdFile = filename:join([?DEFAULT_DATA_DIR, ?SERVER_ID_FILE]),
  initialize_ids(RequestedClientIdFile, IntendedServerIdFile).

initialize_ids(RequestedClientIdFile, IntendedServerIdFile)->
  {ok, RequestedClientId} = file:read_file(RequestedClientIdFile),
  ?XTT_IDENTITY_SIZE = size(RequestedClientId),
  {ok, IntendedServerId} = file:read_file(IntendedServerIdFile),
  ?XTT_IDENTITY_SIZE = size(IntendedServerId),
  {RequestedClientId, IntendedServerId}.



initialize_daa(#{use_tpm := UseTpm} = ParameterMap) when is_boolean(UseTpm)->
  initialize_daa(UseTpm, ParameterMap);
initialize_daa(#{} = ParameterMap)->
  initialize_daa(false, ParameterMap).


initialize_daa(UseTpm, #{data_dir := DataDir} = ParameterMap) ->
  BasenameFile = maps:get(base_filename, ParameterMap, filename:join([DataDir, ?BASENAME_FILE])),
  GpkFile = maps:get(gpk_filename, ParameterMap, filename:join([DataDir, ?DAA_GPK_FILE])),
  CredFile = maps:get(cred_filename, ParameterMap, filename:join([DataDir, ?DAA_CRED_FILE])),
  PrivKeyFile = maps:get(priv_key_filename, ParameterMap, filename:join([DataDir, ?DAA_SECRETKEY_FILE])),

  {ok, Basename} = file:read_file(BasenameFile),
  true = size(Basename) > 0,

  {ok, Gpk} = file:read_file(GpkFile),
  ?XTT_DAA_GROUP_PUB_KEY_SIZE = size(Gpk),

  {ok, Credential} = file:read_file(CredFile),
  ?XTT_DAA_CREDENTIAL_SIZE = size(Credential),

  {ok, PrivKey} = file:read_file(PrivKeyFile),
  ?XTT_DAA_PRIV_KEY_SIZE = size(PrivKey).