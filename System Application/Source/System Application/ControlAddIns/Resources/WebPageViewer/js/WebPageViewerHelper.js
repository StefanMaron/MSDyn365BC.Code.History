/*! Copyright (C) Microsoft Corporation. All rights reserved. */

var WebPageViewerHelper = {
    Initialize: function () {
      if (WebPageViewerHelper.IsRunningOnIos()) {
        // Do not add the spinner in iOS, as this might cause rendering issues for the iframe
        return;
      }
      var spinnerSrc = Microsoft.Dynamics.NAV.GetImageResource('Loader.gif');
      var spinnerContainer = document.createElement('div');
      spinnerContainer.setAttribute('id', 'spinner');
  
      var spinner = document.createElement('img');
      spinner.setAttribute('src', spinnerSrc);
  
      spinnerContainer.appendChild(spinner);
  
      document.body.insertBefore(spinnerContainer, document.body.childNodes[0]);
    },
  
    DisplaySpinner: function () {
      var spinner = document.getElementById('spinner');
      if (spinner != null) {
        spinner.setAttribute('style', 'display: block');
      }
  
      var content = document.getElementById('controlAddIn');
      content.display = 'none';
    },
  
    HideSpinner: function () {
      var spinner = document.getElementById('spinner');
      if (spinner != null) {
        spinner.setAttribute('style', 'display: none');
      }
  
      var content = document.getElementById('controlAddIn');
      content.display = 'block';
    },
  
    CreateIFrame: function (height, width) {
      WebPageViewerHelper.DisplaySpinner();
  
      var iframe = document.createElement('iframe');
      iframe.setAttribute('height', height);
      iframe.setAttribute('width', width);
      iframe.setAttribute('frameBorder', '0');
      iframe.setAttribute('seamless', 'seamless');
  
      return iframe;
    },
  
    IFrameReady: function (iframe, callback) {
      var contentLoadedEvent = function () {
        WebPageViewerHelper.HideSpinner();
        iframe.removeEventListener('load', contentLoadedEvent);
      };
  
      var poll = setInterval(function () {
        try {
          if (iframe.contentDocument && iframe.contentDocument.body) {
            iframe.addEventListener('load', contentLoadedEvent);
  
            iframe.contentDocument.body.setAttribute('style', 'margin: 0px; padding: 0px;');
  
            var event = {
              preventLoadEvent: function () {
                iframe.removeEventListener('load', contentLoadedEvent);
              }
            };
  
            callback(event);
  
            clearInterval(poll);
          }
        }
        catch (ex) {
          clearInterval(poll);
        }
      }, 5);
    },
  
    CreateInput: function (name, value) {
      var input = document.createElement('input');
      input.setAttribute('type', 'hidden');
      input.setAttribute('name', name);
      input.setAttribute('value', value);
  
      return input;
    },
  
    CreateFormWithData: function (method, action, data) {
      if (!(method.toUpperCase() === "GET" || method.toUpperCase() === "POST")) {
        throw 'Unsupported Method Specified';
      }
  
      if (action.substring(0, 8).toLowerCase() !== "https://") {
        throw 'Insecure URL Specified';
      }
  
      var form = document.createElement('form');
      form.setAttribute('method', method);
      form.setAttribute('action', action);
  
      for (var key in data) {
        // decode posted data as it will be re-encoded on submit by the browser
        var input = WebPageViewerHelper.CreateInput(decodeURIComponent(key), decodeURIComponent(data[key]));
  
        form.appendChild(input);
      }
  
      return form;
    },
  
    RunJavascript: function (js, documentContext) {
      var script = document.createElement('script');
      script.type = 'text/javascript';
      script.text = js;
      documentContext.head.appendChild(script);
    },
  
    SetBodyContent: function (content) {
      var controlAddIn = window.document.getElementById('controlAddIn');
      controlAddIn.innerHTML = '';
      controlAddIn.appendChild(content);
  
      // For elastic scrolling to work on iOS we need to apply
      // a few styles on the DOM element that is hosting the 
      // iframe element.
      if (WebPageViewerHelper.IsRunningOnIos()) {
        controlAddIn.classList.add('ms-dyn-nav-scrollable');
      }
  
      WebPageViewerHelper.Properties.BodyContent = content;
    },
  
    GetCallbackURL: function () {
      var proto = document.location.protocol;
      var host = document.location.host;
      var path = Microsoft.Dynamics.NAV.GetImageResource('Callback.html');
  
      if (host == '') { // on phone client the host is empty
        return path;
      }
  
      if (path.indexOf(proto + '//') == 0) {
        // assume path already contains host information
        return path;
      } else {
        // need to specify host information
        return proto + '//' + host + path;
      }
    },
  
    TriggerCallback: function (data) {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('Callback', [data]);
    },
  
    ChildDocumentReady: function () {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DocumentReady');
    },
  
    TriggerEvent: function (data) {
      var target = WebPageViewerHelper.Properties.BodyContent;
      if (!(target && target.contentWindow)) {
        return;
      }
  
      var event;
      if (!target.contentDocument.createEvent) {
        event = new CustomEvent('webpageviewerevent', data);
      } else {
        event = target.contentDocument.createEvent('CustomEvent');
        event.initEvent('webpageviewerevent', true, true);
        event.data = data;
      }
  
      window.dispatchEvent(event);
    },
  
    LinksOpenInNewWindow: function () {
      var targetDocument = WebPageViewerHelper.Properties.BodyContent;
      if (!targetDocument || !targetDocument.contentDocument) {
        return;
      }
  
      targetDocument = targetDocument.contentDocument;
      var links = targetDocument.getElementsByTagName('a');
  
      for (var i = 0; i < links.length; i++) {
        if (links[i].hasAttribute('href')) {
          (function () {
            var url = links[i].getAttribute('href');
            links[i].setAttribute('href', '#');
            links[i].addEventListener('click', function (e) {
              Microsoft.Dynamics.NAV.OpenWindow(url);
              e.preventDefault();
            });
          })();
        }
      }
    },
  
    UpdateLinks: function () {
      if (WebPageViewerHelper.Properties.LinksOpenInNewWindow) {
        WebPageViewerHelper.LinksOpenInNewWindow();
      }
    },
  
    SetCallbacksFromSubscribedEventToIgnore: function (eventName, callbackResults) {
      WebPageViewerHelper.Properties.IgnoreCallbacks[eventName] = callbackResults;
    },
  
    SubscribeToEvent: function (eventName, recieveMessage) {
      if (WebPageViewerHelper.Properties.SubscribedEvents.indexOf(eventName) < 0) {
        WebPageViewerHelper.Properties.SubscribedEvents.push(eventName);
        window.addEventListener(eventName, recieveMessage);
      }
    },
  
    HandleException: function (ex) {
      var errMsg = ex + '.';
      var helpMsg = 'Please contact your system administrator.';
  
      var container = document.createElement('div');
  
      var h1 = document.createElement('h1');
      var h2 = document.createElement('h2');
  
      if (container.textContent === '') {
        h1.textContent = errMsg;
        h2.textContent = helpMsg;
      } else {
        h1.innerText = errMsg;
        h2.innerText = helpMsg;
      }
  
      container.appendChild(h1);
      container.appendChild(h2);
  
      WebPageViewerHelper.SetBodyContent(container);
    },
  
    IsRunningOnIos: function () {
      return WebPageViewerHelper.FindInUserAgentString('IPAD') || WebPageViewerHelper.FindInUserAgentString('IPOD') || WebPageViewerHelper.FindInUserAgentString('IPHONE');
    },
  
    FindInUserAgentString: function (targetString) {
      return WebPageViewerHelper.GetUserAgentString().indexOf(targetString) > -1;
    },
  
    GetUserAgentString: function () {
      if (WebPageViewerHelper.Properties.UserAgentString == null) {
        WebPageViewerHelper.Properties.UserAgentString = window.navigator.userAgent.toUpperCase();
      }
  
      return WebPageViewerHelper.Properties.UserAgentString;
    },
    
    /// <summary>
    /// Creates a subscription function for an iframe that notifies any subscribers after the load event occurs and the src attribute is set. 
    /// </summary>
    /// <param name="iframe">The iframe to trigger the load event from.</param>
    /// <returns type="function">Subscription function that adds subscribers to the load event.</returns>
    BindSrcLoadEvent: function (iframe) {

  
      var loaded = false;
      var subscriptions = [];
  
      // Checks to see if the iframe has loaded and if the src attribute has been set
      var srcLoadEvent = function () {
        if (iframe.src) {
          iframe.removeEventListener('load', srcLoadEvent);
          loaded = true;
  
          // Notify all subscribers that the load event has occured with the src attribute set
          for (var i = 0; i < subscriptions.length; i++) {
            subscriptions[i]();
          }
        }
      }
  
      // Hook up the actual load event listener
      iframe.addEventListener('load', srcLoadEvent);
  
      // Return a subscription function that allows consumers to subscribe to the load event at any time
      return function (subscriber) {
        if (typeof subscriber === 'function' && subscriptions.indexOf(subscriber) < 0) {
          subscriptions.push(subscriber); // Always add the subscriber to the subscriptions list
          if (loaded) subscriber(); // Notify the subscriber immediately if already loaded
        }
      };
    },
  
    Properties: {
      BodyContent: null,
      LinksOpenInNewWindow: false,
      UserAgentString: null,
      SubscribedEvents: [],
      IgnoreCallbacks: {}
    }
  };
