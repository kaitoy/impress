{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class StepListView extends ScrollView
  panel = null

  @content: ->
    @div class: 'step-list-view', =>
      @div class: 'step-list', outlet: 'stepList'

  # initialize: ->
  #   super()

  destroy: ->
    @stepList.empty()
    @panel?.destroy()
    @panel = null

  toggle: ->
    @panel ?= atom.workspace.addBottomPanel
      item: this
      priority: 10
      visible: false
    if @panel.isVisible()
      @hide()
    else
      @show()

  show: ->
    editor = atom.workspace.getActiveTextEditor()
    return if editor.getGrammar().name isnt 'HTML'

    @panel.show()
    @iframe = $('<iframe src="' + editor.getPath() + '"></iframe>')
    @stepList.append(@iframe)

  hide: ->
    @stepList.empty()
    @panel.hide()
