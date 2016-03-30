import os
from flask import Flask, render_template, request
from flask.ext import assets
import glob
import sys

app = Flask(__name__)

env = assets.Environment(app)

# Tell flask-assets where to look for our coffeescript and sass files.
env.load_path = [
    os.path.join(os.path.dirname(__file__), 'sass'),
    os.path.join(os.path.dirname(__file__), 'coffee'),
    os.path.join(os.path.dirname(__file__), 'bower_components'),
]

bower_js = [
    'jquery/dist/jquery.min.js',
    'bootstrap/dist/js/bootstrap.min.js',
    'underscore/underscore-min.js',
]

bower_css = [
    'bootstrap/dist/css/bootstrap.min.css',
    'bootstrap/dist/css/bootstrap-theme.min.css',
]

receiver_js_files = [os.path.join(dirpath, f)
                     for dirpath, dirnames, files in os.walk(os.path.join('coffee', 'receiver'))
                     for f in files if f.endswith('.coffee')]
sender_js_files = [os.path.join(dirpath, f)
                   for dirpath, dirnames, files in os.walk(os.path.join('coffee', 'sender'))
                   for f in files if f.endswith('.coffee')]
receiver_css_files = [os.path.join(dirpath, f)
                      for dirpath, dirnames, files in os.walk(os.path.join('sass', 'receiver'))
                      for f in files if f.endswith('.scss')]
sender_css_files = [os.path.join(dirpath, f)
                    for dirpath, dirnames, files in os.walk(os.path.join('sass', 'sender'))
                    for f in files if f.endswith('.scss')]

receiver_js_files = map(
    lambda x: x[x.find(os.path.sep) + 1:], receiver_js_files)
sender_js_files = map(lambda x: x[x.find(os.path.sep) + 1:], sender_js_files)
receiver_css_files = map(
    lambda x: x[x.find(os.path.sep) + 1:], receiver_css_files)
sender_css_files = map(lambda x: x[x.find(os.path.sep) + 1:], sender_css_files)

receiver_js_bundle = bower_js + \
    [assets.Bundle(*receiver_js_files, filters='coffeescript',
                   output='receiver.js')]
sender_js_bundle = bower_js + \
    [assets.Bundle(*sender_js_files, filters='coffeescript',
                   output='sender.js')]
receiver_css_bundle = bower_css + \
    [assets.Bundle(*receiver_css_files, filters='scss',
                   output='receiver.css')]
sender_css_bundle = bower_css + \
    [assets.Bundle(*sender_css_files, filters='scss',
                   output='sender.css')]

bundles = {
    'receiver_js': assets.Bundle(*receiver_js_bundle),
    'sender_js': assets.Bundle(*sender_js_bundle),
    'receiver_css': assets.Bundle(*receiver_css_bundle),
    'sender_css': assets.Bundle(*sender_css_bundle),
}

env.register(bundles)


@app.route("/")
def index():
    return render_template('receiver.html', debug=request.args.get('debug'))


@app.route("/sender")
def sender():
    return render_template('sender.html')

app.debug = ('debug' in sys.argv)

if not app.debug and os.environ.get('HEROKU') is None:
    import logging
    from logging.handlers import RotatingFileHandler
    file_handler = RotatingFileHandler('tmp/castroulette.log', 'a', 1 * 1024 * 1024, 10)
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'))
    app.logger.addHandler(file_handler)
    app.logger.setLevel(logging.INFO)
    app.logger.info('castroulette startup')

if __name__ == "__main__":
    app.run(host='0.0.0.0')
