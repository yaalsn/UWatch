-module(watch_method).
-compile(export_all).

addmethod(User,Method) -> watch_db:add_method(User,Method).
getmethod(User) -> 
    case watch_db:get_method(User) of
        [ M ] -> M;
        _ -> ""
    end.

delmethod(User) -> watch_db:del_method(User).

listmethod() -> lists:map(fun(X)->{User, Value} = X, User++":"++Value end,watch_db:list_method()).