// SIG // Begin signature block
// SIG // MIInQwYJKoZIhvcNAQcCoIInNDCCJzACAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // hrzT4aeocEidJtWlFnZ0el78HeuKzeUoXt9/RzAlG7mg
// SIG // ggy6MIIF9TCCA92gAwIBAgITMwAAAh1NGchO1w9XSAAA
// SIG // AAACHTANBgkqhkiG9w0BAQsFADBXMQswCQYDVQQGEwJV
// SIG // UzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5n
// SIG // IFBDQSAyMDI0MB4XDTI2MDQxNjE4NTk0M1oXDTI3MDQx
// SIG // NTE4NTk0M1owdDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
// SIG // Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
// SIG // BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEeMBwG
// SIG // A1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjAN
// SIG // BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0L3sF8cf
// SIG // YGWRQumLNVgWsvASfJBgOCUJx+QjGn6jgEpU6SvR/KOW
// SIG // V017dHGlUEzTFD7eOOcF2A/nRbWilk8A59SOdqFEqwvb
// SIG // yYp9RrKrfs8iiS+Q4N3kF20DUetQ5jMttBi0yDt0hXnf
// SIG // UX4v6KYYAixhSw0d69Crx48DG/42FktHHpVf+C89uy3w
// SIG // HpJvL/ROSF2nol2wFGGSitPdJ+AlZdyQbWzfvQ7SPUjb
// SIG // v8o76M1udv7u0V/07aWvyg5abqJGfmXG75rXfbq/YBS7
// SIG // 2c4eNaPTLBP3JULXWhVhr7qOibmv57aYJHstxOf7wRXv
// SIG // jCTxuqYXZ7qOq+e2bnQrnYiNWwIDAQABo4IBmzCCAZcw
// SIG // DgYDVR0PAQH/BAQDAgeAMB8GA1UdJQQYMBYGCisGAQQB
// SIG // gjdMCAEGCCsGAQUFBwMDMB0GA1UdDgQWBBR+kLjMKnDx
// SIG // tIUJUOnOYwrU0y61XjBFBgNVHREEPjA8pDowODEeMBwG
// SIG // A1UECxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMRYwFAYD
// SIG // VQQFEw0yMzAwMTIrNTA3NTU5MB8GA1UdIwQYMBaAFH9Z
// SIG // P1Qh2q1P7wXl5qPXLQaUEggxMGAGA1UdHwRZMFcwVaBT
// SIG // oFGGT2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
// SIG // cHMvY3JsL01pY3Jvc29mdCUyMENvZGUlMjBTaWduaW5n
// SIG // JTIwUENBJTIwMjAyNC5jcmwwbQYIKwYBBQUHAQEEYTBf
// SIG // MF0GCCsGAQUFBzAChlFodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMENv
// SIG // ZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyNC5jcnQwDAYD
// SIG // VR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEASk22
// SIG // Do88Exvw1xms/bOvn0Hmk7Q3BZjGPuVMlRQso+z7/uYt
// SIG // +6n1/JUi/7QSH2EH1rDLgUJX2bqyQ+q+B1Sdgnh/tX4I
// SIG // qvHXB3VSqGd0mtql6F93KvYkvHFW9Oge/uf1yeyNDsRx
// SIG // /Xw7Lyd098OVf2bQCBZi65fj9ArRvvdrs0bJ9J023RYz
// SIG // pCzC1jywFN0x6ISkZUhDIBSaT5JuZ+VAGd+cV+hVgqwy
// SIG // 7Eim+eeW04n8GvJiQcHZaH9G5n2InR/ncWdRXQ8by5zZ
// SIG // fc3irAOJHo2miKqiD4LocALYuUJewZUzaCTcMQrwZqlt
// SIG // jEC5wpGDf1VVLEd1dsf63Ezc6AX/2f0qUTr3WgNmTjnd
// SIG // boqFybd7XS0O7x6aqYm9Cn1q/xVl1tdKt/FcXwp0UAas
// SIG // 20rs7Ue5xDLs1+wpPgf12jw13daoe9vkGMgdGdlc1pjv
// SIG // c7J2/VKv3cLvCxnkKp8ruu0gxgAr514otn2/flEuPdlU
// SIG // 510pxSsqsIM1MhTLWStf7B2E7+mxuE7UFMoEMUzfmVfm
// SIG // iSJSjtjKme2yqwJzs0vZujYKE3VjqtdW0zmcCpSBFfxI
// SIG // VfUlpA5naUf4Tz09r+kxI+BfD0/8x40XsyFOXPwxpbf1
// SIG // YWP6StF5CbRMjJpktQTLY1P66gWVTCJt3Z8ULP0wQcq/
// SIG // gn/Gda+2on0FUPlkqs4wgga9MIIEpaADAgECAhMzAAAA
// SIG // OTu2Nxm/Bh1nAAAAAAA5MA0GCSqGSIb3DQEBDAUAMIGI
// SIG // MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
// SIG // bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
// SIG // cm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNy
// SIG // b3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkg
// SIG // MjAxMTAeFw0yNDA4MDgyMDU0MThaFw0zNjAzMjIyMjEz
// SIG // MDRaMFcxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNy
// SIG // b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jv
// SIG // c29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMjQwggIiMA0G
// SIG // CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDYAZwe4zjH
// SIG // qpUWBzWtuub+CGPXx/EyoXph3zyDXtYKS2ld3YYN9uFs
// SIG // B9Oi3B26Z7AbpAgzYra8qNHbUvxFuiP8hC/2y0mPISqW
// SIG // 30LlrrAT6/ams2HA8Qlv6p42+SbCNbPGzToN21QE70FS
// SIG // +LXH9N2k8nLM/EHgnTNJf8h0TmyfUKmszNa+lTxDieyy
// SIG // /rhBG+98OkArobPPWtbr9c3qzmDJ7J3kUcAm6cltdSHI
// SIG // IFNHESgw6taY1ScyGyBevqIl120XjrIHiPM7tRckHytH
// SIG // 1ZGsmvEplR0P7Tn9t5meFvZNEYttkFvad1IEguTlA5LS
// SIG // scXAphi+rVy3zhklhyCFeGK0yU0+jzbcuURKIxybmRwK
// SIG // 5BfVZx0xEVqE4wM3yN5D/uW+GpVHYYAGe7bTrtW1Z13x
// SIG // 2qj2Jdqz7NtI4tNyzlVrIf62nYBNe3rOYS/repVdHlR6
// SIG // 1YbLLETlibs9jFzAre4sO5RTxvS1yho7JqJ59oKLRnRy
// SIG // LhIOSZyTCVZosXeS0ZZJoGEWSs4cUgsMqBiKtD4WgO2P
// SIG // lT3LeaQh5Io3CCA5tJ5ZCvtCsnqaJXKhptE/xmEETIRy
// SIG // ZRjjplUKKd+sFFVGJJVMvvrw1nhIBKOLO4cTepiG39jE
// SIG // iEP4iHzGYCcQuvaLpDFFwqzgt0pBP8SJIKX5dtjDNYrZ
// SIG // Gd+ZzV5DKJVNZQIDAQABo4IBTjCCAUowDgYDVR0PAQH/
// SIG // BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQW
// SIG // BBR/WT9UIdqtT+8F5eaj1y0GlBIIMTAZBgkrBgEEAYI3
// SIG // FAIEDB4KAFMAdQBiAEMAQTAPBgNVHRMBAf8EBTADAQH/
// SIG // MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO4eqnxzHRI4k0
// SIG // MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWlj
// SIG // cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jv
// SIG // b0NlckF1dDIwMTFfMjAxMV8wM18yMi5jcmwwXgYIKwYB
// SIG // BQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3
// SIG // Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
// SIG // ckF1dDIwMTFfMjAxMV8wM18yMi5jcnQwDQYJKoZIhvcN
// SIG // AQEMBQADggIBABSUHzgoT+6J5+nyyDCq0pTdVmCsAxYA
// SIG // HXcpjlDtxazPHewf1v4kOg8V7A5+w+VuMDMGHi8rLXBK
// SIG // n5I8+DVEUYGs8jLuckc0IeC6owOLUrU3CYdaKRMaO55+
// SIG // T7jwWJ27tPkx0rlR03tFU0z1YYpcv6Yhaw6N2sUPT+Av
// SIG // jpecnrftoE33pCAkucUvnGH0iL4J9CZLFQVTGFSOUBbv
// SIG // 6oZy4bBBRFMxvH779IY4JDvpZKVfbcuhpDeL3Z3e8muk
// SIG // Omkfct+GojNapsWsQYujlJ8jZen5Lrp/3YkxZ2Ay06aT
// SIG // pK/5oOVknwog1TDQsbY+MDyguTph5tQ0CLfzDaJG2x91
// SIG // BrBT9UG87C6HLkqiwrx9PSKN3wz05rHEfWO+RuKl+0U1
// SIG // /AHQT6NCOjhKI39/c7hWbdKjh5uuWFkBOvXGTNrnhNTA
// SIG // dOXTTYByvYExO8yryv34PAdqo1vPDE/1heVebr2Rramv
// SIG // RUi9kWswKwPqwz7n+iRmM+B6YDGRweEurM1kimAb9FYr
// SIG // As38YHlPnarl1vW3dGrmJTgefAz3DmCnXN0nveIPsS+K
// SIG // XBIWweeCToAJMGE7v/XS3h9qQ6niWQAAVQ1kUAml3zuS
// SIG // 4MisCgi2F6YoK2WAo1EgXK/lXvDxVjIVU0JdL+KvCfwF
// SIG // JkDeVuJ9dNXGNi+AOxk0BtYd9hxwL30BElj9MYIZ4TCC
// SIG // Gd0CAQEwbjBXMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9N
// SIG // aWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDI0AhMz
// SIG // AAACHU0ZyE7XD1dIAAAAAAIdMA0GCWCGSAFlAwQCAQUA
// SIG // oIGuMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
// SIG // CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
// SIG // SIb3DQEJBDEiBCD+BYy7aI2jZ8rDyymfmlaFFuZkOoo0
// SIG // uwUCu4m3QXdOmTBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAIFx
// SIG // MOXAeNIApeZ7Rxhlmr46+/qnT2vrEh0c8rG+3x7bwDUP
// SIG // aPly4DYtDcHO27CeqTjA5KkMNFsKf8YJZyhj0wUs+LHW
// SIG // jY8d9PxPLp8wBk22kEk25PHP0P+MHojj7Ks5eFAVG2XF
// SIG // BzxSIJ3zp0ItMU/HqtDRpYvzd7ZMmTpmZyPV7fi+Vk9U
// SIG // /YmXm/6IvOtFoFZMHP5vXn+gSQKyMJP5sj9qPhvLo/ol
// SIG // ms5jVpEDUwHojxeYKeq13JZqZHyHjwZ8QVN77soTV/p6
// SIG // K919Lc0gQcBb8AsJ8/oXlLEk8DBjANYWlmtbfFT+jKOh
// SIG // ahD9Z3my8DOJG8S3UWWoP2JmYqn/9FehgheTMIIXjwYK
// SIG // KwYBBAGCNwMDATGCF38wghd7BgkqhkiG9w0BBwKgghds
// SIG // MIIXaAIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUQYLKoZI
// SIG // hvcNAQkQAQSgggFABIIBPDCCATgCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQg50zkDeiyEgZ1OCFr
// SIG // NMY2q4oY5y4AsiVqP/VJWf/9HpoCBmpfWBVlYxgSMjAy
// SIG // NjA4MDMxNTAzNDMuNDNaMASAAgH0oIHRpIHOMIHLMQsw
// SIG // CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
// SIG // MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
// SIG // b2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3Nv
// SIG // ZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5u
// SIG // U2hpZWxkIFRTUyBFU046QTQwMC0wNUUwLUQ5NDcxJTAj
// SIG // BgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZp
// SIG // Y2WgghHqMIIHIDCCBQigAwIBAgITMwAAAijwpYfX88ge
// SIG // QAABAAACKDANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDAeFw0yNjAyMTkxOTQwMDZa
// SIG // Fw0yNzA1MTcxOTQwMDZaMIHLMQswCQYDVQQGEwJVUzET
// SIG // MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
// SIG // bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
// SIG // aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBP
// SIG // cGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBF
// SIG // U046QTQwMC0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jv
// SIG // c29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqG
// SIG // SIb3DQEBAQUAA4ICDwAwggIKAoICAQCujvbk/sqcCSRe
// SIG // ZaJfCuf1NwRcc7XknhE6wkLofkNj1mxEAg35qy2xcFjg
// SIG // jartVvA09W8QHcpyMqVSXOTxNHJsmk0qP2CDLvUAulWg
// SIG // 7aS5oBORpEX1oz3n0R2nPqeH0IHK1zJxjxaHW21AbuZ0
// SIG // Z+wM3WYNzkBlcHmVe03ZG7rlk28h72r5P5ME8FGpFmYW
// SIG // 5Hl7psKbgLEfrYAitpttsb+sZsBUI+hMKl4uLJYotKyZ
// SIG // v1ewOIinBfRU8QosivjofaBezUf9NdV+iGrWh321WnSs
// SIG // K3A/Jl6GLtbSWXcJWULgbxuqnobPK+YlB3174TMWTgX4
// SIG // YWjG7o0Otz/pjHNCKBbB788dynhLdGY6B08E9+4SGrRp
// SIG // sty4iJHOydHCA5M4i5yYRwsdut+gmvxIpT8yNXJcjJCg
// SIG // 0vO8mv/nFY9Wytv2qmCtCFFivGUWqU20/sUeRooQZGiQ
// SIG // OJQn095Cj3isIsvRP8KU7hN/EDI8HVsb/NPzMFLvRznr
// SIG // Rnj0TOnDiOTUcnYwmk+XfoS1owskcCCCwHnbC00D58z8
// SIG // 3y7K5ZJB745hcn4CE2nR3e6RGsr42y5qtt6Mdz/s7MTn
// SIG // DS2UmVHWX1X/HZe3UlX8gj/t63L50xIPqkRCBEdM1ADN
// SIG // UaSfo9OQiKb/bj1diZCGTfEDUBBLop1mhkwIF82faplV
// SIG // 2busZ+U4kQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFKrJ
// SIG // pYz48tzouvVkBVthASFpQ93DMB8GA1UdIwQYMBaAFJ+n
// SIG // FV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBS
// SIG // oFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
// SIG // cHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQ
// SIG // Q0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
// SIG // XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
// SIG // LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGlt
// SIG // ZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1Ud
// SIG // EwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgw
// SIG // DgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IC
// SIG // AQCQ6NfLmrRahgVtgWg383GaS07fHyod6bhcUONt2tet
// SIG // +6BaNuH0r7ABkVHheOpxBdrUrOEYVEaIii9dK3cuZLNm
// SIG // p1iUAx/VbmOZYl7xz+tNrjCWqrg1jQmq0oRB8iE4QJpw
// SIG // NhGP67oY5huYIU0D4lhDoahqfgKJn/0Bk+9UKDPw5XlU
// SIG // YmreFmJlj9YQzcPPep8MxBXxh/Y5I7vQeRaW5SjtiLQO
// SIG // LRk3ggvraDs5Sf49MJV6/BwxXC2rvUfEFX6SUDooqKIE
// SIG // 9NgVIRq0RZu7Ot0i0Is+HvPP0hB6KwOxMg1SWKOfTtFp
// SIG // Wpdo8MJvgKCHkPpXEzgprP+pyIHuO7gVRlSTsbYBFLh2
// SIG // yId/itM4uYL0R+2SSBBTpSSRthrGuEmElI5BCHMxzMg/
// SIG // oqHSPwZAIAkM2C4xxi0St7qMuA+m+ZzFYkfoF41QoSJn
// SIG // +HjqhqWYQ0m/SO9/KnJRJJUwMd5TiMnjZ+E/DJiUry5u
// SIG // diWyQpvfj2hQFI0djhahoAXDazeEciLF2uEnTur9Ufjc
// SIG // wOun/oMY+ULftnOi2jKLMrreV097akzz/JxpnDgYJU/t
// SIG // gU7fQflg7IqiL9+0276+joQHo21mVeY5YD8Kh/kUaY6J
// SIG // m/OTM88G7evTz/qnRumxovTjMStvpbAHNRhmSTdIPTV3
// SIG // 2CyuxDKS/V5a5iwA+f9ViBo+wjCCB3EwggVZoAMCAQIC
// SIG // EzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZIhvcNAQEL
// SIG // BQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMT
// SIG // KU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
// SIG // cml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkz
// SIG // MDE4MzIyNVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
// SIG // Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
// SIG // BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
// SIG // A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
// SIG // MTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
// SIG // AQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXI
// SIG // yjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2
// SIG // Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPFdvWG
// SIG // UNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8d
// SIG // q6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/P
// SIG // XfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBpDco2LXCO
// SIG // Mcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnop
// SIG // N6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+
// SIG // cakXW2dg3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW/aUg
// SIG // fX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj
// SIG // 0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9
// SIG // Q07BMzlMjgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2
// SIG // AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU
// SIG // 2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6
// SIG // r1AFemzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1
// SIG // Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkw
// SIG // EgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIE
// SIG // FgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYE
// SIG // FJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARVMFMw
// SIG // UQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0
// SIG // dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9j
// SIG // cy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEF
// SIG // BQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
// SIG // BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
// SIG // HSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNV
// SIG // HR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29m
// SIG // dC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJB
// SIG // dXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBM
// SIG // MEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEw
// SIG // LTA2LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9
// SIG // /Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0x
// SIG // M7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZn
// SIG // OlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++
// SIG // Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449xvNo
// SIG // 32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5
// SIG // KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3D
// SIG // YXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7
// SIG // T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+
// SIG // CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2z
// SIG // AVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77
// SIG // IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFh
// SIG // bHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGE
// SIG // vL8CwYKiexcdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4
// SIG // JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEz
// SIG // fbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDB
// SIG // cQZqELQdVTNYs6FwZvKhggNNMIICNQIBATCB+aGB0aSB
// SIG // zjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMc
// SIG // TWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUG
// SIG // A1UECxMeblNoaWVsZCBUU1MgRVNOOkE0MDAtMDVFMC1E
// SIG // OTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
// SIG // cCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQB1rbmFkzS7
// SIG // qAK1Oav08AUnhbNIUqCBgzCBgKR+MHwxCzAJBgNVBAYT
// SIG // AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
// SIG // EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
// SIG // cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
// SIG // LVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA
// SIG // 7hr4QjAiGA8yMDI2MDgwMzExMjEzOFoYDzIwMjYwODA0
// SIG // MTEyMTM4WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDu
// SIG // GvhCAgEAMAcCAQACAhAwMAcCAQACAhMJMAoCBQDuHEnC
// SIG // AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkK
// SIG // AwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
// SIG // hvcNAQELBQADggEBAB3GhzUjaqfGL8BUEgztm9BI3+jH
// SIG // QRneurYH8tm7+w2+MqcsOVBGcGXRGYESpIWOWVKBYUXJ
// SIG // uxzWpYrxe3amwwH4Cgxs90PMA1nia3gwdGnu1ckXU+7/
// SIG // gWJylYe7TKGBwJXKRJbAvn2W7KxPn9TIwXc4gpe2bfKB
// SIG // 0snFXD+PeIBuAfuichG8sFl+vd8d7dydgrSZz2R8+thh
// SIG // VcexGFN4mKFEwg9UUwGZQJldCheDgbO/8Lc0r41LJ+ur
// SIG // Uq8fZ19T7n6TF8DUKDCKolh6iyNxwfcNE33CGpmGOsm5
// SIG // Qtqxw52A6M23VhZYEPf2uami/YkRepN3aqp6fZA/AECM
// SIG // on9orwQxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJV
// SIG // UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
// SIG // UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
// SIG // cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
// SIG // dGFtcCBQQ0EgMjAxMAITMwAAAijwpYfX88geQAABAAAC
// SIG // KDANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkD
// SIG // MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCA9
// SIG // luEdZXj/+ko2CtD55YmdgINbdHuAL8+Lq+cDmXqfVTCB
// SIG // +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIFWxikZR
// SIG // YGNf4oEVZK1eT45H+3GQ3/qxV75VwuBt+iLXMIGYMIGA
// SIG // pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
// SIG // TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
// SIG // AAIo8KWH1/PIHkAAAQAAAigwIgQgydP5qzybBDQ8I5gy
// SIG // YQqdSLTKsKhBrCudvvaPLeS1XcswDQYJKoZIhvcNAQEL
// SIG // BQAEggIAhTBrcVBuAmwDcTe/Npxo351OL40hzcNWOq4t
// SIG // dbCCG29PdAxSszQoA631Jzkr+9mT/R4yYFdcpn1HC1I+
// SIG // /gjbA+3UpkOuVdVMbH3fdS9aYRH+mvNmSvvc4OV66eEq
// SIG // wsLa+nD5VfeYRLt5VHfiRNcVwAnLOUuVbTtOV/cORXx6
// SIG // jOzEEuKOzfpRw4974j+sAwqT6FSJkt3rXd5NbaM9nNRu
// SIG // VZR03xn61ypvacQxNjN4zTIy1ziu21TvHQSQ8qs/wIHv
// SIG // jbgWNjgOXTF0cAl/NEE7NO6gLM5wjrtboAKBQoyMTGdG
// SIG // tDTj49bt9WxwXUrBttqwQ1P1XVYCa9HMF0q6WRFvVH+7
// SIG // Ezv2ykNryDc/0FFUpVI9eMp55hBpJxxAzYMUUD6UHd1/
// SIG // L0PjB2Wmqev3ihkJoNwDaYqY6e3PduVjmGUXYjDHWAZn
// SIG // cgYZk4uSRtDE9MyWBI3Kmq/bCI2B+Ziccs1EEQPYd4K9
// SIG // d8IvIzWkPLb2rlObtF57w5G+zcCdDx93APQ+VGfAXN1a
// SIG // yovq7WwOhrB/6QmDQcRZcEzaM+5gEMkELz64wEAbNFfv
// SIG // gRiav/m1s+BznE7DEQ+ofZjrODijHpqFyHwhv8pe9/1F
// SIG // nlT14HAOfOe5s+ju6/0fhgjd0QpznnGHy7PznVjsuuVJ
// SIG // /gakHjUWRW7W7j2mAwmcNgEesgKtiV8=
// SIG // End signature block
