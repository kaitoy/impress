path = require 'path'
os = require 'os'
StepListView = require './step-list-view'

module.exports =
  presentationHome:
    default: path.join os.homedir(), 'impress'
    type: 'string'
    description: 'Presentation home.'
  mainHtmlPath:
    default: 'index.html'
    type: 'string'
    description: 'Path to the main HTML file.
                  (Relative path from the project root.)'
  stepListViewHeight:
    default: 120
    type: 'integer'
    minimum: StepListView.minHeight
    description: "Height of Step List View.
                  (#{StepListView.minHeight} at minimum.)"
