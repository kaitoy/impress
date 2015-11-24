{TextEditor, CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
$ = require 'jquery'
React = require 'react'
ReactDOM = require 'react-dom'
path = require 'path'
util = require './util'
StepList = require './step-list'
remote = require 'remote'
dialog = remote.require 'dialog'

module.exports =
class StepListView extends View
  @minHeight: 50
  indexHtmlPath: undefined
  viewHeight: undefined
  panel: null
  subscriptions: null

  @content: ->
    @div class: 'step-list-view', tabindex: -1, =>
      @iframe outlet: 'iframe'

  initialize: (projPath) ->
    @indexHtmlPath = path.join projPath, 'index.html'
    @viewHeight = atom.config.get 'impress.stepListViewHeight'
    @panel = atom.workspace.addBottomPanel
      item: @element
      priority: -5
      visible: false
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeActivePaneItem (item) =>
      if item instanceof TextEditor and item.getPath() is @indexHtmlPath
        @panel.show()
      else
        @panel.hide()
    @subscriptions.add util.observeFileChange @indexHtmlPath, null, =>
      @iframe.get(0).contentWindow.location.reload();
    @iframe.attr
      'impress-no-init': 'impress-no-init'
      'src': @indexHtmlPath
    @iframe.css
      width: '100%'
      height: @viewHeight
      border: 'none'
    @iframe.load =>
      @iframe.contents().keydown (e) ->
        e.preventDefault()
      $(@iframe.get(0).contentWindow).resize (e) =>
        @_adjustSize()

      steps = []
      @iframe.contents().find('div.step').each (idx, dom) ->
        return if dom.id is 'overview'
        step = $(dom)
        step.css 'margin', 0
        steps.push
          index: idx
          title: if dom.id then dom.id else "step #{idx + 1}"
          width: step.outerWidth()
          height: step.outerHeight()
          content: dom
      ReactDOM.render(
        React.createElement(
          StepList,
            steps: steps
            height: @viewHeight
            actionHandler: @_actionHandler
        ),
        @iframe.contents().find('#impress').get(0),
        => @_adjustSize()
      )

  destroy: ->
    @panel.destroy()
    @subscriptions.dispose()

  toggle: ->
    if @panel.isVisible()
      @hide()
    else
      @show()

  show: ->
    atom.workspace.open @indexHtmlPath
      .then () => @panel.show()
      .catch (error) -> console.error error

  hide: ->
    @panel.hide()

  _adjustSize: () ->
    doc = @iframe.contents().get(0).documentElement
    scrollbarHeight = doc.scrollHeight - doc.clientHeight
    if scrollbarHeight isnt 0
      @iframe.css height: @iframe.height() + scrollbarHeight

  _actionHandler: (action) ->
    switch action.name
      when 'delete'
        editor = atom.workspace.getActiveTextEditor()
        if editor.isModified()
          atom.notifications.addWarning
          answer = dialog.showMessageBox(
            remote.getCurrentWindow(),
              type: 'question'
              buttons: ['OK', 'Cansel to delete']
              title: 'Confirm'
              cancelId: 1
              message: 'OK to save after deleting the step.'
          )
          return if answer isnt 0
        range = util.getStepRange(editor, action.step, true, true)
        editor.setTextInBufferRange range, "\n"
        editor.save()
      when 'focus'
        editor = atom.workspace.getActiveTextEditor()
        range = util.getStepRange(editor, action.step, false, false)
        editor.setSelectedBufferRange range, {reversed: true}
        editor.scrollToCursorPosition()
      else
        console.warn("Unknown action:", action)
