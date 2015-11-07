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
    editor = atom.workspace.getActiveTextEditor()
    currentFilePath = editor.getPath()
    for projPath in atom.project.getPaths()
      if currentFilePath.startsWith projPath
        indexPath = path.join projPath, 'index.html'
        continue unless fs.existsSync indexPath

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
        @previewWindow.openDevTools()
        @previewWindow.loadUrl indexPath
        @previewWindow.show()
        break
