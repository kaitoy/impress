{CompositeDisposable} = require 'atom'
toml = require 'toml'
path = require 'path'
fs = require 'fs-plus'
$ = require 'jquery'

module.exports = class ConfigResolver
  subscriptions: null
  configFileName: '.impress.toml'
  resolvedConfigs: null
  globalConfig: null
  localConfigs: null
  @instance: null

  constructor: ->
    @resolvedConfigs = {}
    @localConfigs = {}
    @_loadGlobalConfig()
    @_resolveNewProjectConfigs atom.project.getPaths()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.project.onDidChangePaths (projPaths) =>
      @_deleteUnneededConfigs projPaths
      @_resolveNewProjectConfigs projPaths
    @subscriptions.add atom.config.onDidChange => @_loadGlobalConfig()

  destroy: ->
    @subscriptions.dispose()

  @init: ->
    @instance = new ConfigResolver

  @deinit: ->
    @instance?.destroy()
    @instance = null

  _loadGlobalConfig: ->
    @globalConfig =
      presentationHome: atom.config.get 'impress.presentationHome'
      mainHtmlPath: atom.config.get 'impress.mainHtmlPath'
      resources: atom.config.get 'impress.resources'
      stepListView:
        stepListViewHeight: atom.config.get 'impress.stepListViewHeight'
    for projPath of @resolvedConfigs
      @resolvedConfigs[projPath] =
        $.extend true, {}, @globalConfig, @localConfigs[projPath]

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
      confFilePath = @getConfigFilePath projPath
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

  getConfigFilePath: (projPath) ->
    return path.join projPath, @configFileName

  presentationHome: ->
    return @globalConfig.presentationHome

  mainHtmlPath: (projPath) ->
    return @resolvedConfigs[projPath].mainHtmlPath

  resources: (projPath) ->
    return @resolvedConfigs[projPath].resources

  stepListViewHeight: (projPath) ->
    return @resolvedConfigs[projPath].stepListView.stepListViewHeight
