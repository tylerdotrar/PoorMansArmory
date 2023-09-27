# Author: Tyler McCann (@tylerdotrar)
# Arbitrary Version Number:  3.0.0
# Link: https://github.com/tylerdotrar/PoorMansArmory

# Synopsis:
# Simple Flask web server for bi-directional file transfers, supporting
# both HTTP and HTTPS using self-signed certificates.  Intended to be
# used with the PowerShell WebClient helper script(s).

# Parameters:
# --directory <string>  (default: ./uploads)
# --port <int>          (default: 80)
# --ssl                 (default: false)
# --debug               (default: false)
# --help


import os, flask, argparse, sys
from flask import request, send_from_directory
from werkzeug.utils import secure_filename

app = flask.Flask(__name__, static_url_path='')


# DOWNLOAD FILES
@app.route('/<string:FILE_NAME>', methods=['GET','HEAD'])
def DownloadFile(FILE_NAME):
    path = CLIENT_DOWNLOADS + '/' + FILE_NAME
    #isFile = os.path.isfile(path)

    #if isFile:
    try:
        return send_from_directory(CLIENT_DOWNLOADS, FILE_NAME, as_attachment=True)
    except FileNotFoundError:
        abort(404)
    #return '[-] File not found.'


# UPLOAD FILES
@app.route('/<string:FILE_NAME>', methods=['POST'])
def upload_file(FILE_NAME):
    if request.method == 'POST':
        f = request.files['file']

        if FILE_NAME != '':
            f.save(os.path.join(CLIENT_UPLOADS, FILE_NAME))
            return '[+] Upload successful.'
        return '[-] Null filename.'
    return '[-] Invalid request method.'


# [DEPRECATED] RAW FILE CONTENTS
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
            return '[-] File not human readable.'
    return '[-] File not found.'


# PARAMETERS
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Flask-based Web Server for File Transfers that supports both HTTP and HTTPS via Self-Signed Certificates')
    parser.add_argument('-d', '--directory', default="./uploads", type=str, help='Target file directory (default: ./uploads)')
    parser.add_argument('-p', '--port', default=80, type=int, help='Server port to listen on (default: 80)')
    parser.add_argument('-s', '--ssl', action='store_const', const='adhoc', default=None, help='Enable HTTPS support via self-signed certificates (default: false)')
    parser.add_argument('-D', '--debug', action='store_true', help='Toggle Flask debug mode (default: false)')
    args = parser.parse_args()
    
    CLIENT_UPLOADS   = args.directory
    CLIENT_DOWNLOADS = args.directory

    if CLIENT_UPLOADS == './uploads':
        if not os.path.isdir(CLIENT_UPLOADS):
            os.mkdir(CLIENT_UPLOADS)   
    elif not os.path.isdir(CLIENT_UPLOADS):
        print('[-] Could not find directory. Exiting.')
        sys.exit()
    
    # Confirm Arguments
    print(f'Server Arguments:')
    print(f' * Directory   : {args.directory}')
    print(f' * Server Port : {args.port}')
    print(f' * SSL Context : {args.ssl}\n')
    print('Starting Server...')

    app.run(host='0.0.0.0', port=args.port, ssl_context=args.ssl, debug=args.debug)
