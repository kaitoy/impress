{CompositeDisposable} = require 'atom'
util = require './util'
StepListView = require './step-list-view'
ConfigResolver = require './config-resolver'

module.exports =
class StepListViewManager
  subscriptions: null
  views: null

  constructor: ->
    @subscriptions = new CompositeDisposable
    @views = {}
    @subscriptions.add atom.project.onDidChangePaths (projPaths) =>
      removedProjPaths = []
      for projPath, view of @views
        if projPaths.indexOf(projPath) is -1
          removedProjPaths.push projPath
      for projPath in removedProjPaths
        @_deleteView projPath

  destroy: ->
    view.destroy() for projPath, view of @views
    @subscriptions.dispose()

  toggleStepListView: ->
    currentProjectPath = util.getCurrentProjectPath()
    return if currentProjectPath is null
    if not ConfigResolver.instance.resolvedConfigs[currentProjectPath]?
      atom.notifications.addWarning(
        'Failed to find the configration of this project.',
          detail: "#{ConfigResolver.instance.getConfigFilePath currentProjectPath}
                   didn't exist or was invalid when this project was added."
          dismissable: true
      )
      return

    if @views[currentProjectPath]?
      @_deleteView currentProjectPath
    else
      view = new StepListView currentProjectPath
      @views[currentProjectPath] = view
      view.show()

  _deleteView: (projPath) ->
    @views[projPath].destroy()
    delete @views[projPath]
