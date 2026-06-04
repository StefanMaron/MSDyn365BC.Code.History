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
// SIG // MIInRAYJKoZIhvcNAQcCoIInNTCCJzECAQExDzANBglg
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
// SIG // JkDeVuJ9dNXGNi+AOxk0BtYd9hxwL30BElj9MYIZ4jCC
// SIG // Gd4CAQEwbjBXMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
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
// SIG // 7N/6vvXlMLoU894IyLtSBadku/bYh2ahgheUMIIXkAYK
// SIG // KwYBBAGCNwMDATGCF4Awghd8BgkqhkiG9w0BBwKgghdt
// SIG // MIIXaQIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQgO5QFa1RJh0EbgqS4
// SIG // 9rVXIjj+eotGJYrakCxv/1JE3yICBmnnoGvb9xgTMjAy
// SIG // NjA1MDExNzA1MzIuMTc1WjAEgAIB9KCB0aSBzjCByzEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
// SIG // b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
// SIG // blNoaWVsZCBUU1MgRVNOOjdGMDAtMDVFMC1EOTQ3MSUw
// SIG // IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
// SIG // aWNloIIR6jCCByAwggUIoAMCAQICEzMAAAIeo6ykbjlv
// SIG // fEkAAQAAAh4wDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTkzOTQ5
// SIG // WhcNMjcwNTE3MTkzOTQ5WjCByzELMAkGA1UEBhMCVVMx
// SIG // EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
// SIG // ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
// SIG // dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
// SIG // T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
// SIG // RVNOOjdGMDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNy
// SIG // b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEApdE47Ww8LEex
// SIG // XvGnOqJebNc4bU6ndgFqXIUIS6fRuZpkjNtzeX8kBgkN
// SIG // Q9OqzgNz4Fyhfu+r17zgrNlbC79aMI+JhxMhKoqvBiec
// SIG // gvv0DWEaWTwPHuzoHpMwzukv+L8v40zGG6d64bhYiigs
// SIG // 01jkLXRXBfg9JN+vSO6ZvxNO0sjTBpLjXeZY+UifdVKh
// SIG // bmX4zAenENsIe+5rYkVFXY+d8o3Tao/hkJfmGs9vQY68
// SIG // 5+1NZZ/iaS5Z29MXRpmaCDymW8AVXFrci+LsoTC+0kk5
// SIG // ojn1l1PoPsjZdAnaCxi/C7VhxIvBbLkz3knUqpnjK7y2
// SIG // hJom01U0uL0EGPDT52+riOcuojVfbwRXJvC1P5Q04xk6
// SIG // j2u1AU+IHX+SZt8GK3whWeD/4+TKKk9CTjXGudI7eExi
// SIG // PdEooV2gxGKpNt0tCCWd1JFKbpA0U4yu9dwSMpH38cga
// SIG // jHkKnztM71n1Mewa5lKboEHMPffg8S5doH/rkBKUZp5W
// SIG // 61SfXb1vXbOH6hDzdoxtEMBdTwUoJTXFdUqamSorUIAR
// SIG // ksLv/NgCs7aAh8GER0TcM8E1Xv9SjU75qgHeFIHrOMsD
// SIG // h9NoWmoE/MGGPDnVnYyp95NOdsPpJnNFAtBfolV0xmSD
// SIG // Mb6PYgWUKF3oc0bVif1TrSrwskt3LCsze60rVicI0ls+
// SIG // nbTn9JfsrS0CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBTm
// SIG // Chaa6gQdCWZiXBQuHDz5nheCZDAfBgNVHSMEGDAWgBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
// SIG // UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
// SIG // UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
// SIG // MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
// SIG // bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
// SIG // HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
// SIG // MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
// SIG // AgEApKGQeTZyVRW+cCno0aJ5OdfGtkwTWKSnATLXy+gU
// SIG // tAEWgATjBmC5TzboSNR8JnpT/YV96Kt02hJv3A5JMzUA
// SIG // Mw3nT4KESNke/vKaDUlrx1xALO0mTg5vceyqpQZDWTPX
// SIG // seF2NcjZlTgJlg40a+4yo2okG57X+xAuBjYpMRhmlVjo
// SIG // 32Ld0PV9K/yrPCgZW8w0fc4wP0wnLUeHKNVqVNWUSxaw
// SIG // fW5fHUcbG58k9qkONRO3U9dkd9HiBlM4hLORjftulf6L
// SIG // 1zottHSYjNd4WFr8tTTSQIZCjpSwdTjbp3en34T3VHB1
// SIG // rLvFfpUdGmpDFeuB6g2y7pmawjcFKH1cd8TJPBeLQmCb
// SIG // UMS08sHN9LGQA9UtrAtfefceiosQPqeNRS1JfIOuKB8t
// SIG // 232Jx+cXeCTgYEKGqp3Ro3HLca/vBJJ44Ssq4AM603Ci
// SIG // yW1Hs4KMnvG6wiyfsujwKBI6V0ZEmAFPMH0N2FkXJOgC
// SIG // 8KFe1Ip/Pq6RkEm14RenNXUxWpF5goQpbneCAA2P7eiU
// SIG // ZCftOhcy/ow3fCi1fEI++yX4rk4jyBuRv8ZZxqGRXF/s
// SIG // sgbQ782ROPHfmPh2FHf3L4R9RSpewB/uQMqLaiUhZrzP
// SIG // wbmEcdgdtGrFV4pVdpNiWzTtyxgs90PnaRJc8LHya5Gt
// SIG // Tf4HrZmu31qaMLDb6CGhEL42nfEwggdxMIIFWaADAgEC
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
// SIG // wXEGahC0HVUzWLOhcGbyoYIDTTCCAjUCAQEwgfmhgdGk
// SIG // gc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
// SIG // HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
// SIG // BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3RjAwLTA1RTAt
// SIG // RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
// SIG // bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAg/0DZCgy
// SIG // FuFSBe496Itqm60dGv+ggYMwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIF
// SIG // AO2fTEwwIhgPMjAyNjA1MDExNTU5MDhaGA8yMDI2MDUw
// SIG // MjE1NTkwOFowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA
// SIG // 7Z9MTAIBADAHAgEAAgIC/jAHAgEAAgIThTAKAgUA7aCd
// SIG // zAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZ
// SIG // CgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqG
// SIG // SIb3DQEBCwUAA4IBAQBT3kQJHfBLETLJx0LwHKqxcIqn
// SIG // F3mpJjC0OcgD5FgSyDBw6WSsL8AtlyeaEcRuLFtpxR1D
// SIG // z/PAJ+YwneOwxeyR8BeOuYCh604GpmhB+qiOfRBmua/m
// SIG // x+oRPWOij+QJsPNqQQnV/UWpYivUZAJ2YJK6NM2mc8XT
// SIG // FNKMyB0Nt8/krXsLC3ZXVfP9gKFf/xNteAL1cu4uUj3B
// SIG // iPjQWftX4b8OR55QJekOSzZOSm57bHlOGCL6UdPVoqO1
// SIG // OE/P0CvKwmVNaTWQThHiIon1O/QfWDnEl/63hO92Vt2h
// SIG // iXs3IB3FY6jNb5m0aMt77KEQKI0JyTq0JDt54hs0wLHK
// SIG // 6rN4TzVDMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTACEzMAAAIeo6ykbjlvfEkAAQAA
// SIG // Ah4wDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
// SIG // AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
// SIG // 9v3ApxooXm6LVXgVpsPGoS73rKPIz6c0Nvxb2lfMK0ww
// SIG // gfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAvgV1q
// SIG // 8/YHjIDPAb5/G6sR44R1ydvRAYsyEyMNAfbzgjCBmDCB
// SIG // gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
// SIG // HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
// SIG // AAACHqOspG45b3xJAAEAAAIeMCIEIDuC9ZEXshzjmH6G
// SIG // 1Wu8WVoDkUMSYbAnWUVEjwwmuzyLMA0GCSqGSIb3DQEB
// SIG // CwUABIICAFEwhGxn1pL10xkb6nfa+vF8eiwbijYHcsJP
// SIG // ZPrKatKAANMYn64YAg2TC9i8hm7TTSAeub9z6l2mSgQf
// SIG // iju/K/QxDmtin7rdtGcFZZsZHY+b7g0x/RrphPyQlLwl
// SIG // fy9aW7cpMhmb1EsKi4HacmQfZCIpdlXzsFk5Hgj+nxGv
// SIG // 4/HWrgTnmVDtNao4GwhvTrXKjPRD0gWBI6wmRxydzMY7
// SIG // l65/np47195fP27RL53BbzoJu5gmQovc6izfyTtBhxEG
// SIG // BUrFbQWeW0yR3uKs4OaPzKGJzT38WKV9iSTVV7wMtDuL
// SIG // /hu6HKWBJ3FdHSdqbaDr9F42fyobjDwsIvbKnmHXUEQp
// SIG // ewGTT+nCdwWtD4rL3kO6NOkG4SxMPMxVJoA7yhdZHjzl
// SIG // Yee+2Ck/KHk7fvDIJIEOa3EefNVYqTJ4V7bBZXGR4fnY
// SIG // TR6w59rmbFy1Mk0vdOaK9c4XnJGuAbASY30lUDUXCwEm
// SIG // BDpDsN6hV1noVTNkJNO1hRyUcF3X7Lw4cx0NwOgXyG2C
// SIG // uCIiSX8oZFY9PzVyqvhjhi9AY60GatCzXFKKhKhc0JlF
// SIG // MSmfhCaerDzW4tuEOwREnKgfpuVY53ajeJ4CsOGmx8kf
// SIG // Q2x2hnzJsgSzn+yxcrT35kWrI1s+q8T8ibMwd4Ckk6O6
// SIG // X8GBADTOBPsHG6B7DY+RySIU3pgHsDvV
// SIG // End signature block
