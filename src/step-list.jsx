//
// lib/step-list.js is transpiled from src/step-list.jsx by Babel
//

const $ = require('jquery');
const React = require('react');
const ReactDOM = require('react-dom');
const Mui = require('material-ui');
const GridList = Mui.GridList;
const GridTile = Mui.GridTile;
const IconButton = Mui.IconButton;
const FontIcon = Mui.FontIcon;
const util = require('./util');
const xMark = util.readIconInBase64('x-mark.png');

module.exports = StepList = React.createClass({
  render: function() {
    const viewHeight = this.props.height;
    const steps = this.props.steps;
    const actionHandler = this.props.actionHandler;
    var gridWidth = this.props.steps.length - 1;
    steps.forEach(function(step) {
      step.scale = viewHeight / step.height;
      step.finalWidth = Math.floor(step.width * viewHeight / step.height);
      gridWidth += step.finalWidth;
    });
    return(
      <GridList
        cols={steps.length}
        padding={0}
        cellHeight={viewHeight}
        style={{
          width: gridWidth + 'px',
          margin: 0,
          display: 'flex',
          flexWrap: 'nowrap',
          justifyContent: 'space-between'
        }}
        ref={function(grid) {
          $(ReactDOM.findDOMNode(grid)).children().each(function(idx, dom) {
            $(dom).css('width', steps[idx].finalWidth + 'px');
          });
        }}
      >
        {
          steps.map(function(step) {
            const handleOnClickTile = function(e) {
              if (step.deleting) return;
              actionHandler({name: 'focus', step: step});
            };
            const handleOnClickDelete = function(e) {
              if (step.deleting) return;
              step.deleting = true;
              actionHandler({name: 'delete', step: step});
            };
            return <GridTile
              title={step.title}
              style={{boxSizing: 'border-box', border: 'solid 1px'}}
              onClick={handleOnClickTile}
              key={step.index}
              actionIcon={
                <IconButton
                  tooltip='Delete'
                  tooltipPosition='top-left'
                  onClick={handleOnClickDelete}
                >
                  <img
                    width="100%"
                    src={'data:image/png;base64,' + xMark}
                  />
                </IconButton>
              }
              ref={function(tile) {
                $(ReactDOM.findDOMNode(tile)).children().each(function() {
                  if (this.getAttribute('step')) {
                    return true;
                  }
                  // title label
                  $(this).css({
                    height: '30px',
                    lineHeight: '20px'
                  });
                });
              }}
            >
              <div
                step={step.index}
                style={{
                  transform: 'scale(' + step.scale + ')',
                  transformOrigin: 'top left',
                  position: 'absolute'
                }}
                ref={function(div) {div.appendChild(step.content);}}
              />
            </GridTile>
          })
        }
      </GridList>
    );
  },
});
