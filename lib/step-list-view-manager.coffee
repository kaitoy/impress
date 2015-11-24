{CompositeDisposable} = require 'atom'
util = require './util'
StepListView = require './step-list-view'

module.exports =
class StepListViewManager
  subscriptions: null
  views: {}

  constructor: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.project.onDidChangePaths (projPaths) =>
      removedProjPaths = []
      for projPath, view of @views
        if projPaths.indexOf(projPath) is -1
          removedProjPaths.push projPath
      for projPath in removedProjPaths
        @views[projPath].destroy()
        delete @views[projPath]

  destroy: ->
    view.destroy() for view of @views
    @subscriptions.dispose()

  toggleStepListView: ->
    currentProjectPath = util.getCurrentProjectPath()
    return if currentProjectPath is null
    if @views[currentProjectPath]?
      @views[currentProjectPath].toggle()
    else
      view = new StepListView currentProjectPath
      @views[currentProjectPath] = view
      view.show()
