/*! Copyright (C) Microsoft Corporation. All rights reserved. */

var iframe = null;
var subscribeToSrcLoad = function () { };
var maxSize = 300;
var defaultSize = '100%';
var iframeHeight = defaultSize, iframeWidth = defaultSize;
var pageTabSize = 20;

function InitializeIFrame(ratio) {
  SetIFrameSize(ratio);
}

function InitializeFullIFrame() {
  SetFullIFrameSize();
}

function SetIFrameSize(ratio) {
  var controlAddInElement = document.getElementById('controlAddIn');
  var controlAddInWidth = controlAddInElement.offsetWidth;
  var controlAddInHeight = controlAddInElement.offsetHeight;
  var arr = ratio.split(":");
  var ratioWidth = arr[0];
  var ratioHeight = arr[1];

  var heightMaxRatio = Math.ceil((controlAddInHeight - pageTabSize) / ratioHeight);

  do {
    iframeWidth = Math.ceil(heightMaxRatio * ratioWidth);
    heightMaxRatio--;
  } while (iframeWidth > controlAddInWidth);

  iframeHeight = ((heightMaxRatio + 1) * ratioHeight) + pageTabSize;

  iframeWidth = iframeWidth < maxSize ? defaultSize : iframeWidth;
  iframeHeight = iframeHeight < maxSize ? defaultSize : iframeHeight;
}

function SetFullIFrameSize() {
  var controlAddInElement = document.getElementById('controlAddIn');
  var controlAddInWidth = controlAddInElement.offsetWidth;
  var controlAddInHeight = controlAddInElement.offsetHeight;
}

function SetContent(html, javascript) {
  iframe = WebPageViewerHelper.CreateIFrame(iframeHeight, iframeWidth);

  WebPageViewerHelper.SetBodyContent(iframe);

  WebPageViewerHelper.IFrameReady(iframe, function (event) {
    iframe.contentDocument.body.innerHTML = html;

    if (typeof (javascript) !== 'undefined') {
      WebPageViewerHelper.RunJavascript(javascript, iframe.contentDocument);
    }

    WebPageViewerHelper.UpdateLinks();
    WebPageViewerHelper.ChildDocumentReady();
    WebPageViewerHelper.HideSpinner();

    event.preventLoadEvent();
  });
}

function Navigate(url, method, data) {
  iframe = WebPageViewerHelper.CreateIFrame(iframeHeight, iframeWidth);

  try {
    if (typeof (method) === 'undefined' || typeof (data) === 'undefined') {
      if (url.substring(0, 8).toLowerCase() !== "https://") {
        throw 'Insecure URL Specified';
      }

      WebPageViewerHelper.SetBodyContent(iframe);

      subscribeToSrcLoad = WebPageViewerHelper.BindSrcLoadEvent(iframe);

      WebPageViewerHelper.IFrameReady(iframe, function () {
        iframe.setAttribute('src', url);
        WebPageViewerHelper.ChildDocumentReady();
      });

      return;
    }

    data = JSON.parse(data);
    var form = WebPageViewerHelper.CreateFormWithData(method, url, data);

    WebPageViewerHelper.SetBodyContent(iframe);

    WebPageViewerHelper.IFrameReady(iframe, function () {
      iframe.contentDocument.body.appendChild(form);
      form.submit();
      WebPageViewerHelper.ChildDocumentReady();
    });
  }
  catch (ex) {
    WebPageViewerHelper.HandleException(ex);
    WebPageViewerHelper.HideSpinner();
  }
}

function LinksOpenInNewWindow() {
  WebPageViewerHelper.Properties.LinksOpenInNewWindow = true;
  WebPageViewerHelper.UpdateLinks();
}

function InvokeEvent(data) {
  // Receive events with window.addEventListener('webpageviewerevent', function (e) { });
  WebPageViewerHelper.TriggerEvent(data);
}

function SetCallbacksFromSubscribedEventToIgnore(eventName, callbackResults) {
  if (typeof eventName !== 'string' || !eventName) return;

  if (!callbackResults) {
    callbackResults = [];
  }

  WebPageViewerHelper.SetCallbacksFromSubscribedEventToIgnore(eventName, callbackResults);
}

