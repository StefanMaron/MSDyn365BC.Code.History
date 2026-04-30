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
// SIG // MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // 6yctMDJrw/1weoqRCXyff6D00FnLlUrws4wJ3X6fuACg
// SIG // gg12MIIF9DCCA9ygAwIBAgITMwAABIVemewOWS/N1wAA
// SIG // AAAEhTANBgkqhkiG9w0BAQsFADB+MQswCQYDVQQGEwJV
// SIG // UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
// SIG // UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
// SIG // cmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBT
// SIG // aWduaW5nIFBDQSAyMDExMB4XDTI1MDYxOTE4MjEzN1oX
// SIG // DTI2MDYxNzE4MjEzN1owdDELMAkGA1UEBhMCVVMxEzAR
// SIG // BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
// SIG // bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
// SIG // bjEeMBwGA1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
// SIG // wEpIdXKb7lKn26sXpXuywkhxGplTQXxROLmNRZBrAHVB
// SIG // f7546RNXZwA/bzDqsuWTuPSC4T+I4j/z9j5/WqPuUw7S
// SIG // pnEPqWXc2xu7eN8kVyQt5170xkK6KHT4vVEkIvayPtIM
// SIG // Ll0SgSCOy/pN5DJCi5ha7FlI84F1Qi2GumR+wQgCwHCV
// SIG // mU8Fj6Ik+B6akISXGCwe6X3rQFQngRFWQ/IrSkOkAOfy
// SIG // 0EfvV+nZUo+FcbWuCZ6cb4Eq5I1ws/rZSeuwAWeedZcN
// SIG // t0VlNbsn4AnxBYQX4sj0dlko7JD5fWqeqq3/HzUNbBmL
// SIG // p9qeCXV8XlACn9YVWv900F47z04kVwpyTwIDAQABo4IB
// SIG // czCCAW8wHwYDVR0lBBgwFgYKKwYBBAGCN0wIAQYIKwYB
// SIG // BQUHAwMwHQYDVR0OBBYEFLgmchogri2BNGlO4+UxamNO
// SIG // ZJKNMEUGA1UdEQQ+MDykOjA4MR4wHAYDVQQLExVNaWNy
// SIG // b3NvZnQgQ29ycG9yYXRpb24xFjAUBgNVBAUTDTIzMDAx
// SIG // Mis1MDUzNTkwHwYDVR0jBBgwFoAUSG5k5VAF04KqFzc3
// SIG // IrVtqMp1ApUwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDov
// SIG // L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
// SIG // Q29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNybDBhBggr
// SIG // BgEFBQcBAQRVMFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93
// SIG // d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWlj
// SIG // Q29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNydDAMBgNV
// SIG // HRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQAo5qgK
// SIG // dgouLEx2XIvqpLRACrBZORzVRislkdqxRl7He3IIGdOB
// SIG // +VOEldHwC+nzhPXS77eCOxwRy4aRnROVIy8uDcS0xtmw
// SIG // wJHgFZsZndrillRisptWmqw8V379xgjeJkV/j5+HPqct
// SIG // 0v+ipLeXkgwCCLK8ysNyodkltYQsF1/5Nb+G/jR9RY5f
// SIG // ov8TybKVwhbmQeGguRS0+X4G0Sqp7FngHZ/A7K2EIU90
// SIG // Fy7ejb9/3TM7+xvwnaW3XKLpfBWJfrd3ZlzPkiApQt5d
// SIG // mntMDpTa0ONskBMnLj1OTqKi0/OY7Ge/uAmknHxSDZTu
// SIG // 5e2O6/8Wrqh20j0Na96CAvnu9ebNhtwpWWt8vfWmMdpZ
// SIG // 12HtbK3KyMfDQF01YosqV1Z/WRphJHzXHw4qhkMJJpec
// SIG // /Z5t6VogWevWnWgQWwBRI8iRuMtGu+m3pf+LAwlb2mcy
// SIG // zN0xW8VTvQUK42UbWyWW5At1wK6S6mUn8ed0rmHXXcT1
// SIG // /Kb3KhbhLvMHFHg9ObfcTWyeE7XQBAiZRItL7wcZZjOb
// SIG // cxV8tqmXqjzFx0kGKj4GfY70nGejcM5xQ9Pt95G88oTk
// SIG // s/1rhmwLuHB2RvICp5UFU+LgNg4nsfQzLNlh4qJDZJ2J
// SIG // S6FHll1tUKyS6ajvNky8ik2wTP6GRwHSHNJM6Ek66PW9
// SIG // /r459vNPQ9PkjjglWTCCB3owggVioAMCAQICCmEOkNIA
// SIG // AAAAAAMwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYT
// SIG // AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
// SIG // EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
// SIG // cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290
// SIG // IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDExMB4XDTEx
// SIG // MDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
// SIG // A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
// SIG // BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
// SIG // dCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9zb2Z0
// SIG // IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZI
// SIG // hvcNAQEBBQADggIPADCCAgoCggIBAKvw+nIQHC6t2G6q
// SIG // ghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/DDB7dN2vG
// SIG // EtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOlo
// SIG // XtLfm1OyCizDr9mpK656Ca/XllnKYBoF6WZ26DJSJhIv
// SIG // 56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW9Ea64DhkrG5k
// SIG // NXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vj
// SIG // K1oQH01WKKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd
// SIG // 6IlPhBryoS9Z5JA7La4zWMW3Pv4y07MDPbGyr5I4ftKd
// SIG // gCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBS
// SIG // v4yUh7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbs
// SIG // YR9q4ShJnV+I4iVd0yFLPlLEtVc/JAPw0XpbL9Uj43Bd
// SIG // D1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
// SIG // fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xb
// SIG // n6/83bBm4sGXgXvt1u1L50kppxMopqd9Z4DmimJ4X7Iv
// SIG // hNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXUpUMv
// SIG // dJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY
// SIG // 0uDWiIwLAgMBAAGjggHtMIIB6TAQBgkrBgEEAYI3FQEE
// SIG // AwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3IrVtqMp1
// SIG // ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYD
// SIG // VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
// SIG // BBgwFoAUci06AjGQQ7kUBU7h6qfHMdEjiTQwWgYDVR0f
// SIG // BFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQu
// SIG // Y29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0
// SIG // MjAxMV8yMDExXzAzXzIyLmNybDBeBggrBgEFBQcBAQRS
// SIG // MFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9z
// SIG // b2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAx
// SIG // MV8yMDExXzAzXzIyLmNydDCBnwYDVR0gBIGXMIGUMIGR
// SIG // BgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
// SIG // Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9w
// SIG // cmltYXJ5Y3BzLmh0bTBABggrBgEFBQcCAjA0HjIgHQBM
// SIG // AGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABhAHQA
// SIG // ZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEA
// SIG // Z/KGpZjgVHkaLtPYdGcimwuWEeFjkplCln3SeQyQwWVf
// SIG // Liw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1pZddZYSQ
// SIG // fYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XU
// SIG // tR13lDni6WTJRD14eiPzE32mkHSDjfTLJgJGKsKKELuk
// SIG // qQUMm+1o+mgulaAqPyprWEljHwlpblqYluSD9MCP80Yr
// SIG // 3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/D
// SIG // Mhji8MUtzluetEk5CsYKwsatruWy2dsViFFFWDgycSca
// SIG // f7H0J/jeLDogaZiyWYlobm+nt3TDQAUGpgEqKD6CPxNN
// SIG // ZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf
// SIG // 2vP48hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+
// SIG // YWG18NzGGwS+30HHDiju3mUv7Jf2oVyW2ADWoUa9WfOX
// SIG // pQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
// SIG // +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6
// SIG // /IvrC4DqaTuv/DDtBEyO3991bWORPdGdVk5Pv4BXIqF4
// SIG // ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3ZbCoBI
// SIG // a/15n8G9bW1qyVJzEw16UM0xghoNMIIaCQIBATCBlTB+
// SIG // MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
// SIG // bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
// SIG // cm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNy
// SIG // b3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExAhMzAAAE
// SIG // hV6Z7A5ZL83XAAAAAASFMA0GCWCGSAFlAwQCAQUAoIGu
// SIG // MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
// SIG // AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3
// SIG // DQEJBDEiBCA+9mTDDOC1qdcG5TFjGY9yIprRKO3WFaJr
// SIG // mrJgOrbiPDBCBgorBgEEAYI3AgEMMTQwMqAUgBIATQBp
// SIG // AGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5taWNy
// SIG // b3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBALLBaHR2
// SIG // 6wZrLlbVre0+uHIdJgWugXC59AOlpfrs39UjshAPtuWC
// SIG // aU3URBXQsbJgdoz+6cCmGB9ViKPq8F7yPiJC5gzFuRoE
// SIG // htElrmVNlDgYU1vdwk7+eY7a3NA/BEHKqHZYEDclokQA
// SIG // bG4IZJnyKYmtYEehbXaL8cgofwWeyiQHql0uLuvNErih
// SIG // DhyQiWykdiIvQZ8O9Jrwhh1dj+XiVZXPBvx2ORgmr/t+
// SIG // dFLOCFYbDXluh+2R6gRHwElPTUB01oqzBWXRDt8uKlc0
// SIG // I42fmdjjP/cxdPUhtx1eWFfOIg699AI31qyKfHZ0jluF
// SIG // 7s2GLd6Y349uNUKHJ4+uAiillKShgheXMIIXkwYKKwYB
// SIG // BAGCNwMDATGCF4Mwghd/BgkqhkiG9w0BBwKgghdwMIIX
// SIG // bAIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZIhvcN
// SIG // AQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkKAwEw
// SIG // MTANBglghkgBZQMEAgEFAAQgTAsHTTc5nqhuLkDmWksD
// SIG // piVEcTr3NdM5icCWr4FR8dcCBmm4V7wKJRgTMjAyNjAz
// SIG // MzExNzMwNTUuMjA5WjAEgAIB9KCB0aSBzjCByzELMAkG
// SIG // A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
// SIG // BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
// SIG // dCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
// SIG // IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNo
// SIG // aWVsZCBUU1MgRVNOOkE0MDAtMDVFMC1EOTQ3MSUwIwYD
// SIG // VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
// SIG // oIIR7TCCByAwggUIoAMCAQICEzMAAAIo8KWH1/PIHkAA
// SIG // AQAAAigwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTk0MDA2WhcN
// SIG // MjcwNTE3MTk0MDA2WjCByzELMAkGA1UEBhMCVVMxEzAR
// SIG // BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
// SIG // bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
// SIG // bjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3Bl
// SIG // cmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNO
// SIG // OkE0MDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3Nv
// SIG // ZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG
// SIG // 9w0BAQEFAAOCAg8AMIICCgKCAgEAro725P7KnAkkXmWi
// SIG // Xwrn9TcEXHO15J4ROsJC6H5DY9ZsRAIN+astsXBY4I2q
// SIG // 7VbwNPVvEB3KcjKlUlzk8TRybJpNKj9ggy71ALpVoO2k
// SIG // uaATkaRF9aM959Edpz6nh9CBytcycY8Wh1ttQG7mdGfs
// SIG // DN1mDc5AZXB5lXtN2Ru65ZNvIe9q+T+TBPBRqRZmFuR5
// SIG // e6bCm4CxH62AIrabbbG/rGbAVCPoTCpeLiyWKLSsmb9X
// SIG // sDiIpwX0VPEKLIr46H2gXs1H/TXVfohq1od9tVp0rCtw
// SIG // PyZehi7W0ll3CVlC4G8bqp6GzyvmJQd9e+EzFk4F+GFo
// SIG // xu6NDrc/6YxzQigWwe/PHcp4S3RmOgdPBPfuEhq0abLc
// SIG // uIiRzsnRwgOTOIucmEcLHbrfoJr8SKU/MjVyXIyQoNLz
// SIG // vJr/5xWPVsrb9qpgrQhRYrxlFqlNtP7FHkaKEGRokDiU
// SIG // J9PeQo94rCLL0T/ClO4TfxAyPB1bG/zT8zBS70c560Z4
// SIG // 9Ezpw4jk1HJ2MJpPl36EtaMLJHAggsB52wtNA+fM/N8u
// SIG // yuWSQe+OYXJ+AhNp0d3ukRrK+NsuarbejHc/7OzE5w0t
// SIG // lJlR1l9V/x2Xt1JV/II/7ety+dMSD6pEQgRHTNQAzVGk
// SIG // n6PTkIim/249XYmQhk3xA1AQS6KdZoZMCBfNn2qZVdm7
// SIG // rGflOJECAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSqyaWM
// SIG // +PLc6Lr1ZAVbYQEhaUPdwzAfBgNVHSMEGDAWgBSfpxVd
// SIG // AF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQ
// SIG // hk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
// SIG // L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
// SIG // JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwG
// SIG // CCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
// SIG // b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUt
// SIG // U3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMB
// SIG // Af8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4G
// SIG // A1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEA
// SIG // kOjXy5q0WoYFbYFoN/NxmktO3x8qHem4XFDjbdrXrfug
// SIG // Wjbh9K+wAZFR4XjqcQXa1KzhGFRGiIovXSt3LmSzZqdY
// SIG // lAMf1W5jmWJe8c/rTa4wlqq4NY0JqtKEQfIhOECacDYR
// SIG // j+u6GOYbmCFNA+JYQ6Goan4CiZ/9AZPvVCgz8OV5VGJq
// SIG // 3hZiZY/WEM3Dz3qfDMQV8Yf2OSO70HkWluUo7Yi0Di0Z
// SIG // N4IL62g7OUn+PTCVevwcMVwtq71HxBV+klA6KKiiBPTY
// SIG // FSEatEWbuzrdItCLPh7zz9IQeisDsTINUlijn07RaVqX
// SIG // aPDCb4Cgh5D6VxM4Kaz/qciB7ju4FUZUk7G2ARS4dsiH
// SIG // f4rTOLmC9EftkkgQU6UkkbYaxrhJhJSOQQhzMczIP6Kh
// SIG // 0j8GQCAJDNguMcYtEre6jLgPpvmcxWJH6BeNUKEiZ/h4
// SIG // 6oalmENJv0jvfypyUSSVMDHeU4jJ42fhPwyYlK8ubnYl
// SIG // skKb349oUBSNHY4WoaAFw2s3hHIixdrhJ07q/VH43MDr
// SIG // p/6DGPlC37ZzotoyizK63ldPe2pM8/ycaZw4GCVP7YFO
// SIG // 30H5YOyKoi/ftNu+vo6EB6NtZlXmOWA/Cof5FGmOiZvz
// SIG // kzPPBu3r08/6p0bpsaL04zErb6WwBzUYZkk3SD01d9gs
// SIG // rsQykv1eWuYsAPn/VYgaPsIwggdxMIIFWaADAgECAhMz
// SIG // AAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUA
// SIG // MIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
// SIG // Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylN
// SIG // aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3Jp
// SIG // dHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAx
// SIG // ODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
// SIG // YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
// SIG // VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
// SIG // BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
// SIG // MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
// SIG // 5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1
// SIG // V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeF
// SIG // RiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDc
// SIG // wUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus
// SIG // 9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130
// SIG // /o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHI
// SIG // NSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTes
// SIG // y+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGp
// SIG // F1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+
// SIG // /NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fz
// SIG // pk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNO
// SIG // wTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLi
// SIG // Mxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5
// SIG // UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9Q
// SIG // BXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6H
// SIG // XtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIG
// SIG // CSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYE
// SIG // FCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEG
// SIG // DCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRw
// SIG // Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
// SIG // UmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUH
// SIG // AwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYD
// SIG // VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
// SIG // BBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0f
// SIG // BE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQu
// SIG // Y29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0
// SIG // XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBK
// SIG // BggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQu
// SIG // Y29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
// SIG // Ni0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1Vffwq
// SIG // reEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1
// SIG // OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpT
// SIG // Td2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinL
// SIG // btg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l
// SIG // 9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJ
// SIG // w7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2Fz
// SIG // Lixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7
// SIG // hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY
// SIG // 3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFX
// SIG // SVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFU
// SIG // a2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz
// SIG // /gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/
// SIG // AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1
// SIG // ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328
// SIG // y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEG
// SIG // ahC0HVUzWLOhcGbyoYIDUDCCAjgCAQEwgfmhgdGkgc4w
// SIG // gcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
// SIG // dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
// SIG // aWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
// SIG // Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNV
// SIG // BAsTHm5TaGllbGQgVFNTIEVTTjpBNDAwLTA1RTAtRDk0
// SIG // NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
// SIG // U2VydmljZaIjCgEBMAcGBSsOAwIaAxUAda25hZM0u6gC
// SIG // tTmr9PAFJ4WzSFKggYMwgYCkfjB8MQswCQYDVQQGEwJV
// SIG // UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
// SIG // UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
// SIG // cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
// SIG // dGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAO11
// SIG // 8gUwIhgPMjAyNjAzMzEwNzExMDFaGA8yMDI2MDQwMTA3
// SIG // MTEwMVowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA7XXy
// SIG // BQIBADAKAgEAAgI+uwIB/zAHAgEAAgIR9DAKAgUA7XdD
// SIG // hQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZ
// SIG // CgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqG
// SIG // SIb3DQEBCwUAA4IBAQBWiXQeVt7zC4I8sN5iiyo258qQ
// SIG // b6ErpBWMzHmQ0lSYEoANJsWyjk0XPHEj9rTVHQOrubUX
// SIG // Psh7adqUQQ9XBWYtrdrOevASsl2jkTBJIBzRW/PcXf5/
// SIG // MQ43pmhAdgm/f5rBrn3KxeC/yL+A0X9d54jTQGLKXOC8
// SIG // 66SdwnWmF7jwpSi3p8FS3LoMS7MImqMk7BbIWySWTA4m
// SIG // 2oqJmWLn7e8OUB50tcynkizlPfWPYy8UX0g/FcQDp/4Q
// SIG // U/lVeiN/l7QxJylPhHjxRWsUxA1nM9f5B88eXUAUvlHe
// SIG // XyFmIXTZQbQJWHfnqlVEsiUK0HBe3/XsCYQKGlAQeFme
// SIG // BcoxlCQ2MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTACEzMAAAIo8KWH1/PIHkAAAQAA
// SIG // AigwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
// SIG // AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
// SIG // yvvta4szqRgnREppVe6l6tf0vwst599oncpqh80Zed8w
// SIG // gfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBVsYpG
// SIG // UWBjX+KBFWStXk+OR/txkN/6sVe+VcLgbfoi1zCBmDCB
// SIG // gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
// SIG // HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
// SIG // AAACKPClh9fzyB5AAAEAAAIoMCIEIIRWmULVQDO7FpnO
// SIG // QUulu4gWotDbZkjsNCSJTSlQKq/2MA0GCSqGSIb3DQEB
// SIG // CwUABIICAEBKKCAjHi5Qw4XoSTPl31yaSrQREJZMe5Gu
// SIG // vWSuNtl9wqJWGgc0l+bGN854jzAAxLFNONgLigbEEJOp
// SIG // Pt2caDW58Vd3i5+Y01p4AW47DO5C2zSmH/RdyHHENVFh
// SIG // Nzr1+RYfy5GkAoEmStYkN+y6NoD9McstRUBny3f7+QFU
// SIG // mgwrh9Jqvt5xOhUO7rk6s4ZOC+aPx3KHABWYHr5bRl8+
// SIG // 3Xj3hPBqwwQlyAnd4431wzxqd2loxpR9ab0ZQWMuTwNQ
// SIG // tL5BGscmtuiNaEmb96cXM1+rqTcmpBZrgVbyd1W2rfZD
// SIG // cc7Onykbn14uCrCAqkpQX2JbX140djlCTWUeMF0RCmxS
// SIG // /46++8THSk9HxmKsQG77qRUTk0k0AQ/vZvbyKx4lkS+U
// SIG // wvGKM4yynCzKh0Mhqu38O4xQKf2/6Zl8HCTgIqnVwsKP
// SIG // 6xGtWD6kfdZCEVvqDJsNzJyeyOhkLNtqAYQzRmWWoNHR
// SIG // paBwOQXll67Tv97031ES9TKq3M8KxU0BwXffjFFhAHeJ
// SIG // XcEDRVyBZqmU3qymIlkQi8V9YHPmDcFtvfwdDUaRHXJ9
// SIG // IvHkSQOT7kwdy/GxDj4KzVZQTx21T98LgLKH1IYaN/Ze
// SIG // zZFom3NVRKd5nELFmThoYBEg/m8IIniyL3UWbSYFGFkK
// SIG // rzWvPeGNfYadSG6wUaGKY/VpOmzH2Zm0
// SIG // End signature block
