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
// SIG // MIInRwYJKoZIhvcNAQcCoIInODCCJzQCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // K/T7jnK2YQnYVTbIYH8LmjtMVoXn+uPVg+wzpzjyNTGg
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
// SIG // JkDeVuJ9dNXGNi+AOxk0BtYd9hxwL30BElj9MYIZ5TCC
// SIG // GeECAQEwbjBXMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9N
// SIG // aWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDI0AhMz
// SIG // AAACHU0ZyE7XD1dIAAAAAAIdMA0GCWCGSAFlAwQCAQUA
// SIG // oIGuMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
// SIG // CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
// SIG // SIb3DQEJBDEiBCD/3xo7gvYWAadmSaU5mPhed3oAiewn
// SIG // fiF5hRcd/g61jTBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAEcw
// SIG // MlO0AkmoW6I3LV3LklpVdNzVZ/wHuePMLQhdAoEpSXjz
// SIG // QIj5IQlJjHVC3+Oid3SjrJ8O03V9pOMbng5Dvp01ya8+
// SIG // gRJkf4m6kXRnWyGTpcamaczq7NIm835AsIUWfAZCl9N+
// SIG // Qs3QRMLh7OrXYt8QAehvq76oR5qkdCesSSrK5cQV1rTG
// SIG // bHnJZtkz55sAQx8MObsXgEyhJ/kZaEqkFibuvP2/QMC9
// SIG // oSCZEAFIxfjerzQMA9u2cizrgwMUPF8xcmgCbRVhPZ5S
// SIG // n+yAxhtyE4oXCGEQcM+G8+zhYHkAOJrH56y4gSAZBJGg
// SIG // 7N/6vvXlMLoU894IyLtSBadku/bYh2ahgheXMIIXkwYK
// SIG // KwYBBAGCNwMDATGCF4Mwghd/BgkqhkiG9w0BBwKgghdw
// SIG // MIIXbAIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQgO5QFa1RJh0EbgqS4
// SIG // 9rVXIjj+eotGJYrakCxv/1JE3yICBmoxnCJjLRgTMjAy
// SIG // NjA3MDIxNzM3MTcuNzg4WjAEgAIB9KCB0aSBzjCByzEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
// SIG // b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
// SIG // blNoaWVsZCBUU1MgRVNOOjM3MDMtMDVFMC1EOTQ3MSUw
// SIG // IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
// SIG // aWNloIIR7TCCByAwggUIoAMCAQICEzMAAAIfOnBp5KIw
// SIG // LpUAAQAAAh8wDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTkzOTUx
// SIG // WhcNMjcwNTE3MTkzOTUxWjCByzELMAkGA1UEBhMCVVMx
// SIG // EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
// SIG // ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
// SIG // dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
// SIG // T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
// SIG // RVNOOjM3MDMtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNy
// SIG // b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyzvFxTnHxqgK
// SIG // oIs9PgJkJhZd3WdGkxuFBSZKqjXTB8tvA2oXggbOjjbn
// SIG // 7pMnuceNglpM4ESMvZBNlVsBJ7WfGZIMq8pAtGyKrCA+
// SIG // /uhcYLrHk139VcL5tQ/NdOFZnraASZSeLhm7siWVL1w8
// SIG // eeZ1YedMoC082duFpELJz6b0Wb9pD3N/X924S8h1bZx7
// SIG // Gv1v/Ola37XfgHxb3gPqjfxGPlxo+XPwzzFwmBAm9Gq2
// SIG // G/dnQyVrcM6cga6eIHx5YGNVBKXOJeABhC639ieMK8U8
// SIG // 01vkjPF4VdXTjj62Iw9PNCG2ai/AfiBdEQnZ9uvWF6xi
// SIG // ukCB4qc5ymXAkvIzd9GAB50yVTeWc7Orf9mLKgRg6rrw
// SIG // 2ne/d+BRU8M71HDt1aCMnfd11sLz/P0ghVSYdtVvKBkE
// SIG // 6bRh8pcvhZeIXp1TFWRdb+qLDrYq1/BhU4hIZ3/J0XTo
// SIG // O8mWACdMcvQrQ3212k5/3H9y6tzfxgmChYwvuZlAhPgC
// SIG // YZsTLjHb0lBpiogBXYjwI1E6rFlgQWSZtHgsIHhiRZpk
// SIG // APle//fASnBPoFC+zvXlkQ0MCngHL6Oq8Tb9mOIyqxwO
// SIG // mf8It2v3ylISwjWREvKhna6QwJu6ofuhY2McrQG5IijO
// SIG // rkzcv1Cz5cLZWGaACQw0D+3mAssMFWzU2x10QUkvjXHA
// SIG // tLEgeFu1Ou8CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBTZ
// SIG // O9rBg5R9K+Q8L3xkeV8CSPAe2zAfBgNVHSMEGDAWgBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
// SIG // UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
// SIG // UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
// SIG // MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
// SIG // bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
// SIG // HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
// SIG // MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
// SIG // AgEAZW7tyKMp5z89CtYj23jZ7Ho9m9eZebHZdhQBQQRk
// SIG // /ZUXXNoDVfCwCLrD2Bx4VL0Q3LMeJWzDYVSjxruEwy2q
// SIG // jbfwiPkhbRrqnUS6VT9VxPXAi8iqyj6XCRSQqj6Vfnn6
// SIG // ALWAZiFEHMccE+1iEO4GoPPq5Cr6zJAqEaiktJir/Cdb
// SIG // Cn4vOfhtroWf9UbXklXWGTmTo/km+MM6J0wk4+xLYDDf
// SIG // wV9+VuXU83e8CXRnqWJFYvO9XUqwtk69WRcwEe0uOHaw
// SIG // lmaSeqYSWm1TTrDcRSSoEspLoDhls0N9fEa9zEz4NrNw
// SIG // Z7PqVD1YDIo3eG1Dh9gZRLCzDMDnKJU02aoNR2K3WNY8
// SIG // aVACPYqYwUESDS/zu9OWfv39i4zZiUKKAlSVV9uGnaWe
// SIG // dfUrH2sxqKlxrfdW5qiqNHyNPSJeLFB4eIoeq6YkAwZc
// SIG // i+75rwno8FcWHr2OKlcE2f6N4L5fkdJRcWEvX3iDODXh
// SIG // tPlrA2e4y3IuTBXrjcKLEGN89ul4NaI9FPbvp3Efbk1P
// SIG // sQZifAbZQnYUNd0TTF+T/pK0WDwd1wqfSZul2jtffeat
// SIG // 9gCGZtZswRiOsh5b4l2hAuU8xojtS17j7V2VNl/d6ECW
// SIG // zKHt7/PuQjyq0GpRlsmLodmt1dacG4/ltBRJhBT6bvEy
// SIG // PqmDtSCEFlEkbxY17YeTm9NoTDIwggdxMIIFWaADAgEC
// SIG // AhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEB
// SIG // CwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
// SIG // aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
// SIG // ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQD
// SIG // EylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
// SIG // b3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5
// SIG // MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
// SIG // EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
// SIG // HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
// SIG // BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
// SIG // MDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
// SIG // AgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
// SIG // yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64
// SIG // NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1
// SIG // hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmv
// SIG // Haus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoP
// SIG // z130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1w
// SIG // jjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56
// SIG // KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7
// SIG // vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2l
// SIG // IH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUD
// SIG // o9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhz
// SIG // PUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtco
// SIG // dgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGU
// SIG // lNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsl
// SIG // uq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W2
// SIG // 9R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZ
// SIG // MBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
// SIG // BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQW
// SIG // BBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBT
// SIG // MFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNo
// SIG // dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0Rv
// SIG // Y3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYB
// SIG // BQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEw
// SIG // CwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYD
// SIG // VR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYD
// SIG // VR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3Nv
// SIG // ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2Vy
// SIG // QXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4w
// SIG // TDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3Nv
// SIG // ZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAx
// SIG // MC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1V
// SIG // ffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9
// SIG // MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
// SIG // ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pv
// SIG // vinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbz
// SIG // aN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3
// SIG // +SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsId
// SIG // w2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5m
// SIG // O0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ
// SIG // /gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9
// SIG // swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu
// SIG // +yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyh
// SIG // YWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFR
// SIG // hLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0
// SIG // +CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAx
// SIG // M328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQ
// SIG // wXEGahC0HVUzWLOhcGbyoYIDUDCCAjgCAQEwgfmhgdGk
// SIG // gc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
// SIG // HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
// SIG // BgNVBAsTHm5TaGllbGQgVFNTIEVTTjozNzAzLTA1RTAt
// SIG // RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
// SIG // bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUASyDINT+7
// SIG // Dbgl6Zmx9iF09rV3hBCggYMwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIF
// SIG // AO3wh5wwIhgPMjAyNjA3MDIwNjQ1NDhaGA8yMDI2MDcw
// SIG // MzA2NDU0OFowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA
// SIG // 7fCHnAIBADAKAgEAAgIqQwIB/zAHAgEAAgISsTAKAgUA
// SIG // 7fHZHAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
// SIG // AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0G
// SIG // CSqGSIb3DQEBCwUAA4IBAQC1nIqTb4WDscVk+BCg6GGI
// SIG // HlfPXk7j3q09ItztW31kZgYBDQGrHeZ10JCP9gEhZ755
// SIG // z7xmKzmLXuKFogFBzo7gAtGsyOj7QtREejEESqVnn14U
// SIG // oGhj2lHxd7X4ttm5pjaT+FM16mQqxdVltBznhENeBYE4
// SIG // mcz4zI24JWgD3w8jJDQJml2oEDtm65MalD7C+AOVlLxf
// SIG // 34JfqaYcn4aYmQiGBpOgkbRTbH+oc+x2pIiE78u7DNYu
// SIG // ESx0+IUOD9VXBU1OqRH30YS3k9LK2D3WW6eEhsuefS2Z
// SIG // o888vSbm1z7vnQCM9LY3nO2ZyM6XDw1Y9XKbi+jJ4eCq
// SIG // hIkNCm8XYigAMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTACEzMAAAIfOnBp5KIwLpUA
// SIG // AQAAAh8wDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3
// SIG // DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
// SIG // IgQgRyomRbMWamHO8FYr60d1eG6Rb7mUvha6q/423zeb
// SIG // qY0wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCCw
// SIG // JArfVpArDLVEZBbuk2ND91F3UZwomLj2YXt8pC38FDCB
// SIG // mDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
// SIG // YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
// SIG // VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
// SIG // BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
// SIG // AhMzAAACHzpwaeSiMC6VAAEAAAIfMCIEIInRAOF17RJ9
// SIG // Y+DziAiHw/rkUGxltuRn9dx1alyG7gK5MA0GCSqGSIb3
// SIG // DQEBCwUABIICADqoWxf5Eo/EB0FGuv0bbKQjLXi2+MIp
// SIG // HxdYbNCrkmQX7JuyQFOnzodxUuPcR4e14oqs9/6O4x8W
// SIG // +3Kw3Ic+7pcN8La6IoT4/2Gt0H3D6kzzf9MH7XYcqE00
// SIG // Wx+AVlLP+ZILkE9Do1AdmoL7eFOMi9bhwnNzENSGvD4+
// SIG // ksfjaqBFQhmP8OuMmHzQPD+AoWuHJZUaSdl8gmpi+TnV
// SIG // RSZBNBVS81SfO1iyLS3FCicNbqrUBBXGLam96nAVc2CX
// SIG // VROXDU8Fa51iIhSi1sOOlAVLV28HK5FgG7z6mzw78AQL
// SIG // pQrWFAOPFtbH4MCCgLy2m/7KXrxQh93nsB8e4drW64LT
// SIG // yn/Wpny/dkPSx7S88Ray6ASA1sCxbVpTnTRS5s982bGw
// SIG // aE8oTv2o7LzZxiWbcSyQm7Hig2ajgDCaPJaTghfgv8WY
// SIG // OizNuWYIRcj+550luOkD9yV7INQlbs3KVg+bcF4GtGm6
// SIG // Od0KkDvXKrZL2lOy2Vr6TIdGmraWhi+rpB64ezO4zAPP
// SIG // v2Wu1zDu5FpK922wE4r9h1nBT2dSqyfHDZHlWDSQrNCU
// SIG // TdQUWkzgtNIqzDz97vx1e55pvNNRc5ayPnQpaZSjRCYp
// SIG // +ytF80OibUDo8DVuTby4LJxYIA086eOVovL/Ji6GrBuB
// SIG // pea93BJaPdZcBTEPzEVaXSO1IE4XEL3Q7oQy
// SIG // End signature block
