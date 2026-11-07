var addInContainer = 'controlAddIn';

var FlowIntegrationAddIn = function () {
  var flowSdk,
    hostName,
    accessToken,
    locale,

    resetContainer = function () {
      document.getElementById(addInContainer).innerHTML = '';
    },

    notifyError = function (error, description) {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ErrorOccurred', [error, description]);
    },

    initialize = function (flowHostName, flowLocale, flowServiceToken) {
      hostName = flowHostName;
      locale = flowLocale;
      accessToken = flowServiceToken;

      try {
        flowSdk = new MsFlowSdk(
          {
            hostName: hostName,
            locale: locale
          });
      } catch (e) {
        notifyError(e.name, e.message);
      }
    },

    loadFlows = function (flowEnvironmentId) {
      resetContainer();

      var widgetOptions = {
        enableOnBehalfOfTokens: true,
        container: addInContainer,
        environmentId: flowEnvironmentId
      };

      try {
        var widget = flowSdk.renderWidget('flows', widgetOptions);
        widget.iframe.style.width = '100%';
        widget.iframe.style.height = '100%';
        widget.iframe.style.border = 'none';

        widget.callbacks.GET_ACCESS_TOKEN = function (requestParam, widgetDoneCallback) {
          widgetDoneCallback(
            null,
            {
              token: accessToken
            });

        };
      } catch (e) {
        notifyError(e.name, e.message);
      }
    },

    loadTemplates = function (flowEnvironmentId, searchTerm, pageSize, destination) {
      resetContainer();

      var widgetOptions = {
        enableOnBehalfOfTokens: true,
        container: addInContainer,
        environmentId: flowEnvironmentId,
        templatesSettings: {
          searchTerm: searchTerm,
          pageSize: pageSize,
          destination: destination,
          isManualFilter: true
        }
      };

      try {
        var widget = flowSdk.renderWidget('templates', widgetOptions);
        widget.iframe.style.width = '100%';
        widget.iframe.style.height = '100%';
        widget.iframe.style.border = 'none';

        widget.callbacks.GET_ACCESS_TOKEN = function (requestParam, widgetDoneCallback) {
          widgetDoneCallback(null,
            {
              token: accessToken
            });
        };
      } catch (e) {
        notifyError(e.name, e.message);
      }
    };

  return {
    initialize: initialize,
    loadFlows: loadFlows,
    loadTemplates: loadTemplates,
    notifyError: notifyError
  };

}();

function Initialize(flowHostName, locale, flowServiceToken) {
  try {
    if (typeof flowHostName !== 'string' || !flowHostName) throw 'Invalid Flow hostName.';
    if (typeof locale !== 'string') throw 'Invalid locale.';
    if (typeof flowServiceToken !== 'string' || !flowServiceToken) throw 'Invalid Flow Service Token.';
  } catch (e) {
    FlowIntegrationAddIn.notifyError(e.name, e.message);
  }

  FlowIntegrationAddIn.initialize(flowHostName, locale, flowServiceToken);
}

function LoadFlows(environmentId) {
  try {
    if (typeof environmentId !== 'string' || !environmentId) throw 'Invalid Environment Id.';
  } catch (e) {
    FlowIntegrationAddIn.notifyError(e.name, e.message);
  }
  FlowIntegrationAddIn.loadFlows(environmentId);
}

function LoadTemplates(environmentId, searchTerm, pageSize, destination) {
  try {
    if (typeof environmentId !== 'string' || !environmentId) throw 'Invalid Environment Id.';
    if (typeof searchTerm !== 'string') throw 'Invalid Search Term';
  } catch (e) {
    FlowIntegrationAddIn.notifyError(e.name, e.message);
  }

  if (typeof pageSize !== 'string' || !pageSize) pageSize = '8';
  if (typeof destination !== 'string' || !destination) destination = 'new';

  var escapedSearchTerm = encodeURIComponent(searchTerm);

  FlowIntegrationAddIn.loadTemplates(environmentId, escapedSearchTerm, pageSize, destination);
}

