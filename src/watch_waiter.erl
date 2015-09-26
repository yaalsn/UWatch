-module(watch_waiter).
-export([start/1]).

-define(TCP_OPTIONS, [ list, {packet, 0}, {active, false}, {reuseaddr, true}]).

start(Port) ->
  Pid = spawn(fun() -> manage() end),
  register(waiter_manager,Pid),

  {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
  io:format("port:~w~n", [Port]),
  do_accept(LSocket).

do_accept(LSocket) ->
  case gen_tcp:accept(LSocket) of
      {ok, Socket} ->
 
          case inet:peername(Socket) of 
              {ok, {Address,_}} -> IP_Address = Address;
              _ -> IP_Address = '0.0.0.0'
          end,
          case watch_auth:check_ip( IP_Address ) of
            true -> 
              io:format("[WARM] wolcome:~p~n", [ IP_Address ] ),
              spawn(fun() -> handle_client(Socket) end);
            false ->
              io:format("[WARM] IP_Address:~p deny~n", [ IP_Address ] ),
              gen_tcp:send( Socket, "deny" ),
              gen_tcp:close( Socket )
       end;
       {error, Reason} -> io:format( "~p~n", Reason )
   end,
   do_accept(LSocket).

handle_client(Socket) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, "data"} -> 
        gen_tcp:send( Socket, "data modle" ),
        handle_item(Socket);
    {ok, Data} ->
        case string:tokens( Data, " /" ) of
            ["GET","relate","add",ITEM,USER|_] -> 
              lists:foreach( fun(X) -> watch_relate:add(X,USER) end,string:tokens( ITEM, ":" ) ), ok( Socket );
            ["GET","relate","del",ITEM,USER|_] ->
              lists:foreach( fun(X) -> watch_relate:del(X,USER) end,string:tokens( ITEM, ":" ) ), ok( Socket );
            ["GET","relate","list"|_]  ->
               ok( Socket, lists:map( fun(X) -> {I,U} = X, I++ ":" ++ U end,watch_relate:list()));
            ["GET","relate","list4user",USER|_]  ->
               ok( Socket, watch_relate:list4user(USER) );

            ["GET", "item","add",ITEM|_]     -> watch_item:add(ITEM), ok( Socket );
            ["GET", "item","del",ITEM|_]     -> watch_item:del(ITEM), ok( Socket );
            ["GET", "item","list"| _]        -> ok( Socket, watch_item:list() );
            ["GET", "item","mesg",ITEM|_]  -> ok( Socket, watch_item:disk_log(ITEM, "mesg" ) );
            ["GET", "item","count",ITEM|_] -> ok( Socket, watch_item:disk_log(ITEM, "count" ) );

            ["GET","user","add",USER,PASS|_]  -> watch_user:add(USER, PASS ),ok( Socket );
            ["GET","user","del", USER|_]        -> watch_user:del(USER), ok( Socket );
            ["GET","user","list"|_]           -> ok( Socket, watch_user:list() );
            ["GET","user","mesg",USER,ITEM|_]     -> ok( Socket, watch_user:mesg(USER,ITEM) );
            ["GET","user","getinfo",USER|_]      -> ok( Socket, [ watch_user:getinfo(USER) ] );
            ["GET","user","setinfo",USER,INFO|_] -> watch_user:setinfo(USER,INFO), ok( Socket );
            ["GET","user","auth",USER,PASS|_] -> 
               gen_tcp:send( Socket, watch_user:auth(USER,PASS) ), gen_tcp:close( Socket );

            ["GET","follow","add",Owner,Follower|_] -> 
              lists:foreach( 
                fun(X) -> watch_follow:add(X,Follower) end,string:tokens( Owner, ":" ))
              , ok( Socket );
            ["GET","follow","del",Owner,Follower|_] -> 
              lists:foreach( 
                fun(X) -> watch_follow:del(X,Follower) end,string:tokens( Owner, ":" ))
              , ok( Socket );
            ["GET","follow","list"|_] -> ok( Socket, watch_follow:list() );
            ["GET","follow","list4follower",Follower|_]  -> ok( Socket, watch_follow:list(Follower) );

            ["GET","stat","list"|_]           -> ok( Socket, watch_stat:list() );
            ["GET","last","list"|_]           -> ok( Socket, watch_last:list() );
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
       lists:map( fun(X) -> waiter_manager ! {X} end, string:tokens( Data, "\n" ) ),
       handle_item( Socket );
    {error, closed} -> io:format( "close~n" ), gen_tcp:close( Socket )
  end.

manage() ->
  receive
    { Data } ->
      DATA = string:tokens(Data,"#"),
      case length(DATA) > 2 of
          true ->
              [ MARK, ITEM | D ] = DATA,
              case MARK == "@@" of
                 true ->
                  NAME = list_to_atom( "item_list#"++ ITEM ),
                  try
                      NAME ! { "data", string:join(D,"#") }
                  catch
                      error:badarg -> watch_item:add(ITEM)
                  end;
                  false -> false
              end;
          false -> false
      end
  end,
  manage().

ok( Socket ) ->
  gen_tcp:send( Socket, "ok" ), gen_tcp:close( Socket ).

ok( Socket, List ) ->
  lists:map( fun(X) -> gen_tcp:send( Socket, X ++"\n" ) end, List ),
  gen_tcp:close( Socket ).
