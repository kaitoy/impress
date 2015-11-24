{Range, Point, Disposable} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
sax = require "sax"
$ = require 'jquery'
chokidar = require 'chokidar'

exports.getCurrentFilePath = getCurrentFilePath = ->
  currentFilePath = null
  editor = atom.workspace.getActiveTextEditor()
  if editor?
    currentFilePath = editor.getPath()
  else
    paneItem = atom.workspace.getActivePaneItem()
    if paneItem?.getPath?
      # e.g. ImageEditor
      currentFilePath = paneItem.getPath()
  return currentFilePath

exports.getCurrentProjectPath = getCurrentProjectPath = ->
  currentFilePath = getCurrentFilePath()
  return null if currentFilePath is null

  for projPath in atom.project.getPaths()
    if currentFilePath.startsWith projPath
      return projPath
  return null

exports.findIndexHtmlPath = ->
  currentProjectPath = getCurrentProjectPath()
  return null if currentProjectPath is null
  indexPath = path.join currentProjectPath, 'index.html'
  return if fs.existsSync indexPath then indexPath else null

exports.readIconInBase64 = (fileName) ->
  packagePath = atom.packages.resolvePackagePath 'impress'
  fs.readFileSync(path.join(packagePath, 'icons', fileName)).toString 'base64'

exports.getStepRange = (
  editor, stepIdx, includePrecedingEmptyLines, includeTrailingEmptyLines
) ->
  parser = sax.parser false,
    trim: false
    normalize: false
    position: true
    lowercase: true
  start = null
  range = null
  depth = 0
  parser.onopentag = (node) ->
    if start?
      depth++
      return
    return if node.name isnt 'div'
    return unless node.attributes.class?
    classes = node.attributes.class.split ' '
    return if 0 > $.inArray 'step', classes
    if stepIdx is 0
      start = [@line, @column]
      return
    stepIdx--
  parser.onclosetag = ->
    return unless start?
    if depth is 0
      range = new Range start, [@line, @column]
      @close()
      @onopentag = null
      @onclosetag = null
      return
    depth--
  parser.write editor.getText()
  parser.close()
  editor.backwardsScanInBufferRange /[\t ]*</, [[0, 0], range.start], (arg) ->
    range.start = arg.range.start
    arg.stop()
  editor.scanInBufferRange /[\t ]*/, [range.end, [range.end.row + 1, 0]], (arg) ->
    range.end = arg.range.end
    arg.stop()
  if includePrecedingEmptyLines
    if range.start.column is 0
      newRow = range.start.row
      while editor.lineTextForBufferRow(newRow - 1).trim().length is 0
        newRow--
      if newRow < range.start.row
        range.start = new Point newRow, 0
  if includeTrailingEmptyLines
    trailingCharRange = Range.fromPointWithDelta range.end, 0, 1
    if editor.getTextInBufferRange(trailingCharRange).length is 0
      newRow = range.end.row
      while editor.lineTextForBufferRow(newRow + 1).trim().length is 0
        newRow++
      if newRow > range.end.row
        range.end = new Point newRow + 1, 0
  return range

exports.observeFileChange = (targets, opts, callback) ->
  watcher = chokidar.watch targets,
    persistent: true
    ignoreInitial: true
    awaitWriteFinish: true
    ignored: opts?.ignored
  watcher
    .on 'add', callback
    .on 'addDir', callback
    .on 'change', callback
    .on 'unlink', callback
    .on 'unlinkDir', callback
    return new Disposable ->
      watcher.close()
