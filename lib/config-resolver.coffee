{CompositeDisposable} = require 'atom'
toml = require 'toml'
path = require 'path'
fs = require 'fs-plus'
$ = require 'jquery'

class ConfigResolver
  subscriptions: null
  configFileName: '.impress.toml'
  resolvedConfigs: {}
  globalConfig: null
  localConfigs: {}

  constructor: ->
    @_loadGlobalConfig()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.project.onDidChangePaths (projPaths) =>
      @_deleteUnneededConfigs projPaths
      @_resolveNewProjectConfigs projPaths
    @subscriptions.add atom.config.onDidChange => @_loadGlobalConfig()

  destroy: ->
    @subscriptions.dispose()

  _loadGlobalConfig: ->
    @globalConfig =
      presentationHome: atom.config.get 'impress.presentationHome'
      stepListView:
        stepListViewHeight: atom.config.get 'impress.stepListViewHeight'
    for projPath of @resolvedConfigs
      @resolvedConfigs[projPath] = $.extend true, {}, @globalConfig, localConf

  _deleteUnneededConfigs: (currentProjPaths) ->
    removedProjPaths = []
    for projPath of @resolvedConfigs
      if currentProjPaths.indexOf(projPath) is -1
        removedProjPaths.push projPath
    for projPath in removedProjPaths
      @_deleteConfig projPath

  _deleteConfig: (projPath) ->
    delete @resolvedConfigs[projPath]
    delete @localConfigs[projPath]

  _resolveNewProjectConfigs: (currentProjPaths) ->
    for projPath in currentProjPaths
      continue if @resolvedConfigs[projPath] # not new project
      confFilePath = path.join projPath, @configFileName
      continue unless fs.existsSync confFilePath # conf file not exist
      localConf = @_readLocalConfig confFilePath
      continue unless localConf # invalid conf file
      @localConfigs[projPath] = localConf
      @resolvedConfigs[projPath] = $.extend true, {}, @globalConfig, localConf

  _readLocalConfig: (confFilePath)->
    try
      confFileContent = fs.readFileSync confFilePath
    catch e
      console.error "Couldn't read #{confFilePath}: #{e.message}"
      return null
    try
      return toml.parse confFileContent
    catch e
      console.error "Parsing error (at #{e.line}:#{e.column}): #{e.message}"
      return null

module.exports = new ConfigResolver
