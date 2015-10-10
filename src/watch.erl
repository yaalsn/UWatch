-module(watch).
-export([start/1]).

start(Port) ->

  watch_db:init(),
  watch_db:start(),


  watch_item:start(),
  watch_user:start(),
  watch_notify:start(),
  watch_waiter:start(Port),
  watch_mesg:start(),
  watch_stat:start().

