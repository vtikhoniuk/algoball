#!/usr/bin/env tarantool

require('strict').on()

package.setsearchroot()

local cartridge = require('cartridge')
local ok, err = cartridge.cfg({
    roles = {
        'cartridge.roles.vshard-storage',
        'cartridge.roles.vshard-router',
        'cartridge.roles.metrics',
        'app.roles.router',
        'app.roles.storage',
    }
})

assert(ok, tostring(err))

-- register admin function to use it with 'cartridge admin' command

local admin = require('app.admin')
admin.init()

local metrics = require('cartridge.roles.metrics')
metrics.set_export({
    {
        path = '/metrics',
        format = 'prometheus'
    },
    {
        path = '/health',
        format = 'health'
    }
})
