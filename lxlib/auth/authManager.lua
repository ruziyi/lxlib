
local lx, _M, mt = oo{
    _cls_   = '',
    _ext_   = 'manager',
    _bond_  = 'authFactoryBond',
    _mix_   = 'auth.createUserProvider'
}

local app, lf, tb, str, new = lx.kit()

function _M:ctor()

    self.inCtx = true

    self.userResolver = function(guard)
        
        return self:guard(guard):user()
    end
end

function _M:guard(name)

    return self:resolve(name)
end

function _M:createSessionDriver(config)

    local name = config.driver
    local provider = self:createUserProvider(config['provider'])
    local guard = new('auth.sessionGuard', name, provider, app['session.store'])
    
    if guard:__has('setCookieJar') then
        guard:setCookieJar(app['cookie'])
    end
    if guard:__has('setRequest') then
        guard:setRequest(app:refresh('request', guard, 'setRequest'))
    end
    
    return guard
end

function _M:createTokenDriver(config)

    local guard = new('auth.tokenGuard', 
        self:createUserProvider(config['provider']), app['request']
    )
    app:refresh('request', guard, 'setRequest')
    
    return guard
end

function _M.__:getConfig(name)

    return app['config']['auth.guards.' .. name]
end

function _M:getDefaultDriver()

    return app['config']['auth.defaults.guard']
end

function _M:shouldUse(name)

    name = name or self:getDefaultDriver()
    self:setDefaultDriver(name)
    self.userResolver = function(name)
        
        return self:guard(name):getUser()
    end
end

function _M:setDefaultDriver(name)

    app:conf('auth.defaults.guard', name)
end

function _M:viaRequest(driver, callback)

    return self:extend(driver, function()
        guard = new('auth.requestGuard', callback, app['request'])
        app:refresh('request', guard, 'setRequest')
        
        return guard
    end)
end

function _M:resolveUsersUsing(userResolver)

    self.userResolver = userResolver
    
    return self
end

function _M:extend(driver, callback)

    self.customCreators[driver] = callback
    
    return self
end

function _M:provider(name, callback)

    self.customProviderCreators[name] = callback
    
    return self
end

function _M:_run_(method)

    return 'guard'
end

return _M

