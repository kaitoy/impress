{CompositeDisposable} = require 'atom'
util = require './util'
NewPresentationGeneratorView = require './new-presentation-generator-view'
StepListViewManager = require './step-list-view-manager'
ConfigResolver = require './config-resolver'
config = require './config'
remote = require 'remote'
BrowserWindow = remote.require 'browser-window'

module.exports = Impress =
  subscriptions: null
  newPresentationGeneratorView: null
  stepListViewManager: null
  previewWindow: null

  config: config

  activate: ->
    ConfigResolver.init()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'impress:new-presentation': => @newPresentation()
      'impress:toggle-step-list-view': => @toggleStepListView()
      'impress:preview': => @preview()
    @newPresentationGeneratorView = new NewPresentationGeneratorView
    @stepListViewManager = new StepListViewManager

  deactivate: ->
    ConfigResolver.deinit()
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
