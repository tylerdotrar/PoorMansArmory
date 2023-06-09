# Author: Tyler McCann (@tylerdotrar)
# Arbitrary Version Number:  2.0.0

# Synopsis:
# Simple Flask web server for bi-directional file transfers, supporting
# both HTTP and HTTPS using self-signed certificates.  Intended to be
# used with the PowerShell WebClient helper script(s).

# Parameters:
# --port (default: 443)
# --ssl
# --debug

import os, flask, argparse
from flask import request, send_from_directory
from werkzeug.utils import secure_filename

app = flask.Flask(__name__, static_url_path='')

CLIENT_UPLOADS   = './uploads'
CLIENT_DOWNLOADS = './downloads'

if not os.path.isdir(CLIENT_UPLOADS):
    os.mkdir(CLIENT_UPLOADS)
if not os.path.isdir(CLIENT_DOWNLOADS):
    os.mkdir(CLIENT_DOWNLOADS)

# FILE DOWNLOAD
@app.route('/d/<string:FILE_NAME>', methods=['GET','HEAD'])
def DownloadFile(FILE_NAME):
    path = CLIENT_DOWNLOADS + '/' + FILE_NAME
    isFile = os.path.isfile(path)

    if isFile:
        try:
            return send_from_directory(CLIENT_DOWNLOADS, FILE_NAME, as_attachment=True)
        except FileNotFoundError:
            abort(404)
    return 'FILE NOT FOUND'

# FILE UPLOAD
@app.route('/u/<string:FILE_NAME>', methods=['POST'])
def upload_file(FILE_NAME):
    if request.method == 'POST':
        f = request.files['file']

        if FILE_NAME != '':
            f.save(os.path.join(CLIENT_UPLOADS, FILE_NAME))
            return 'SUCCESSFUL UPLOAD'
        return 'NULL FILENAME'
    return 'INVALID METHOD'

# [DEPRECATED] FILE RAW CONTENT
@app.route('/r/<string:FILE_NAME>', methods=['GET'])
def ShowContent(FILE_NAME):
    path = CLIENT_DOWNLOADS + '/' + FILE_NAME
    isFile = os.path.isfile(path)

    if isFile:
        try:
            with open(path, 'r', encoding='utf-8-sig') as f:
                FILE_CONTENT = ''.join([line for line in f])
                return FILE_CONTENT
        except:
            return 'NOT HUMAN READABLE'
    return 'FILE NOT FOUND'

# PARAMETERS
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', default=443, type=int)
    parser.add_argument('--ssl', action='store_const', const='adhoc', default=None)
    parser.add_argument('--debug', action='store_true')
    args = parser.parse_args()

    app.run(host='0.0.0.0', port=args.port, ssl_context=args.ssl, debug=args.debug)