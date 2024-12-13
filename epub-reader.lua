os.setlocale('') -- set native locale

local logger = require('jls.lang.logger')
local system = require('jls.lang.system')
local event = require('jls.lang.event')
local File = require('jls.io.File')
local FileHttpHandler = require('jls.net.http.handler.FileHttpHandler')
local ResourceHttpHandler = require('jls.net.http.handler.ResourceHttpHandler')
local TableHttpHandler = require('jls.net.http.handler.TableHttpHandler')
local WebView = require('jls.util.WebView')

local options = system.createArgumentTable({
  helpPath = 'help',
  emptyPath = 'file',
  schema = {
    title = 'EPUB Reader',
    type = 'object',
    additionalProperties = false,
    properties = {
      loglevel = {
        title = 'The log level',
        type = 'string',
        default = 'warn',
      },
      file = {
        title = 'The EPUB file or folder',
        type = 'string',
        required = true,
      },
      webview = {
        type = 'object',
        additionalProperties = false,
        properties = {
          debug = {
            title = 'Enable WebView debug mode',
            type = 'boolean',
            default = false,
          },
          port = {
            title = 'WebView HTTP server port',
            type = 'integer',
            default = 0,
            minimum = 0,
            maximum = 65535,
          },
          width = {
            title = 'The WebView width',
            type = 'integer',
            default = 600,
            minimum = 320,
            maximum = 7680,
          },
          height = {
            title = 'The WebView height',
            type = 'integer',
            default = 800,
            minimum = 240,
            maximum = 4320,
          },
        }
      },
    },
  },
  aliases = {
    h = 'help',
    f = 'file',
  },
})

logger:setConfig(options.loglevel)

local handler, url

if options.file then
  local file = File:new(options.file)
  if file:isFile() and (file:getExtension() == 'zip' or file:getExtension() == 'epub') then
    logger:info('ZIP file detected')
    local ZipFileHttpHandler = require('jls.net.http.handler.ZipFileHttpHandler')
    handler = ZipFileHttpHandler:new(file)
  else
    handler = FileHttpHandler:new(file)
  end
  url = 'http://localhost:'..tostring(options.webview.port)..'/'
else
  url = WebView.toDataUrl([[<!DOCTYPE html><html><body><p>No EPUB file argument</p></body></html>]])
end

WebView.open(url, {
  title = 'EPUB Reader',
  resizable = true,
  bind = true,
  width = options.webview.width,
  height = options.webview.height,
  debug = options.webview.debug,
  contexts = {
    -- HTTP resources
    ['/(.*)'] = ResourceHttpHandler:new('htdocs/', 'app.html'),
    -- Context to retrieve the configuration
    ['/config/(.*)'] = TableHttpHandler:new(options, nil, true),
    -- Assets HTTP resources directory or ZIP file
    ['/(assets/.*)'] = ResourceHttpHandler:new(),
    -- Context for the EPUB
    ['/epub/(.*)'] = handler,
  },
}):next(function(webview)
  local httpServer = webview:getHttpServer()
  if httpServer then
    logger:info('Server available at http://localhost:%s/', (select(2, httpServer:getAddress())))
  end
  return webview:getThread():ended()
end):next(function()
  logger:info('WebView closed')
end, function(reason)
  logger:warn('Cannot open webview due to '..tostring(reason))
end)

event:loop()
