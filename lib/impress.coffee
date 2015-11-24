{CompositeDisposable} = require 'atom'
path = require 'path'
os = require 'os'
util = require './util'
NewPresentationGeneratorView = require './new-presentation-generator-view'
StepListViewManager = require './step-list-view-manager'
StepListView = require './step-list-view'
remote = require 'remote'
BrowserWindow = remote.require 'browser-window'

module.exports = Impress =
  subscriptions: null
  newPresentationGeneratorView: null
  stepListViewManager: null
  previewWindow: null

  config:
    presentationHome:
      default: path.join os.homedir(), 'impress'
      type: 'string'
      description: 'Presentation home.'
    stepListViewHeight:
      default: 120
      type: 'integer'
      minimum: StepListView.minHeight
      description: 'Height of Step List View.'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'impress:new-presentation': => @newPresentation()
      'impress:toggle-step-list-view': => @toggleStepListView()
      'impress:preview': => @preview()
    @newPresentationGeneratorView = new NewPresentationGeneratorView
    @stepListViewManager = new StepListViewManager

  deactivate: ->
    @newPresentationGeneratorView?.destroy()
    @newPresentationGeneratorView = null
    @stepListViewManager?.destroy()
    @stepListViewManager = null
    @previewWindow?.destroy()
    @previewWindow = null
    @subscriptions.dispose()

  newPresentation: ->
    @newPresentationGeneratorView.show()

  toggleStepListView: ->
    @stepListViewManager.toggleStepListView()

  preview: ->
    indexHtmlPath = util.findIndexHtmlPath()
    return unless indexHtmlPath?
    @previewWindow = new BrowserWindow
      width: 800,
      height: 600,
      resizable: true,
      center: true,
      show: false
    @previewWindow.on 'closed', =>
      @previewWindow.destroy()
      @previewWindow = null
    @previewWindow.setMenuBarVisibility false
    @previewWindow.loadUrl indexHtmlPath
    @previewWindow.show()
