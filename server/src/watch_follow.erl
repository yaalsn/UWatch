-module(watch_follow).
-export([add/2,del/2,list/0,list/1,del4user/1,update/2]).

add(Owner,Follower)     -> watch_db:add_follow(Owner,Follower).
del(Owner,Follower)     -> watch_db:del_follow(Owner,Follower).
del4user(Owner)         -> watch_db:del4user_follow(Owner).
update(Owner, Follower) -> watch_db:update_follow(Owner, Follower).

list() -> lists:map( fun(X) -> {I,U} = X, I++ ":" ++ U end, watch_db:list_follow()).
list(USER) -> watch_db:list_follow(USER).
