path = require 'path'
fs = require 'fs-plus'
$ = require 'jquery'
{TextEditorView, View} = require 'atom-space-pen-views'
ConfigResolver = require './config-resolver'

module.exports =
class NewPresentationGeneratorView extends View
  panel: null
  defaultPresentationName: 'new-presentation'
  previouslyFocusedElement: null

  @content: ->
    @div class: 'new-presentation-generator-view', =>
      @subview 'miniEditor', new TextEditorView mini: true
      @div class: 'error', outlet: 'error'
      @div class: 'message', outlet: 'message'

  initialize: ->
    @miniEditor.on 'blur', => @close()
    atom.commands.add @element,
      'core:confirm': => @generate()
      'core:cancel': => @close()

  destroy: ->
    @panel?.destroy()
    @panel = null


  show: ->
    @panel ?= atom.workspace.addModalPanel item: this, visible: false
    @previouslyFocusedElement = $(document.activeElement)
    @panel.show()
    @message.text 'Enter path to new presentation'

    presentationHome = ConfigResolver.instance.presentationHome()
    editor = @miniEditor.getModel()
    presentationPath = path.join presentationHome, @defaultPresentationName
    editor.setText presentationPath
    endOfDirectoryIndex = presentationPath.length - @defaultPresentationName.length
    editor.setSelectedBufferRange([
      [0, endOfDirectoryIndex],
      [0, endOfDirectoryIndex + @defaultPresentationName.length]
    ])

    @miniEditor.focus()

  close: ->
    return unless @panel.isVisible()
    @error.hide()
    @panel.hide()
    @previouslyFocusedElement?.focus()
    @previouslyFocusedElement = null

  generate: ->
    newPresentationPath = fs.normalize @miniEditor.getText().trim()
    packagePath = atom.packages.resolvePackagePath 'impress'
    presentationTemplatePath = path.join packagePath, 'impress.js'
    if @isValidPath newPresentationPath
      try
        fs.copySync presentationTemplatePath, newPresentationPath
        atom.open(pathsToOpen: newPresentationPath)
        @close()
      catch e
        @error.text "An unexpected error occurred: #{e}"
        @error.show()

  isValidPath: (path) ->
    if fs.existsSync path
      @error.text "Path already exists at '#{path}'"
      @error.show()
      false
    else
      true
