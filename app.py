import os
from flask import Flask, render_template
from flask.ext import assets

app = Flask(__name__)

env = assets.Environment(app)

# Tell flask-assets where to look for our coffeescript and sass files.
env.load_path = [
    os.path.join(os.path.dirname(__file__), 'sass'),
    os.path.join(os.path.dirname(__file__), 'coffee'),
    os.path.join(os.path.dirname(__file__), 'bower_components'),
]


env.register(
    'js_sender',
    assets.Bundle(
        'jquery/dist/jquery.min.js',
        'angularjs/angular.min.js',
        assets.Bundle(
            'sender.coffee',
            filters=['coffeescript']
        ),
        output='js_sender.js'
    )
)

env.register(
    'css_sender',
    assets.Bundle(
        'sender.scss',
        filters='scss',
        output='css_sender.css'
    )
)

env.register(
    'js_receiver',
    assets.Bundle(
        'jquery/dist/jquery.min.js',
        'angularjs/angular.min.js',
        assets.Bundle(
            'receiver.coffee',
            filters=['coffeescript']
        ),
        output='js_receiver.js'
    )
)

env.register(
    'css_receiver',
    assets.Bundle(
        'receiver.scss',
        filters='scss',
        output='css_receiver.css'
    )
)


@app.route("/")
def index():
    return render_template('receiver.html')

@app.route("/sender")
def sender():
    return render_template('sender.html')


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0')