function SubscribeToEvent(eventName, origin) {
  var originFilter = "*";
  if (origin !== 'undefined') {
    if (origin.substring(0, 8).toLowerCase() !== "https://") {
      throw 'Insecure URL Specified';
    }

    originFilter = origin.substring(0, origin.indexOf("/", 8));
  }

  var recieveMessage = function (e) {
    if (e.origin !== originFilter) {
      return;
    }

    var s = JSON.stringify(e.data);
    var callbackResults = WebPageViewerHelper.Properties.IgnoreCallbacks[eventName];
    if (callbackResults) {
      for (var i = 0; i < callbackResults.length; i++) {
        if (callbackResults[i] === s) return;
      }
    }

    WebPageViewerHelper.TriggerCallback(s);
  }

  WebPageViewerHelper.SubscribeToEvent(eventName, recieveMessage);
}

/// <summary>
/// Posts a message (aka event) to the current iframe content window for the target domain.
/// </summary>
/// <param name="message">The JSON string that represents the message to be posted.</param>
/// <param name="targetDomain">
/// The domain to post the message to. This must match the domain of the iframe or the message will not be received. 
/// Do not use the wildcard domain (*) as this is deemed unsecure, possibly allowing messages to be intercepted.
/// </param>
/// <param name="convertToJson">Flag indicating whether we want to convert message to Json object or not.</param>
function PostMessage(message, targetDomain, convertToJson) {

  if (typeof message !== 'string' || !message) return;
  if (typeof targetDomain !== 'string' || !targetDomain) return;

  if (convertToJson) {
    message = JSON.parse(message);
  }

  if (subscribeToSrcLoad) {
    subscribeToSrcLoad(function () {
      iframe.contentWindow.postMessage(message, targetDomain);
    });
  }
}
// SIG // Begin signature block
// SIG // MIInbwYJKoZIhvcNAQcCoIInYDCCJ1wCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // K/T7jnK2YQnYVTbIYH8LmjtMVoXn+uPVg+wzpzjyNTGg
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
// SIG // BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD/3xo7gvYW
// SIG // AadmSaU5mPhed3oAiewnfiF5hRcd/g61jTBCBgorBgEE
// SIG // AYI3AgEMMTQwMqAUgBIATQBpAGMAcgBvAHMAbwBmAHSh
// SIG // GoAYaHR0cDovL3d3dy5taWNyb3NvZnQuY29tMA0GCSqG
// SIG // SIb3DQEBAQUABIIBAHmgW+4I8ERDbpufOtRdFsfdEUUD
// SIG // +KzT+NijyP2TUUyUTYmq3R1mxd5bYgvwratp8O4fPTYm
// SIG // Lzy4/bG+0Fr9QcuEKT+jc6yhDLzsMnigB2qn9wIkfzZl
// SIG // +tg6Rq5byoSF94CHKlFOcddCQL5R8EJqehqrpzUpEiD9
// SIG // kU4K4o7W905eXTqJab8/0D7COdgP2ZodkTxs3YWXgK3Q
// SIG // r2DDtJ6fm7KgJ7uLuKxo3MgzNtnGbUsKwdU0/3o98dE+
// SIG // u38kMwEjKkgQCVJNjnyK3xb6/106uXV0GW5LVSvg3PXt
// SIG // +yY9D++ppGrhP2IPJIidu/o4vf6VB+967IQPmmWrJj+L
// SIG // bqKo/IihghewMIIXrAYKKwYBBAGCNwMDATGCF5wwgheY
// SIG // BgkqhkiG9w0BBwKggheJMIIXhQIBAzEPMA0GCWCGSAFl
// SIG // AwQCAQUAMIIBWgYLKoZIhvcNAQkQAQSgggFJBIIBRTCC
// SIG // AUECAQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEF
// SIG // AAQgJwIqje+eiNAsahbg6UdYYcWtbhNenkrT8vglIj7E
// SIG // 0/YCBmoZwizl5BgTMjAyNjA2MDExNTE3NTIuNzQ3WjAE
// SIG // gAIB9KCB2aSB1jCB0zELMAkGA1UEBhMCVVMxEzARBgNV
// SIG // BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
// SIG // HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEt
// SIG // MCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0
// SIG // aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRT
// SIG // UyBFU046NkIwNS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1p
// SIG // Y3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghH+MIIH
// SIG // KDCCBRCgAwIBAgITMwAAAhFFGDmbQ8/8bAABAAACETAN
// SIG // BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMDAeFw0yNTA4MTQxODQ4MTNaFw0yNjExMTMx
// SIG // ODQ4MTNaMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
// SIG // V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
// SIG // A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYD
// SIG // VQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25z
// SIG // IExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
// SIG // Tjo2QjA1LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZI
// SIG // hvcNAQEBBQADggIPADCCAgoCggIBAM+5uzMQHS+VWsq5
// SIG // O47DKNxp4TfOZLRwmRLxHI+ASHHBynfzSgu7j76V+XYT
// SIG // ut1ulTOYgsZJRvKkHlVaz2ir4/HWGCQuwzbeDTd15VXQ
// SIG // v76L3ibjz4Uyf7u1/qWJldqnoU1Tzjgdf4aZredUs4MW
// SIG // XMzHZxZfl9ntT4LrUgOQgIff18+TVtAsZ2Fc/INFacYP
// SIG // gat9mppLUV6/JtwUhIFLPI4FkT1czxxHM6W4ZaBhhHx2
// SIG // kTph4VSiKjfiYTMHhI1NjVzNluoZt9o/0B/yPylqjTX2
// SIG // HIR2htMSZY1U2KFCj6XEA7oR/XUChILxsY9lOf9xatXp
// SIG // uHTuiIdOJukfrbca+mPKESR/WYWd7HIhQSL2YexNmBVz
// SIG // oz+DBsm0spUEzwxBQLRx4KZLJHhFIbDw0fVb1loXpIUM
// SIG // d6l2gCofgJC5s/4aRN3tMvkSCjtgERI1CyQCoH/kfUJz
// SIG // b6jHjJM/Txq47Io6lhswdpNiTcmlGCpW5kMHjmm7AoqI
// SIG // mNnyW4po1chQBpOQHmHXVBcbyRoEVQh+wXgTygKuzDDp
// SIG // kgkzjGdEsOs8jceFIYeWNLidGTqEypwdyn3Tf22v3ihx
// SIG // XhIYt1qgH808YstKzL4bH7F2Su86HJamkb1ZfEOPCde+
// SIG // Pnsq4sqWPR4VPqIYImIuLkBgw1XUw3ig7aAv4Q9gp/gE
// SIG // c8BNaxXxAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUYn1F
// SIG // A8Dp6iHL32+d/sldBGZ+znAwHwYDVR0jBBgwFoAUn6cV
// SIG // XQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
// SIG // UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
// SIG // cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBD
// SIG // QSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
// SIG // BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
// SIG // Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
// SIG // LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0T
// SIG // AQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
// SIG // BgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIB
// SIG // AKRCnZzHiCFIlOj2rWf6m68Ig82FDCkXMwuAaf12NUvT
// SIG // ZhyPtnN3XKcB9kjpg33byCKre5ka4LwT2DryfQrWUuXn
// SIG // iK7DmwtG9IICk79sK04FhvqpLajRRIUHoqXVETSzevLh
// SIG // wJuXncAcrXdZMMua+gfd5JcQ7JXTplVrcP54I+5JzdPZ
// SIG // rgpsK9eyZ7DBXKCDfx+fbPtUWDe1YnePu54/BXL2Mva2
// SIG // 2TjJ3Qc7E4qLBdTPmjCCV9pNxFRVbLgy+/0eaaSPU4O3
// SIG // lkDlijGRz3bAN2alsw7oSak86BUkEoZ2Xpwvsav8/QYR
// SIG // zxRW1LX4wKBuhAz40kCWF5qII2vDhGtfccJ4d8Fbn3j/
// SIG // nJPv9IMTYu4PpDulmjptOdheLIg/MYulL++S++/fJR7z
// SIG // 04XMRx7IF6jGOfdndcFKH97S/3g2kNFIZ2AlPMhpFNly
// SIG // Z3LTjZwSgL1EQL39qoiFg4+C6XJtMwO1bqH7iUdU6bsn
// SIG // OadY2udmzWQQVagDsMg4QJqlrCVwI2F57LAv3yZHnt9e
// SIG // BYfhiMjILwD0UnIKkWaldenUwWL6HvsNZ/8FrP8kk1LM
// SIG // Q8OE/wCE3LuTwLC5wlaQKw6xS0Uxcrrfnh1KBulGGX4/
// SIG // P0bLkONiDbHtaW/3D5uxtpXCybZCCk/NMbwdS4mjbz0w
// SIG // VRHJjUrxVDNMa12V3GHMVV4mMIIHcTCCBVmgAwIBAgIT
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
// SIG // dGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NkIw
// SIG // NS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
// SIG // aW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
// SIG // ACsqfKtlXYAKtVRpM3ez2cFeszXNoIGDMIGApH4wfDEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcN
// SIG // AQELBQACBQDtx4xEMCIYDzIwMjYwNjAxMDQ0MjQ0WhgP
// SIG // MjAyNjA2MDIwNDQyNDRaMHcwPQYKKwYBBAGEWQoEATEv
// SIG // MC0wCgIFAO3HjEQCAQAwCgIBAAICIrwCAf8wBwIBAAIC
// SIG // EjYwCgIFAO3I3cQCAQAwNgYKKwYBBAGEWQoEAjEoMCYw
// SIG // DAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQAC
// SIG // AwGGoDANBgkqhkiG9w0BAQsFAAOCAQEAQIFxG+mJdHQF
// SIG // xFpXxrJ5F6fCstojMM65ugGVAagAdKrcLhbAk6P129ST
// SIG // IcVcPp5aHDIQpxIjryOsaqR3Bq9vfEm8hBDalJRvldOF
// SIG // HcA1xYGHmCDxB792GTiTcw9dZFhnOLCu3vyOf65vykmG
// SIG // RyMXWH1JRzvowZWEmCms2tKgRNc/z5maJnxoNk/aLH1R
// SIG // Cze9WJnsH+LitKD5x1o1ODz2hVLkuTZ1aOvQa6ZcfXS9
// SIG // 86S1n0HZVYxegRN1Ugd+aSJEY6M56Dz1Ns3FAIIUgYEu
// SIG // VVjlAbTkK2O2HFyhOgeeb2VqlqeT/B3qLKxKpFWWxjZF
// SIG // /cybc9nxMU19e25BA0cErzGCBA0wggQJAgEBMIGTMHwx
// SIG // CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
// SIG // MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
// SIG // b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
// SIG // c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAACEUUY
// SIG // OZtDz/xsAAEAAAIRMA0GCWCGSAFlAwQCAQUAoIIBSjAa
// SIG // BgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZI
// SIG // hvcNAQkEMSIEIMkTPgU/JDfjO36/fFVrOB805SVego4y
// SIG // 1RZCfYixFj36MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB
// SIG // 5DCBvQQgLK0zqZrvh06tWlxcL5YYxfKdp1AjTQhF/zli
// SIG // xzQzJrcwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMAITMwAAAhFFGDmbQ8/8bAABAAACETAiBCD/
// SIG // VjF6YDuzIn2I86dVLIoqvorqyv/8ambkwi17wUGE8TAN
// SIG // BgkqhkiG9w0BAQsFAASCAgC7REbAOZm/N09P8VhrIY3c
// SIG // 2FMOMrLUTMKaDKwdbo5GQ6QNGv0Wir0RiHc7KNQs8p5j
// SIG // Fo8e7UibjXXFadjE7LbO0PHLSp+aHqT3+P8BLMTtYTWt
// SIG // 3ni37hWFzbXoiN6P1Xdy0P/SfURqB1dx7mrUE0Z0WBDg
// SIG // QTX9bVhWwoUmlK2Jhdzi6nNQYg9IexDzHxtC0AD5+9u9
// SIG // EBqHWTlfv65X68OOF0z4o+Oho2WiQcASYb7Uu5wVxHRU
// SIG // KQlx7wgxw696FdgjL5lyU09gC0ypWomLFChW4H9z7JVv
// SIG // NCBbmfbkOeadVWJ6VesYgnKshj5vKgG/lpcvpiqTyCaq
// SIG // Ea59itb/hObM4pxBbwa00YNVDtqlt2eTfIr5MXLjrIPL
// SIG // MaP+h+L/IcTAnKAZKzb7LlryTyiSM/bh3jXQ9x4XiI0v
// SIG // jbzzDy2u3dHSloU9sdUYEwUvBtnkcDuzsXB5VBkIhuFl
// SIG // PfmN4XH7fN9ZD61MPNm39QlUhIrsxUEYlNBsVZlHcnqs
// SIG // 6XPhfGhmIN4EQ6t54H6YRUH0xHynpip4LdA9MRx+7kIz
// SIG // 0P7KtrmJyg38OsnC9nc1gTfe6IOSQWfur3ymrd9R2dhw
// SIG // emgFadReH+/umjoumpudYWgJQbyrkWATAsQUkb/nFeXg
// SIG // mLgPk6QIs9dQmPhAc8kJS08w277tjSNaMH39NM7JkmhPgw==
// SIG // End signature block
