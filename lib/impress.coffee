{CompositeDisposable} = require 'atom'
path = require 'path'
os = require 'os'
util = require './util'
NewPresentationGeneratorView = require './new-presentation-generator-view'
StepListView = require './step-list-view'
remote = require 'remote'
BrowserWindow = remote.require 'browser-window'

module.exports = Impress =
  subscriptions: null
  newPresentationGeneratorView: null
  stepListView: null
  previewWindow: null

  config:
    presentationHome:
      default: path.join os.homedir(), 'impress'
      type: 'string'
      description: 'Presentation home.'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'impress:new-presentation': => @newPresentation()
      'impress:toggle-step-list-view': => @toggleStepListView()
      'impress:preview': => @preview()
    @newPresentationGeneratorView = new NewPresentationGeneratorView
    @stepListView = new StepListView

  deactivate: ->
    @newPresentationGeneratorView?.destroy()
    @newPresentationGeneratorView = null
    @stepListView?.destroy()
    @stepListView = null
    @previewWindow?.destroy()
    @previewWindow = null
    @subscriptions.dispose()

  newPresentation: ->
    @newPresentationGeneratorView.show()

  toggleStepListView: ->
    @stepListView.toggle()

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
