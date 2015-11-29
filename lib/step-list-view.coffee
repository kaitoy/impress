{TextEditor, CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
$ = require 'jquery'
React = require 'react'
ReactDOM = require 'react-dom'
path = require 'path'
util = require './util'
StepList = require './step-list'
configResolver = require './config-resolver'
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
    @indexHtmlPath = path.join projPath, configResolver.mainHtmlPath(projPath)
    @viewHeight = configResolver.stepListViewHeight(projPath)
    if @viewHeight < StepListView.minHeight
      @viewHeight = StepListView.minHeight

    @panel = atom.workspace.addBottomPanel
      item: @element
      priority: -5
      visible: false
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeActivePaneItem (item) =>
      currentFilePath = util.getCurrentFilePath()
      if currentFilePath? and currentFilePath.startsWith projPath
        @show()
      else
        @hide()

    resources = configResolver.resources(projPath)
    if Array.isArray resources
      resources = resources.map (elem) ->
        return path.join projPath, elem
    resources.push @indexHtmlPath
    @subscriptions.add util.observeFileChange resources, =>
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
            actionHandler: $.proxy @_actionHandler, @
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
    @panel.show()

  hide: ->
    @panel.hide()

  _adjustSize: () ->
    doc = @iframe.contents().get(0).documentElement
    scrollbarHeight = doc.scrollHeight - doc.clientHeight
    if scrollbarHeight isnt 0
      @iframe.css height: @iframe.height() + scrollbarHeight

  _actionHandler: (action) ->
    atom.workspace.open @indexHtmlPath
      .then (editor) => @_doAction editor, action
      .catch (error) -> console.error error

  _doAction: (editor, action) ->
    step = action.step
    switch action.name
      when 'delete'
        if editor.isModified()
          answer = dialog.showMessageBox(
            remote.getCurrentWindow(),
              type: 'question'
              buttons: ['OK', 'Cansel Deletion']
              title: 'Confirm'
              cancelId: 1
              message: """
                       '#{editor.getTitle()}' is modified.
                       Press 'OK' to save after deleting the step '#{step.title}'.
                       """
          )
          if answer isnt 0
            delete step.deleting
            return
        range = util.getStepRange editor, step.index, true, true
        editor.setSelectedBufferRange range
        newRange = editor.setTextInBufferRange range, "\n"
        editor.scrollToScreenPosition newRange.start, center: true
        editor.setSelectedBufferRange newRange
        editor.save()
      when 'focus'
        range = util.getStepRange editor, step.index, false, false
        editor.setSelectedBufferRange range, {reversed: true}
        editor.scrollToCursorPosition()
      else
        console.warn 'Unknown action:', action
