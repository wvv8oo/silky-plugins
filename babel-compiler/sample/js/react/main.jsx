var HelloMessage = React.createClass({
  render: function() {
    return <div>Hello {this.props.name}，我是通过React渲染的</div>;
  }
});

function reactRender(){
  React.render(<HelloMessage name="developer" />, document.getElementById('react-example'))
}
