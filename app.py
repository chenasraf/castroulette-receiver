import os
from flask import Flask, render_template
from flask.ext import assets
import glob
import os

app = Flask(__name__)

env = assets.Environment(app)

# Tell flask-assets where to look for our coffeescript and sass files.
env.load_path = [
    os.path.join(os.path.dirname(__file__), 'sass'),
    os.path.join(os.path.dirname(__file__), 'coffee'),
    os.path.join(os.path.dirname(__file__), 'bower_components'),
]

bower_files = [
    'jquery/dist/jquery.min.js',
    'angularjs/angular.min.js',
]

receiver_js_files = glob.glob(os.path.join(
    os.path.dirname(__file__), 'coffee', 'receiver', '*.coffee'))
sender_js_files = glob.glob(os.path.join(
    os.path.dirname(__file__), 'coffee', 'sender', '*.coffee'))
receiver_css_files = glob.glob(os.path.join(
    os.path.dirname(__file__), 'sass', 'receiver', '*.scss'))
sender_css_files = glob.glob(os.path.join(
    os.path.dirname(__file__), 'sass', 'sender', '*.scss'))

receiver_js_files = map(lambda x: x[x.find(os.path.sep)+1:], receiver_js_files)
sender_js_files = map(lambda x: x[x.find(os.path.sep)+1:], sender_js_files)
receiver_css_files = map(lambda x: x[x.find(os.path.sep)+1:], receiver_css_files)
sender_css_files = map(lambda x: x[x.find(os.path.sep)+1:], sender_css_files)

receiver_js_bundle = bower_files + \
    [assets.Bundle(*receiver_js_files, filters='coffeescript',
                   output='receiver.js')]
sender_js_bundle = bower_files + \
    [assets.Bundle(*sender_js_files, filters='coffeescript',
                   output='sender.js')]

bundles = {
    'receiver_js': assets.Bundle(*receiver_js_bundle),
    'sender_js': assets.Bundle(*sender_js_bundle),
    'receiver_css': assets.Bundle(*receiver_css_files,
                                  filters='scss',
                                  output='receiver.css'),
    'sender_css': assets.Bundle(*sender_css_files,
                                filters='scss',
                                output='sender.css'),
}

print sender_css_files
print sender_js_files

env.register(bundles)


@app.route("/")
def index():
    return render_template('receiver.html')


@app.route("/sender")
def sender():
    return render_template('sender.html')


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0')
