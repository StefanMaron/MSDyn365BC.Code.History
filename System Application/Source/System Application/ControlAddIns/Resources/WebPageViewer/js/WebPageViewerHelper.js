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
// SIG // MIInbwYJKoZIhvcNAQcCoIInYDCCJ1wCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // hrzT4aeocEidJtWlFnZ0el78HeuKzeUoXt9/RzAlG7mg
// SIG // ggzJMIIGBDCCA+ygAwIBAgITMwAAAhz6zcWb6C9+xAAA
// SIG // AAACHDANBgkqhkiG9w0BAQsFADBXMQswCQYDVQQGEwJV
// SIG // UzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5n
// SIG // IFBDQSAyMDI0MB4XDTI2MDQxNjE4NTk0MVoXDTI3MDQx
// SIG // NTE4NTk0MVowdDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
// SIG // Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
// SIG // BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEeMBwG
// SIG // A1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjAN
// SIG // BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1bGX4Dip
// SIG // jN9Rz36FjqDRIsNEpQoiMVDAtCPTTFm7nCjsP3vZT6AK
// SIG // HoUFbukhuuVeBD862LJwZxTzaIuPx6DnY4c9apKxLeCO
// SIG // rRHMV1OqDnmPcxr3gv94gXroS2MTNzPz5HFKHmxfjXnZ
// SIG // 5vDpHUj6A7vIplYhz0Kv/AkFLtFkUeKxPnTEX66Van5j
// SIG // Ytqlgl/eE+DLHqYoxlZMBP/7SYNK8gImHR09+C0p5Rv0
// SIG // UgWZkERlmeYPI6pyo0T2q0qjH7dYL47lE1YLVjWX4HCx
// SIG // UiuVmtJsq6vDj3IExhrEYLp/rZ0kviMQ08VbADx9Ts7z
// SIG // 48KJoLgcoVHvznL1DdA+Vpqe8QIDAQABo4IBqjCCAaYw
// SIG // DgYDVR0PAQH/BAQDAgeAMB8GA1UdJQQYMBYGCisGAQQB
// SIG // gjdMCAEGCCsGAQUFBwMDMB0GA1UdDgQWBBTaB+2tmA4z
// SIG // ksKZKegx3JlEuyftMjBUBgNVHREETTBLpEkwRzEtMCsG
// SIG // A1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
// SIG // cyBMaW1pdGVkMRYwFAYDVQQFEw0yMzAwMTIrNTA3NTY5
// SIG // MB8GA1UdIwQYMBaAFH9ZP1Qh2q1P7wXl5qPXLQaUEggx
// SIG // MGAGA1UdHwRZMFcwVaBToFGGT2h0dHA6Ly93d3cubWlj
// SIG // cm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
// SIG // MENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyNC5jcmww
// SIG // bQYIKwYBBQUHAQEEYTBfMF0GCCsGAQUFBzAChlFodHRw
// SIG // Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
// SIG // L01pY3Jvc29mdCUyMENvZGUlMjBTaWduaW5nJTIwUENB
// SIG // JTIwMjAyNC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
// SIG // 9w0BAQsFAAOCAgEAFJxKoWkV3tE94SCY73UBKxJKwP+2
// SIG // wco5+reSAKzg5JEY85GMLSjHNsmI9qrmjay7rVsNmGXJ
// SIG // 4Cj8tW+9WMgyUE8uDQ0cGkofU8ObYa5NzZnD6wB4mub7
// SIG // XASdQoLSiu5kGyHENtnfzd/Nd2sggwxXsLtfo7GZl/q/
// SIG // 2kxKmjjOE1cVbUUpLgsvJwFyrgoTii4v8wOF7h/IhGKi
// SIG // LI9mKDWnksVZnhohEV6SnaN3Q5mItJDucNg/FUuHN/vY
// SIG // eoBJWAWgAIP3WBKwYNu6k9779M0QyYSbn7wjcpQPEu//
// SIG // vB+RPz1eXJ4Op2vVVf8PTld6rrjQ+s3RmthF9/BpaedB
// SIG // fQCEJN6dsV5nL6Kw3jOFye1JVmAYuoPNCdUkjkJyJwmB
// SIG // RJrH1DZ9/tQGkySkiS/N6rigK02nNqSobtGM88686Oh6
// SIG // 7EYkCs6Z0QW9f3TGuj94c++V2zEQXLTbBYWQtO1gpoxM
// SIG // XS4Nnh1ubldE2PA+fusKMyX+7xd/lh5GDzvOWfgQulOB
// SIG // ZDW2DcnGfXBOI9bV0Xcgwn5penNB1jx4zVQzm67/ZSrd
// SIG // 6lKhaV9/FQqlQsjTjtVHF30IlYycN9lNllCmY7f53iSh
// SIG // xAbJvZBbC7ls5EOd/qnGkmsrZrAp5NoDoJa5Q+Xd5Csr
// SIG // 7wMPq85tJU/Ct/D+jy8X2UB4buFvHVewL/DdmZgwgga9
// SIG // MIIEpaADAgECAhMzAAAAOTu2Nxm/Bh1nAAAAAAA5MA0G
// SIG // CSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZp
// SIG // Y2F0ZSBBdXRob3JpdHkgMjAxMTAeFw0yNDA4MDgyMDU0
// SIG // MThaFw0zNjAzMjIyMjEzMDRaMFcxCzAJBgNVBAYTAlVT
// SIG // MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
// SIG // KDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcg
// SIG // UENBIDIwMjQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
// SIG // ggIKAoICAQDYAZwe4zjHqpUWBzWtuub+CGPXx/EyoXph
// SIG // 3zyDXtYKS2ld3YYN9uFsB9Oi3B26Z7AbpAgzYra8qNHb
// SIG // UvxFuiP8hC/2y0mPISqW30LlrrAT6/ams2HA8Qlv6p42
// SIG // +SbCNbPGzToN21QE70FS+LXH9N2k8nLM/EHgnTNJf8h0
// SIG // TmyfUKmszNa+lTxDieyy/rhBG+98OkArobPPWtbr9c3q
// SIG // zmDJ7J3kUcAm6cltdSHIIFNHESgw6taY1ScyGyBevqIl
// SIG // 120XjrIHiPM7tRckHytH1ZGsmvEplR0P7Tn9t5meFvZN
// SIG // EYttkFvad1IEguTlA5LSscXAphi+rVy3zhklhyCFeGK0
// SIG // yU0+jzbcuURKIxybmRwK5BfVZx0xEVqE4wM3yN5D/uW+
// SIG // GpVHYYAGe7bTrtW1Z13x2qj2Jdqz7NtI4tNyzlVrIf62
// SIG // nYBNe3rOYS/repVdHlR61YbLLETlibs9jFzAre4sO5RT
// SIG // xvS1yho7JqJ59oKLRnRyLhIOSZyTCVZosXeS0ZZJoGEW
// SIG // Ss4cUgsMqBiKtD4WgO2PlT3LeaQh5Io3CCA5tJ5ZCvtC
// SIG // snqaJXKhptE/xmEETIRyZRjjplUKKd+sFFVGJJVMvvrw
// SIG // 1nhIBKOLO4cTepiG39jEiEP4iHzGYCcQuvaLpDFFwqzg
// SIG // t0pBP8SJIKX5dtjDNYrZGd+ZzV5DKJVNZQIDAQABo4IB
// SIG // TjCCAUowDgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcV
// SIG // AQQDAgEAMB0GA1UdDgQWBBR/WT9UIdqtT+8F5eaj1y0G
// SIG // lBIIMTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAP
// SIG // BgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIx
// SIG // kEO5FAVO4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuG
// SIG // SWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3Js
// SIG // L3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8w
// SIG // M18yMi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUF
// SIG // BzAChkJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // L2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
// SIG // Mi5jcnQwDQYJKoZIhvcNAQEMBQADggIBABSUHzgoT+6J
// SIG // 5+nyyDCq0pTdVmCsAxYAHXcpjlDtxazPHewf1v4kOg8V
// SIG // 7A5+w+VuMDMGHi8rLXBKn5I8+DVEUYGs8jLuckc0IeC6
// SIG // owOLUrU3CYdaKRMaO55+T7jwWJ27tPkx0rlR03tFU0z1
// SIG // YYpcv6Yhaw6N2sUPT+AvjpecnrftoE33pCAkucUvnGH0
// SIG // iL4J9CZLFQVTGFSOUBbv6oZy4bBBRFMxvH779IY4JDvp
// SIG // ZKVfbcuhpDeL3Z3e8mukOmkfct+GojNapsWsQYujlJ8j
// SIG // Zen5Lrp/3YkxZ2Ay06aTpK/5oOVknwog1TDQsbY+MDyg
// SIG // uTph5tQ0CLfzDaJG2x91BrBT9UG87C6HLkqiwrx9PSKN
// SIG // 3wz05rHEfWO+RuKl+0U1/AHQT6NCOjhKI39/c7hWbdKj
// SIG // h5uuWFkBOvXGTNrnhNTAdOXTTYByvYExO8yryv34PAdq
// SIG // o1vPDE/1heVebr2RramvRUi9kWswKwPqwz7n+iRmM+B6
// SIG // YDGRweEurM1kimAb9FYrAs38YHlPnarl1vW3dGrmJTge
// SIG // fAz3DmCnXN0nveIPsS+KXBIWweeCToAJMGE7v/XS3h9q
// SIG // Q6niWQAAVQ1kUAml3zuS4MisCgi2F6YoK2WAo1EgXK/l
// SIG // XvDxVjIVU0JdL+KvCfwFJkDeVuJ9dNXGNi+AOxk0BtYd
// SIG // 9hxwL30BElj9MYIZ/jCCGfoCAQEwbjBXMQswCQYDVQQG
// SIG // EwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
// SIG // aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWdu
// SIG // aW5nIFBDQSAyMDI0AhMzAAACHPrNxZvoL37EAAAAAAIc
// SIG // MA0GCWCGSAFlAwQCAQUAoIGuMBkGCSqGSIb3DQEJAzEM
// SIG // BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
// SIG // BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD+BYy7aI2j
// SIG // Z8rDyymfmlaFFuZkOoo0uwUCu4m3QXdOmTBCBgorBgEE
// SIG // AYI3AgEMMTQwMqAUgBIATQBpAGMAcgBvAHMAbwBmAHSh
// SIG // GoAYaHR0cDovL3d3dy5taWNyb3NvZnQuY29tMA0GCSqG
// SIG // SIb3DQEBAQUABIIBAF1z54IoKalLfqXqk/BLGOpbbbtL
// SIG // cCNnkvs527+WNeHba8J1KArwJshJnHLjU0SYMZusGyEl
// SIG // ZSDNPaEZZFmCEr9GUlrRRbBDWHVNn+nLx3r/0l05JEWB
// SIG // EuLqtQRsWkKeDkGU/zbE0HPDVqHjPp84ibtjX3lihzTF
// SIG // gnRRe3eNHfVvjO33+SAtJNHxc7uSJdle129p6Jg+pph9
// SIG // eT5A7wfsCYxR2WotidrJNvN+JLAfdX3lJpJrGRdF8yx+
// SIG // VcJB3W7aWWBJEFR98M84stVIVYSgmPouLcdKJZv1vp9V
// SIG // JbW4KdlIZ98OCFFm7HCVIpu1t+of/ozsxf9q7+Jhe5z+
// SIG // JEBGgM2hghewMIIXrAYKKwYBBAGCNwMDATGCF5wwgheY
// SIG // BgkqhkiG9w0BBwKggheJMIIXhQIBAzEPMA0GCWCGSAFl
// SIG // AwQCAQUAMIIBWgYLKoZIhvcNAQkQAQSgggFJBIIBRTCC
// SIG // AUECAQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEF
// SIG // AAQg7FZ/W0NGs00twTh4GbMWuAGUZoKXEcsAP739/JwQ
// SIG // 9JYCBmoQYWXxvBgTMjAyNjA2MDIxNTM3MDYuMzk0WjAE
// SIG // gAIB9KCB2aSB1jCB0zELMAkGA1UEBhMCVVMxEzARBgNV
// SIG // BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
// SIG // HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEt
// SIG // MCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0
// SIG // aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRT
// SIG // UyBFU046MzYwNS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1p
// SIG // Y3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghH+MIIH
// SIG // KDCCBRCgAwIBAgITMwAAAhOwQzVmz6+V6AABAAACEzAN
// SIG // BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMDAeFw0yNTA4MTQxODQ4MTdaFw0yNjExMTMx
// SIG // ODQ4MTdaMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
// SIG // V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
// SIG // A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYD
// SIG // VQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25z
// SIG // IExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
// SIG // TjozNjA1LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZI
// SIG // hvcNAQEBBQADggIPADCCAgoCggIBAPSZeuC6GcQyDUhY
// SIG // M/vSkuTs7+ZuePHj1c3PUV1nuE+PzKZX4GuHqtdkRnae
// SIG // XFb543Xub8X6tmsf457u71FuK2TeJjlJub4fpHGLEJWE
// SIG // OdxcICAd5xI3EB6Jqxt5mXv6M4xUgK+iW4JSrSHgMkj8
// SIG // wHBc8gHq+ZSzVBwRL0DDPATozMmqQr4dMbIOMShXFRCU
// SIG // CyhHwhgX3zGSP2prrRxW9wlE2e2laRtihxBVDZWdb8DC
// SIG // r8V0z0Q528Dxs8sqiSc537CzR0OL17drbUtT3gqBiNIT
// SIG // dT3qvMhrCFzPaKHMAtOgxjUjP+CwMdrir8JlJ+jcC3NP
// SIG // rZr58usNvK2S3o7JEX51VqHxL9ZlmNIx1Jx68EhgUvIF
// SIG // T/YHAbOj+YNDqSTzH8XVJB10ZHDDz1tISD/DW1vFuUrq
// SIG // fB7sJ0im46cgJRgVHTP1ea2W9LGZpJ+9eK+lCxivnCyw
// SIG // DekdxYV+jdJ4+uBduy0ytgW0tKSWWl46NHgzc9UHMXiB
// SIG // S1IBfkQbC2A5/BPHApHsSvDZbdxovcyX+ecOlH02fpME
// SIG // zMTKhcYe/k38e/mgTm2fp8fetQLYqgMu81VevaPy1kXS
// SIG // j2Xb2Z/REshm05z345AREb9tqa0pRE5UcMz+m5hFTili
// SIG // 1lcMbsIe21FlLlG9XI/d877bUGBkGreRPQCyyTZpbyyg
// SIG // rJAe62i7AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUE54Q
// SIG // Ssfha8qYUFjEYqR+PbDBQDowHwYDVR0jBBgwFoAUn6cV
// SIG // XQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
// SIG // UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
// SIG // cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBD
// SIG // QSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
// SIG // BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
// SIG // Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
// SIG // LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0T
// SIG // AQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
// SIG // BgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIB
// SIG // AIJsWiaxqkNg+lCYWekJdkmRTmjbhm1ty8wfhEvpdgQd
// SIG // TCbQUUhXYv4VWN9zacbCUIUOUy1adA12DpCKD0HNe6x/
// SIG // iFYXpjvIwrflOiNUyMOnEe3PrRKPyY6ehKhFNXOP5q2j
// SIG // I4B4UPq2gvzlAJvfANa+GyDx7bAZi0ThpnhOVyyBWgSG
// SIG // Vh74dgjlyEyjm11XecBrSdXWWXcGhwAlxedOo7WvrqFH
// SIG // cswHrjZUzy062fJ8ocRsJPVYenog0OwkDFkkmvAyUvT1
// SIG // F43qIvb03Uu2TF6rvrb+kM98baARefmBSuLhPpohrPdB
// SIG // cZtFStpVq5hYY5EZec8qBzncBu7KTWJA6JgjzViLnVEJ
// SIG // kGCqbfx7LKX3G/saZ1iA0HTM4BPKY9b6cC4FhJx+y7U+
// SIG // HWQnqA6PTyuNEcQQ/JCie+vZ4JBMH8Ag9hF/zEJO/XiL
// SIG // zoaZx9dhrlQcr2imZOV2b6rTzjTcK/Kv6gN/O+yLlsFo
// SIG // J2nl/qa6cNHWf0C7Wxhla4D/k0UI7ftnXGQOT91+C8AD
// SIG // YYj7MtDpeFwnY+zsQSxbzs7Ajwz2lZ5KfnXwxRvjTgYq
// SIG // +2qkyevOttqcpoNVfuoHP9Ub8Qv8IL2MhtN93nCar9Dp
// SIG // 9GUTWK/ovzpMIANxz9Wiw9Gh6xKcOpbdNut4kZAr63HX
// SIG // DlvMN4wvEybmhlsgtkvYxI84MIIHcTCCBVmgAwIBAgIT
// SIG // MwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsF
// SIG // ADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
// SIG // TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
// SIG // aXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMw
// SIG // MTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
// SIG // V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
// SIG // A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
// SIG // VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
// SIG // MDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
// SIG // AOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjK
// SIG // NVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
// SIG // hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ
// SIG // 3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2r
// SIG // rPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d
// SIG // 9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4x
// SIG // yDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3
// SIG // rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75x
// SIG // qRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9
// SIG // fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PR
// SIG // c6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1D
// SIG // TsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC
// SIG // 4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTY
// SIG // uVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqv
// SIG // UAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUe
// SIG // h17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TAS
// SIG // BgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQW
// SIG // BBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
// SIG // n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBR
// SIG // BgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
// SIG // cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2Nz
// SIG // L1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUF
// SIG // BwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsG
// SIG // A1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
// SIG // IwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1Ud
// SIG // HwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0
// SIG // LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1
// SIG // dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEww
// SIG // SgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
// SIG // LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAt
// SIG // MDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38
// SIG // Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEz
// SIG // tTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6
// SIG // U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
// SIG // y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jf
// SIG // ZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kp
// SIG // icO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNh
// SIG // cy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtP
// SIG // u4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4K
// SIG // WN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMB
// SIG // V0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvsh
// SIG // VGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFs
// SIG // c/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8
// SIG // vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgk
// SIG // NWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9
// SIG // vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFx
// SIG // BmoQtB1VM1izoXBm8qGCA1kwggJBAgEBMIIBAaGB2aSB
// SIG // 1jCB0zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMk
// SIG // TWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1p
// SIG // dGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzYw
// SIG // NS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
// SIG // aW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
// SIG // AJgRPEgo8YI2nJsvP1RHZOzcaUemoIGDMIGApH4wfDEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcN
// SIG // AQELBQACBQDtyV9hMCIYDzIwMjYwNjAyMTM1NTQ1WhgP
// SIG // MjAyNjA2MDMxMzU1NDVaMHcwPQYKKwYBBAGEWQoEATEv
// SIG // MC0wCgIFAO3JX2ECAQAwCgIBAAICCB8CAf8wBwIBAAIC
// SIG // E1owCgIFAO3KsOECAQAwNgYKKwYBBAGEWQoEAjEoMCYw
// SIG // DAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQAC
// SIG // AwGGoDANBgkqhkiG9w0BAQsFAAOCAQEAzv82IML1FjvT
// SIG // gSNlA1AZuzGYhXvkaALAfV3unerf1PHJDmVq4+FYohZe
// SIG // BhIOuW7dbuxFymx4xOuNH5YoL7gOLMG4+ZdbbzZukPxB
// SIG // xXbMCI9GsrMKEBNvwAu5bT5uTr+H7xE5xo3bRbOorBDS
// SIG // W5+9SjzVm1OLWiPCXFPnrzFzdS6E2SN4qHpBBljplthP
// SIG // 3CBaBsOVM5rvoakRJyBcXyaKxljeW564S7ClWpZUK/Ky
// SIG // +bmEYnLgGLQkgfEBZ77YvZX6n8qJ1ssZadwMMnjM+yG+
// SIG // iS1j5ysQt9cP9arylyOSnSsugYC42bPEdo+yE8LouOQ8
// SIG // VdvtORXjUuhSc/GRSxP0uDGCBA0wggQJAgEBMIGTMHwx
// SIG // CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
// SIG // MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
// SIG // b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
// SIG // c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAACE7BD
// SIG // NWbPr5XoAAEAAAITMA0GCWCGSAFlAwQCAQUAoIIBSjAa
// SIG // BgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZI
// SIG // hvcNAQkEMSIEIEbwqd/Kw8SeDl/b/FhNn7WRtFfg9k3O
// SIG // ZQkczXJj0ha3MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB
// SIG // 5DCBvQQgzOEJbRSFM/CeA4wMz+J1aHWb0MWBpXlCH6fO
// SIG // jmucWGgwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMAITMwAAAhOwQzVmz6+V6AABAAACEzAiBCAk
// SIG // 4BIz9uwpTZ/Du2dZgD8WKu1Ov8jPRQ8cEGb4G6bW2TAN
// SIG // BgkqhkiG9w0BAQsFAASCAgAbpkriMg9J+o7IuSPJ6qOS
// SIG // POZmpf9DrwB4ubefGtHaRn3eyqp96cLbGT+Mk5XQNG1x
// SIG // j0lL4quFrGWFvSoIMwnCZnTE/yX6pRAgvVpxbgGBo2pJ
// SIG // glCpZNCKG2n8EAsZEL8y28K2/b+0t/6uVivU4WgD04gh
// SIG // 0Rn89xBRCUcdj+JwQCEpuN6oWQlmOXX5DK4OaLJtsaYn
// SIG // GvibPw0/CzIKJP6c8lFs5kJGTuPkhlfFejLf2wp+qVnl
// SIG // q+SfUruuxU6/yfXuSnVy0y6McVpIt6MoxIlfIP4yaWjW
// SIG // vbLINd/XizYMOePgMLEetikbOAwBNSvCXk5Y2k2mpGFZ
// SIG // 89AN2/Y8c9nx2zuWZyiOJGDiNjrzOsEYD1Amj2mTL1AR
// SIG // z5xGntmO1t+lSiyxbvjCTv4be4f/JW/kANgjgUzHeHkB
// SIG // t3Z4WAxqQ334tFrm801qA6scuCSMkmTRL/zlydeS5xuQ
// SIG // xVcdldz6VaUhko+pxZQ6f1BZgCuPK/jDDugPKxVdPxMc
// SIG // sm/MMI8rgZqP8xjOMX5k8k5YIUxnzEByR03l+NlpBWKq
// SIG // tn6tBKtpES3mCByQ98CyxJNOyJRVuJWXrIJaZqZa0mP8
// SIG // uqb29VJe7jvZ2QsyR40TowWVyq6F75NflbYgJfybjjkr
// SIG // S1xk7bpbWog4g7+Ye6jaLLb1JLV/g9vkIbwu7rwHC6yhEg==
// SIG // End signature block
