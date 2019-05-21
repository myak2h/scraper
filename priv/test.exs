urls = [
  "https://www.coolblue.nl/product/812989/lenovo-yoga-530-14ikb-81ek00hwmh.html",
  "https://www.coolblue.nl/product/783282/oral-b-pro-2-2500.html",
  "https://www.coolblue.nl/product/807362/dyson-cyclone-v10-absolute.html",
  "https://www.coolblue.nl/product/812652/acer-swift-3-sf314-54-54lb.html",
  "https://www.coolblue.nl/product/812691/acer-aspire-7-a715-72g-76wl.html",
  "https://www.coolblue.nl/product/824066/hp-15-da1956nd.html",
  "https://www.coolblue.nl/product/814684/samsung-ue43nu7020.html",
  "https://www.coolblue.nl/product/793664/apple-iphone-8-64gb-space-gray.html",
  "https://www.coolblue.nl/product/819385/acer-aspire-5-a515-52g-53y9.html",
  "https://www.coolblue.nl/product/822533/apple-macbook-air-13-3-2018-mre82n-a-space-gray.html",
  "https://www.coolblue.nl/product/734699/ring-video-doorbell-pro.html",
  "https://www.coolblue.nl/product/736763/microsoft-surface-pro-i5-8-gb-256-gb.html",
  "https://www.coolblue.nl/product/812954/lenovo-ideapad-330-17ikbr-81dm0021mh.html",
  "https://www.coolblue.nl/product/815588/lenovo-legion-y530-15ich-81lb001fmh.html",
  "https://www.coolblue.nl/product/808393/philips-43pfs5503.html",
  "https://www.coolblue.nl/product/813084/hp-pavilion-15-cs0960nd.html",
  "https://www.coolblue.nl/product/822686/apple-pencil-2e-generatie.html",
  "https://www.coolblue.nl/product/809931/hp-probook-450-g5-i5-8gb-256ssd.html",
  "https://www.coolblue.nl/product/673324/apple-pencil-1e-generatie.html",
  "https://www.coolblue.nl/product/813156/hp-14-ck0950nd.html",
  "https://www.coolblue.nl/product/813079/hp-pavilion-17-ab497nd.html",
  "https://www.coolblue.nl/product/223987/philips-wake-up-light-hf3510-01.html",
  "https://www.coolblue.nl/product/608152/apple-usb-c-naar-digital-av-adapter.html",
  "https://www.coolblue.nl/product/788988/apple-magic-keyboard-met-numeriek-toetsenblok-qwerty.html"
]




{:ok, pid} = Scraper.start_link(urls: urls)