// SIG // Begin signature block
// SIG // MIInbwYJKoZIhvcNAQcCoIInYDCCJ1wCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // 6yctMDJrw/1weoqRCXyff6D00FnLlUrws4wJ3X6fuACg
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
// SIG // BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCA+9mTDDOC1
// SIG // qdcG5TFjGY9yIprRKO3WFaJrmrJgOrbiPDBCBgorBgEE
// SIG // AYI3AgEMMTQwMqAUgBIATQBpAGMAcgBvAHMAbwBmAHSh
// SIG // GoAYaHR0cDovL3d3dy5taWNyb3NvZnQuY29tMA0GCSqG
// SIG // SIb3DQEBAQUABIIBAJ+CEIMdT45X2MxH24AZbnK9pkL1
// SIG // /5OFg7UaHEOMYkyWjQ6QKh9YCBCMge1oG4heTp4J3/ym
// SIG // DXsMQRvopOM4ZVe/LncAGtiw9Fis3/qWzzqQS1lW0HQp
// SIG // RH7/7KfgDBsCt6XRKI1ll8LASUJUtsG2u8QcLjF2rg2q
// SIG // rtAJiEJtp0KjsR9FdVS4H6u3gc5uU5ehxI9jj8hUESow
// SIG // aRg4Z1cyagSocfmk968HZfr1qMJiGF0LRTiuWuqOhgAX
// SIG // eheFgV+aqTOG/LrYREG8/MPsCbiR5UOPRK6wrIwsyCPy
// SIG // ePPDsCCEkmt+RHWwsS1of4JyaXQZa6+Kre1ZTLhq4W0t
// SIG // J78rtZehghewMIIXrAYKKwYBBAGCNwMDATGCF5wwgheY
// SIG // BgkqhkiG9w0BBwKggheJMIIXhQIBAzEPMA0GCWCGSAFl
// SIG // AwQCAQUAMIIBWgYLKoZIhvcNAQkQAQSgggFJBIIBRTCC
// SIG // AUECAQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEF
// SIG // AAQg2ZuuLVJRW17d3vTJwEPsXWWFa9JqkGXJi/RklXV6
// SIG // yRACBmqvJfsyfRgTMjAyNjEwMDMyMDAwNDEuMDc4WjAE
// SIG // gAIB9KCB2aSB1jCB0zELMAkGA1UEBhMCVVMxEzARBgNV
// SIG // BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
// SIG // HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEt
// SIG // MCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0
// SIG // aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRT
// SIG // UyBFU046NTUxQS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1p
// SIG // Y3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghH+MIIH
// SIG // KDCCBRCgAwIBAgITMwAAAhvQsrgCZ/dyzwABAAACGzAN
// SIG // BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMDAeFw0yNTA4MTQxODQ4MzBaFw0yNjExMTMx
// SIG // ODQ4MzBaMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
// SIG // V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
// SIG // A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYD
// SIG // VQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25z
// SIG // IExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
// SIG // Tjo1NTFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZI
// SIG // hvcNAQEBBQADggIPADCCAgoCggIBAI7FnedmWZMweV3u
// SIG // YP5dhrDowM99LIOo1cXxSVfsOMSA1cmiNyzvGyKZs2Lp
// SIG // dwGR4OdFCEPD60kWRqUKhZETbvqN2CieINrhmAUZLB5x
// SIG // 2EdLlUgkIOfE4ZGMnqZRl96ALxkVbjyKULQIk7Ee+gP4
// SIG // HaFOxw8BG2+92ycE8q2yh4UflmjMvQ0ByOJOUKOPm2Q7
// SIG // NJI++m74Sb3RlPkvM8UAae1AIYyZxaisSLrEiExO8wgk
// SIG // eNthC4ZIVVThaitsOodTALyC3u+ocUSHD49EgS9q/Dvb
// SIG // ceZ41OPrYNqwHVNed6Zsoams3aVHHGARPcA0RVHf3vQq
// SIG // Fse03Z1InAfjGou0U+qrHu3uWhql9Qe254/2R7663xfg
// SIG // SRCJUvYg1wFIHpL12fhWZo7y8D/nTftP3K4fvq+HvBZJ
// SIG // xexF+iCX55jXgzf+vGefZG2idX/j+ZpymH8nQnmZsaxq
// SIG // UtLWlpA5N+g94z1WX5b8a3Pta4QiJTOb/WoCxBSNdkIg
// SIG // U36TgTga9wBgj5Pnh9PpWrY0Go7oPtvwQ9dqm/NudNC0
// SIG // MrVFk9qLWvx2J0YEr9Y72dP3ZpdRbMVmMzpwq433Qf+z
// SIG // eqTckreL5/jxjenRS4pu5MaLPgfVn0D3syYt37issgwA
// SIG // fc0hz49WbvJ2X3nGSfbpuM4+wxYLyV0w05xuapRuGXWx
// SIG // UWv66385AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUtr6f
// SIG // d/5cS6aTSvDpGridgLzZiFAwHwYDVR0jBBgwFoAUn6cV
// SIG // XQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
// SIG // UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
// SIG // cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBD
// SIG // QSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
// SIG // BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
// SIG // Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
// SIG // LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0T
// SIG // AQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
// SIG // BgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIB
// SIG // AGZFNV8UA+DkzNxk4bd9k10oSHzwaDH0rBbAUKhTmaiy
// SIG // TsciTpZSARaZqbzrRjT5AuWfJXRvGgqb4BTaP4w1nk+R
// SIG // Ylud3QI/Sp2cabENz3+X0c0hh0XMRDDnVyFcwycHGVF9
// SIG // HI38Z2u8nTb/Hlwf15Ohuksq0djh+ktSxzFtdZt1Lyhf
// SIG // ni4yD5eOa8YprgwqBHfmndJTgFwOf72TijeZ/3j2Hj9C
// SIG // 0XIWV9EOh/J/2ZkjzJW5YtzDvOdUNPUZk/2Rh2vvxXcv
// SIG // liw68HGMpFfZlMv+E28CsOhbXUemTx8THSItaZPGNpgv
// SIG // xswqtCwrB9LkxXkOkOzXNzEZhEf95i1lIW2lh4F9RW2H
// SIG // Ib0dtm/gbqfmD0eUP9AYWmgDegCAX3BrPrv5yaCAcsmS
// SIG // gPHE8gpp1CP+L1ug+L8sIN1wRX+H9g8BR8v3r7AvufCj
// SIG // JfpNsGtOV9pCtE/2wjy4WqL/WV8qG2sHzTi2Bomrik9h
// SIG // Vr28GcxyBQk8YwcMOj7ebkbwhP451HH/8YZThjJ+oijv
// SIG // V7ePb2UxNknyAZP9+Ii00QSeh+2hj000J82tzn1rtf3U
// SIG // cnAulpeaJ7Nz45xl00iksV5ZST5oOkf7pRqJz/1AmKCe
// SIG // pjfhF438gyz1y6rK/dflUxta2M0Qoz8ARQB7+BCMGhNG
// SIG // owq3++XlBiN/qF1NFD+q5aGfMIIHcTCCBVmgAwIBAgIT
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
// SIG // dGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NTUx
// SIG // QS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
// SIG // aW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
// SIG // AIaFeq+PTOBgXeNStUWAdWdH+M7goIGDMIGApH4wfDEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcN
// SIG // AQELBQACBQDua28pMCIYDzIwMjYxMDAzMTIxMDE3WhgP
// SIG // MjAyNjEwMDQxMjEwMTdaMHcwPQYKKwYBBAGEWQoEATEv
// SIG // MC0wCgIFAO5rbykCAQAwCgIBAAICEOcCAf8wBwIBAAIC
// SIG // EtgwCgIFAO5swKkCAQAwNgYKKwYBBAGEWQoEAjEoMCYw
// SIG // DAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQAC
// SIG // AwGGoDANBgkqhkiG9w0BAQsFAAOCAQEARyino4X47QY5
// SIG // WDTOoPLtLRGB0+cNPK8rnapaOzBRD3Ypf7w0Xrn4xUgJ
// SIG // bhivp5EaORhyxYq+nG2lLKiENDIen5jSbf2e5JIkuv/M
// SIG // HzeSYP7nmsY5wda/r5ROihl5QiBc+Z5NcoKD007Z3iL2
// SIG // 5caig9Ln+LKm6p55PVXXilmOTIUYPw+widU1xrxthejO
// SIG // jaRBGTup5rOijDPcNYL8drJhcUPfIkcQwZzPL8OJLeXn
// SIG // npFueptUgVAkolPt4qYhr0VKDZW1t/EhXtLHvi+hA0Cq
// SIG // zwR5VuPJ9sDBT+ti/QzDyqSU9LRrGqRoFJt9KrSqlVq1
// SIG // Hd/QCrLMoPnCII4OmkQwijGCBA0wggQJAgEBMIGTMHwx
// SIG // CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
// SIG // MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
// SIG // b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
// SIG // c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAACG9Cy
// SIG // uAJn93LPAAEAAAIbMA0GCWCGSAFlAwQCAQUAoIIBSjAa
// SIG // BgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZI
// SIG // hvcNAQkEMSIEIO8JvL8Nw90EQGr09LqBK58sIt81QJt2
// SIG // DDhSItazJA9VMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB
// SIG // 5DCBvQQgMCUUlbg9o5jHEAhV3S7iQMA6VFTWem3OnXyV
// SIG // PN0Ni4AwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMAITMwAAAhvQsrgCZ/dyzwABAAACGzAiBCCA
// SIG // xU1De/RSmYRI0cpz2cg0rcC3zuRI1NsRTD5EteGURDAN
// SIG // BgkqhkiG9w0BAQsFAASCAgBDqo2ER8liPZGTp6az+TGP
// SIG // H6ueU/K/nin5zFTRue8GikkIva5f1uSJuzHnWvmmzsKP
// SIG // bDjAnftx8m22DdLYwwmVFTaHFrd6xMmFR3DzQjECes6e
// SIG // y+FRZSkUH7+ADqclYbyWMFKuTElhXTgAVCC2pegFzMuJ
// SIG // ddcRtJTxPYrHmrYN3WDiHhEc6FG4ba042o4WLwrL0RSw
// SIG // htu3F0ehfAfEay27LdQnxQEhvGXb3vV2/Hl7CpKZ6hhj
// SIG // ecc826jyqcQj3S+fMPsf4ZeweltQJoCiSrwb3sA+vu1v
// SIG // DNzDOMBQVUL8o6pm3eyVTvKOajUba/i0vS/tOvVAmiV6
// SIG // 4x5+Hl/Og+5sSwwPMnJSzaUGHpxqTfxF8oppQOmbI5sw
// SIG // mQZCMG/j6Jdau8bcmjLNHpLedXEEileJyY1I8WwQgHS0
// SIG // PVkaX0pa2FSXbW+qF5lctYwqhXiFww4ajEN4vMOLZINa
// SIG // AE/vb68OACR4iiIHyJ47fzqcZHs7oRMQcB9AuSY4IfrG
// SIG // hjNk7qhRKDpqwpWD9HDBcIHPpWIQQmiOTYWZ/uaMGLeX
// SIG // OLP8j/tKgG7gczSNtF5tc1EE/3RRSr92WPArkVuvTEhy
// SIG // J44jmw5oKSl56TgL/1R96GtK0d1yj8UbU8bAJyQWNUjX
// SIG // UpA+A796avoxOWpGjb93ml1VicWNckhoOQJjFxPPlFJJzQ==
// SIG // End signature block
