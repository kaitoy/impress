{CompositeDisposable} = require 'atom'
path = require 'path'
os = require 'os'
fs = require 'fs-plus'
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
    for projPath in atom.project.getPaths()
      indexPath = path.join projPath, 'index.html'
      continue unless fs.existsSync indexPath

      @previewWindow = new BrowserWindow
        width: 800,
        height: 600,
        show: false,
        'skip-taskbar': true,
        'auto-hide-menu-bar': true
      @previewWindow.on 'closed', =>
        @previewWindow = null;
      @previewWindow.loadUrl indexPath
      @previewWindow.show();
