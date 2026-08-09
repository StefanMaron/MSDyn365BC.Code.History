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
// SIG // MIInRAYJKoZIhvcNAQcCoIInNTCCJzECAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // 6yctMDJrw/1weoqRCXyff6D00FnLlUrws4wJ3X6fuACg
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
// SIG // SIb3DQEJBDEiBCA+9mTDDOC1qdcG5TFjGY9yIprRKO3W
// SIG // FaJrmrJgOrbiPDBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBALHp
// SIG // OeIJUxr8+41lCC5XReAgvI1AP07+0XOSlzAKkVRHPTAo
// SIG // SqajKLojexXGXXkGZaP8ScfjmgDq126QTFEQum9Im4cq
// SIG // pjHmtPgON8mMohhVnQx+YuSIyeoMKYSUPbmxob26WlmV
// SIG // o9CUBtWkwcZjUQaUuJ6eN0HzN+eSeDfGXGBIzaca0asI
// SIG // CS5vpgg7TqK4nTf61qOCUSnvD5fzAkEqmLGXmfVD/Gl/
// SIG // ynhlUHDu3BTFsv5O0we1jL+0pJmWIj4hZScFvkZzYPpM
// SIG // S3fKHol84kua7a+NDrtjm333gj2sBEziSJcifAE2OJSF
// SIG // D0Z4EDZMGtjj1wc6eQYCJf6sWePP90OhgheUMIIXkAYK
// SIG // KwYBBAGCNwMDATGCF4Awghd8BgkqhkiG9w0BBwKgghdt
// SIG // MIIXaQIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQg0dPERDbp57TrcdiS
// SIG // QvfMQY+oxH8i5++CI4rMOyP5nu4CBmoxNtoj2xgTMjAy
// SIG // NjA3MDIxNzM3MjAuMDAzWjAEgAIB9KCB0aSBzjCByzEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
// SIG // b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
// SIG // blNoaWVsZCBUU1MgRVNOOkE0MDAtMDVFMC1EOTQ3MSUw
// SIG // IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
// SIG // aWNloIIR6jCCByAwggUIoAMCAQICEzMAAAIo8KWH1/PI
// SIG // HkAAAQAAAigwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTk0MDA2
// SIG // WhcNMjcwNTE3MTk0MDA2WjCByzELMAkGA1UEBhMCVVMx
// SIG // EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
// SIG // ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
// SIG // dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
// SIG // T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
// SIG // RVNOOkE0MDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNy
// SIG // b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAro725P7KnAkk
// SIG // XmWiXwrn9TcEXHO15J4ROsJC6H5DY9ZsRAIN+astsXBY
// SIG // 4I2q7VbwNPVvEB3KcjKlUlzk8TRybJpNKj9ggy71ALpV
// SIG // oO2kuaATkaRF9aM959Edpz6nh9CBytcycY8Wh1ttQG7m
// SIG // dGfsDN1mDc5AZXB5lXtN2Ru65ZNvIe9q+T+TBPBRqRZm
// SIG // FuR5e6bCm4CxH62AIrabbbG/rGbAVCPoTCpeLiyWKLSs
// SIG // mb9XsDiIpwX0VPEKLIr46H2gXs1H/TXVfohq1od9tVp0
// SIG // rCtwPyZehi7W0ll3CVlC4G8bqp6GzyvmJQd9e+EzFk4F
// SIG // +GFoxu6NDrc/6YxzQigWwe/PHcp4S3RmOgdPBPfuEhq0
// SIG // abLcuIiRzsnRwgOTOIucmEcLHbrfoJr8SKU/MjVyXIyQ
// SIG // oNLzvJr/5xWPVsrb9qpgrQhRYrxlFqlNtP7FHkaKEGRo
// SIG // kDiUJ9PeQo94rCLL0T/ClO4TfxAyPB1bG/zT8zBS70c5
// SIG // 60Z49Ezpw4jk1HJ2MJpPl36EtaMLJHAggsB52wtNA+fM
// SIG // /N8uyuWSQe+OYXJ+AhNp0d3ukRrK+NsuarbejHc/7OzE
// SIG // 5w0tlJlR1l9V/x2Xt1JV/II/7ety+dMSD6pEQgRHTNQA
// SIG // zVGkn6PTkIim/249XYmQhk3xA1AQS6KdZoZMCBfNn2qZ
// SIG // Vdm7rGflOJECAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSq
// SIG // yaWM+PLc6Lr1ZAVbYQEhaUPdwzAfBgNVHSMEGDAWgBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
// SIG // UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
// SIG // UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
// SIG // MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
// SIG // bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
// SIG // HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
// SIG // MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
// SIG // AgEAkOjXy5q0WoYFbYFoN/NxmktO3x8qHem4XFDjbdrX
// SIG // rfugWjbh9K+wAZFR4XjqcQXa1KzhGFRGiIovXSt3LmSz
// SIG // ZqdYlAMf1W5jmWJe8c/rTa4wlqq4NY0JqtKEQfIhOECa
// SIG // cDYRj+u6GOYbmCFNA+JYQ6Goan4CiZ/9AZPvVCgz8OV5
// SIG // VGJq3hZiZY/WEM3Dz3qfDMQV8Yf2OSO70HkWluUo7Yi0
// SIG // Di0ZN4IL62g7OUn+PTCVevwcMVwtq71HxBV+klA6KKii
// SIG // BPTYFSEatEWbuzrdItCLPh7zz9IQeisDsTINUlijn07R
// SIG // aVqXaPDCb4Cgh5D6VxM4Kaz/qciB7ju4FUZUk7G2ARS4
// SIG // dsiHf4rTOLmC9EftkkgQU6UkkbYaxrhJhJSOQQhzMczI
// SIG // P6Kh0j8GQCAJDNguMcYtEre6jLgPpvmcxWJH6BeNUKEi
// SIG // Z/h46oalmENJv0jvfypyUSSVMDHeU4jJ42fhPwyYlK8u
// SIG // bnYlskKb349oUBSNHY4WoaAFw2s3hHIixdrhJ07q/VH4
// SIG // 3MDrp/6DGPlC37ZzotoyizK63ldPe2pM8/ycaZw4GCVP
// SIG // 7YFO30H5YOyKoi/ftNu+vo6EB6NtZlXmOWA/Cof5FGmO
// SIG // iZvzkzPPBu3r08/6p0bpsaL04zErb6WwBzUYZkk3SD01
// SIG // d9gsrsQykv1eWuYsAPn/VYgaPsIwggdxMIIFWaADAgEC
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
// SIG // BgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNDAwLTA1RTAt
// SIG // RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
// SIG // bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAda25hZM0
// SIG // u6gCtTmr9PAFJ4WzSFKggYMwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIF
// SIG // AO3wywMwIhgPMjAyNjA3MDIxMTMzMjNaGA8yMDI2MDcw
// SIG // MzExMzMyM1owdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA
// SIG // 7fDLAwIBADAHAgEAAgIH/TAHAgEAAgISXTAKAgUA7fIc
// SIG // gwIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZ
// SIG // CgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqG
// SIG // SIb3DQEBCwUAA4IBAQAJ8ncKo7asvy0aQb399zPc+7Ke
// SIG // sATUEsGkwbqwzLv3dopPGxL9XYjv/C3u1ptKFGDbYnBF
// SIG // B78emfHSt85cT9tW88PZXEguOeOFSB0IOqXc62kuTELF
// SIG // 7MzTnzHoZLaFv9/5omPXDjKQQIFUz0/Int3RtEmZEsC9
// SIG // hr73iNIEJwiOpvO20yrTwp9JyLxKUFaGB0LxV6ANDMpC
// SIG // Y1e/c85fSHARu/rSprkaNFinmiSpVMXqw3gIqwxvUSQ6
// SIG // PCRGOEjKPgQuaVO1Yu9F0mEb7u8aX/aaCylZXQnCKqCl
// SIG // BiJFDBYiBwc0wZZOuTYpTEV0fsMLi5x3u44ZmLe53gjk
// SIG // Kcq88BojMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTACEzMAAAIo8KWH1/PIHkAAAQAA
// SIG // AigwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
// SIG // AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
// SIG // 5AATx1ElxtNesFqmADd1JP1wD1ss+g08ALQzbdgDX3Ew
// SIG // gfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBVsYpG
// SIG // UWBjX+KBFWStXk+OR/txkN/6sVe+VcLgbfoi1zCBmDCB
// SIG // gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
// SIG // HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
// SIG // AAACKPClh9fzyB5AAAEAAAIoMCIEINfBv0TOtHsIz2K+
// SIG // WAnVNz8kwUZEGFSyB+Kx3Fbw8f3DMA0GCSqGSIb3DQEB
// SIG // CwUABIICAE9lasQlv6p19HPT8x22rlAT7FVnIpTJTZmR
// SIG // yGiTW05x3vzuFbz2xwljFYzwOfgr+Wg/5KIPCtww2VIz
// SIG // RYRZRu8aw7dennVCY18d75ITcog52obzUodMai5QCLBL
// SIG // X7rz7And1mhVF5jjUkit20I+IyAYGkVRsdZwXyBj1upT
// SIG // qvvDKgYOwDN1IHX6WYOW+Xl3X8dYcxd73+W9fUrIk17x
// SIG // hsJZFz27klkqf3BckMFwnL97ZVHrK1CQwa8qAb/mZ24I
// SIG // fjz5ke3J7pR1HLsWezgTvfuvyG9GPxlvBlHCMHq+hInG
// SIG // V1tzNRfhYRCzFIljTZAYuBhREX4RL1AC6KVZ1QvVNVFC
// SIG // G6sTM4QW1tksdYLbpouVCBqakuiA0aGR3ph6FP/hRs/2
// SIG // z62aILCsiFiUIERSaI6FT/UMnOhS1e5UNvov6pbl/RUV
// SIG // LPkoxzeUvBDEP8GyROboTq3xLaNLqwHmQKHtf0wEzTfX
// SIG // kNOUWL9R4iX5cooab8eTlXpt5Mh1bA10P6uKb7JH/Z4L
// SIG // NHjhspFG3CiOd7iSjmvzQiFTDWhEeLNL2hfUyROzAcro
// SIG // IKZUQuE006ZKAs1xJSmDCMFHnMwiUg1id6D1yD7/oCn4
// SIG // bMx6lnjCX0Tqi/AIW9jueRKBMpZxMCJ/pTpf5A99jZQ4
// SIG // I5HKCnREmEbP+JKw0aLBDOB85xP8RUKq
// SIG // End signature block
