-module(watch_waiter).
-export([start/1]).

%-define(TCP_OPTIONS, [ binary,{active,false},{packet,2} ]).
-define(TCP_OPTIONS, [ list, {packet, 0}, {active, false}, {reuseaddr, true}]).

start(Port) ->

  Pid = spawn( fun() -> manage() end ),
  register( xxrelate_manager, Pid ),

  {ok, LSocket} = gen_tcp:listen( Port, ?TCP_OPTIONS ),
  io:format( "port:~w~n", [Port] ),
  do_accept(LSocket).

do_accept(LSocket) ->
  {ok, Socket} = gen_tcp:accept(LSocket),

  {ok, {IP_Address, Port}} = inet:peername(Socket),

  case watch_auth:check_ip( IP_Address ) of
    true -> 
      io:format("IP_Address:~p:~p~n", [ IP_Address, Port ] ),
      spawn(fun() -> register_client(Socket ) end),
      do_accept(LSocket);
   false ->
      io:format("IP_Address:~p deny~n", [ IP_Address ] ),
      gen_tcp:close( Socket ),
      do_accept( LSocket )
   end.


register_client(Socket) ->
  case gen_tcp:recv(Socket, 0) of
%    {ok, "ctrl"} -> 
%        gen_tcp:send( Socket, "ctrl modle" ),
%        handle_ctrl(Socket);
    {ok, "data"} -> 
        gen_tcp:send( Socket, "data modle" ),
        handle_item(Socket);
    {ok, Data} ->
        case string:tokens( Data, " /" ) of
            [ "GET", "relate", "list" | _ ] ->
               gen_tcp:send( Socket, "xxxxxxxxxx" ),
               relate_manager ! {"list", Socket },
               gen_tcp:close( Socket );
            [ "GET", "relate", "add", ITEM, USER| _] ->
               relate_manager ! {"add", ITEM, USER },
               gen_tcp:send( Socket, "ok" ),
               gen_tcp:close( Socket );
            [ "GET", "relate", "del", ITEM, USER| _] ->
               relate_manager ! {"del", ITEM, USER },
               gen_tcp:send( Socket, "ok" ),
               gen_tcp:close( Socket );
            [ "GET", "datalist", "add", ITEM, USER| _] ->
               item_manager ! {"add", ITEM, USER },
               gen_tcp:send( Socket, "ok" ),
               gen_tcp:close( Socket );
 
            _ -> 
               gen_tcp:send( Socket, "undefinition" ),
               gen_tcp:close( Socket )
        end;
    {error, closed} ->
      io:format( "register fail" )
  end.


handle_item( Socket ) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, Data} ->
 %      io:format( "data:~p ~n", [ Data ] ),
       DATA = string:tokens( Data, "\n" ),
       lists:map( fun(X) -> xxrelate_manager ! {X} end, DATA ),
       handle_item( Socket );
    {error, closed} -> io:format( "close" ), gen_tcp:close( Socket )
  end.

manage( ) ->
  receive
    { Data } ->
%%      io:format( "data:~p ~n", [ Data ] ),
      DATA = string:tokens( Data, "#" ),
      case length(DATA) > 2 of
          true ->
              [ MARK, LISTNAME | D ] = DATA,
              case MARK == "@@" of
                 true ->
                  NAME = list_to_atom( "item_list#"++ LISTNAME ),
                  try
                      NAME ! { "data", string:join(D, "#") }
                  catch
                      error:badarg -> item_manager ! { "add", LISTNAME }
                  end;
                  false -> false
              end;
          false -> false
      end
  end,
  manage( ).


%% handle_ctrl(Socket) ->
%%   case gen_tcp:recv(Socket, 0) of
%%     {ok, Data} ->
%%       CTRL = string:tokens( Data, "#" ),
%%       case length(CTRL) of
%%         2 ->
%%             case list_to_tuple( CTRL ) of
%%               { "relate", "list" } ->
%%                 relate_manager ! {"list", Socket };
%%               Other -> io:format( "commaaaaaaaaaand undef~n" )
%%             end;
%% 
%%         3 ->
%%             case list_to_tuple( CTRL ) of
%%               { "datalist", "add", CNAME } ->
%%                 item_manager ! {"add", CNAME };
%%               Other -> io:format( "command undef~n" )
%%             end;
%%         4 ->
%%             case list_to_tuple( CTRL ) of
%%               { "relate", "del", CNAME, CUSER } ->
%%                 relate_manager ! {"del", CNAME, CUSER };
%%               { "relate", "add", CNAME, CUSER } ->
%%                 relate_manager ! {"add", CNAME, CUSER };
%%               Other -> io:format( "command undef~n" )
%%             end;
%%         Etrue -> io:format( "error command~n" )
%%       end,
%%       handle_ctrl( Socket );
%%     {error, closed} ->
%%       gen_tcp:close( Socket )
%%   end.
%% 
