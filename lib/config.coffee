path = require 'path'
os = require 'os'
StepListView = require './step-list-view'

module.exports =
  presentationHome:
    default: path.join os.homedir(), 'impress'
    type: 'string'
    description: 'Presentation home.'
  stepListViewHeight:
    default: 120
    type: 'integer'
    minimum: StepListView.minHeight
    description: 'Height of Step List View.'
