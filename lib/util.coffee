path = require 'path'
fs = require 'fs-plus'

exports.findIndexHtmlPath = ->
  editor = atom.workspace.getActiveTextEditor()
  if editor?
    currentFilePath = editor.getPath()
  else
    paneItem = atom.workspace.getActivePaneItem()
    if paneItem?.getPath?
      # e.g. ImageEditor
      currentFilePath = paneItem.getPath()
  return null unless currentFilePath?

  return currentFilePath if currentFilePath.endsWith 'index.html'

  for projPath in atom.project.getPaths()
    if currentFilePath.startsWith projPath
      indexPath = path.join projPath, 'index.html'
      continue unless fs.existsSync indexPath
      return indexPath
  return null
