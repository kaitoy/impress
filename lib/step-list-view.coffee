{$, ScrollView} = require 'atom-space-pen-views'
util = require './util'

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
    indexHtmlPath = util.findIndexHtmlPath()
    return unless indexHtmlPath?

    @panel.show()
    @iframe = $('<iframe src="' + indexHtmlPath + '"></iframe>')
    @stepList.append(@iframe)

  hide: ->
    @stepList.empty()
    @panel.hide()
