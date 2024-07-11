/* taken from https://www.w3schools.com/js/js_cookies.asp */

function setCookie(cname, cvalue, exdays) {
  const d = new Date();
  d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
  const expires = "expires=" + d.toUTCString();
  document.cookie = `${cname}=${cvalue};${expires};path=/;secure=true;sameSite=none`;

  // Verify if the cookie is set correctly
  if (document.cookie.includes(`${cname}=${cvalue}`)) {
    console.log('Cookie set successfully');
    // Delay the reload to ensure the cookie is set
    setTimeout(() => {
      location.reload();
    }, 1000); // 1 second delay
  } else {
    console.error('Cookie was not set successfully');
  }
}


function getCookie(cname) {
  let name = cname + "=";
  let ca = document.cookie.split(';');
  for(let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}
