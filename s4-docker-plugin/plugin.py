from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/Plugin.Activate', methods=['POST'])
def activate():
    return jsonify({"Implements": ["VolumeDriver"]})

@app.route('/VolumeDriver.Create', methods=['POST'])
def create():
    return jsonify({"Err": ""})

@app.route('/VolumeDriver.Remove', methods=['POST'])
def remove():
    return jsonify({"Err": ""})

@app.route('/VolumeDriver.Mount', methods=['POST'])
def mount():
    return jsonify({"Mountpoint": "", "Err": ""})

@app.route('/VolumeDriver.Unmount', methods=['POST'])
def unmount():
    return jsonify({"Err": ""})

@app.route('/VolumeDriver.Path', methods=['POST'])
def path():
    return jsonify({"Mountpoint": "", "Err": ""})

@app.route('/VolumeDriver.Get', methods=['POST'])
def get():
    return jsonify({"Volume": {}, "Err": ""})

@app.route('/VolumeDriver.List', methods=['POST'])
def list_volumes():
    return jsonify({"Volumes": [], "Err": ""})

@app.route('/VolumeDriver.Capabilities', methods=['POST'])
def capabilities():
    return jsonify({"Capabilities": {"Scope": "local"}})

if __name__ == '__main__':
    app.run()
