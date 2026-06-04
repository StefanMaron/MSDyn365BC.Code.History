/*
This addin communicates with OAuthLanding.htm using localStorage. The keys used in the localStorage must be the same in both the files.
*/
var AuthStatusKey = "NavOauthStatus";
var RegistrationStatusKey = "NavRegistrationStatus";

function StartAuthorization(url) {

    OauthLandingHelper(url, AuthStatusKey, handler);

    function handler(data) {
        if (data.code) {
            notifySuccess(data.code);
        } else if (data.error) {
            notifyError(data.error, data.desc);
        }
    }

    function notifySuccess(code) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AuthorizationCodeRetrieved', [code]);
    }

    function notifyError(error, desc) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AuthorizationErrorOccurred', [error, desc]);
    }
}

function Authorize(url, linkName, linkTooltip) {
    var a = createHyperlink(url, linkName, linkTooltip);

    a.onclick = function () {
        StartAuthorization(url);
    }
}

function RegisterApp(url, linkName, linkTooltip) {
    var a = createHyperlink(url, linkName, linkTooltip);

    a.onclick = function () {
        if (!isFeatureSupported()) {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AppRegistrationErrorOccurred', ['NotSupported', '']);
            return;
        }

        OauthLandingHelper(url, RegistrationStatusKey, handler);
    }

    function isFeatureSupported() {
        var isSupported = false;
        switch (Microsoft.Dynamics.NAV.GetEnvironment().Platform) {
            case 0: // windows
            case 1: // web
                switch (Microsoft.Dynamics.NAV.GetEnvironment().DeviceCategory) {
                    case 0: // desktop
                    case 1: // tablet
                        isSupported = true;
                }
        }
        return isSupported;
    }

    function handler(data) {
        if (data.clientId && data.clientSecret) {
            top.window.localStorage.setItem(RegistrationStatusKey, 'success');
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AppRegistrationInformationRetrieved', [data.clientId, data.clientSecret]);
        }
    }
}

function OauthLandingHelper(url, key, callback) {
    var w = top.window;
    var aadWindow = w.open(url, '_blank', 'width=972,height=904,location=no');

    if (aadWindow == null || aadWindow.closed || typeof aadWindow.closed === "undefined") {
        callback({
            error: "Popup blocked",
            desc: "There was a problem opening the authentication prompt. Check if it was blocked by a popup blocker."
        });
        return;
    }

    function storageEvent(e) {
        if (e.key === key && e.newValue) {
            w.removeEventListener('storage', storageEvent, false);
            action(e.newValue);
        }
    }

    function messageEvent(e) {
        if (e.data.clientId) {
            w.removeEventListener("message", messageEvent, false);
            action(e.data);
        }
    }

    function action(data) {
        var obj = data;
        if (typeof data === 'string') {
            obj = JSON.parse(data);
        }
        callback(obj);
        closeWindow();
    }

    function closeWindow() {
        try {
            w.removeEventListener("message", messageEvent, false);
            w.removeEventListener('storage', storageEvent, false);

            try {
                if (aadWindow.onbeforeunload) {
                    aadWindow.onbeforeunload = null;
                }
            } catch (e) { }

            if (w.localStorage.getItem(key)) {
                w.localStorage.removeItem(key);
            }

            aadWindow.close();
        } catch (ex) { }
    }

    function isCordova(win) {
        if (typeof win !== 'undefined' && win) {
            try {
                // this can throw a 'Permission denied" exception in IE11
                if (win.executeScript) { // if cordova. Is there a better way to detect?
                    return true;
                }
            }
            catch (e) {
                return false;
            }
        }

        return false;
    }

    if (isCordova(aadWindow)) {
        aadWindow.addEventListener("loadstop", function () {
            function getDataFromWindow() {
                aadWindow.executeScript(
                    { code: "localStorage.getItem('" + AuthStatusKey + "');" },
                    function (data) {
                        if (data && data.length > 0 && data[0]) {
                            var value = data[0];
                            clearInterval(loop);
                            action(value);
                        }
                    }
                );
            };
            var loop = setInterval(getDataFromWindow, 1000);
        });
    } else {
        w.removeEventListener('storage', storageEvent, false);
        w.addEventListener('storage', storageEvent, false);
        w.removeEventListener('message', messageEvent, false);
        w.addEventListener("message", messageEvent, false);
    }
}

function createHyperlink(url, linkName, linkTooltip) {
    var a = document.createElement('a');
    var linkText = document.createTextNode(linkName);
    a.appendChild(linkText);
    a.title = linkTooltip;
    a.href = "#";
    a.className = getLinkClassName();

    document.getElementById('controlAddIn').appendChild(a);
    return a;
}

function getClassNameSuffix() {
    switch (Microsoft.Dynamics.NAV.GetEnvironment().Platform) {
        case 0:
        default:
            return '-windows';

        case 3:
            return '-outlook';

        case 1:
        case 2:
            switch (Microsoft.Dynamics.NAV.GetEnvironment().DeviceCategory) {
                case 0:
                default:
                    return "-desktop";
                case 1:
                    return '-tablet';
                case 2:
                    return '-phone';
            }
    }
}

function getLinkClassName() {
    return 'addInLink' + getClassNameSuffix();
}

Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady');

// SIG // Begin signature block
// SIG // MIInRwYJKoZIhvcNAQcCoIInODCCJzQCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // MHuD+Jd7RaUoY+JY9dBzS6FDLBLed1jlALFpLQEjQDug
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
// SIG // SIb3DQEJBDEiBCABP5Oxl4ICe0uHJzx59ERf8vThYsKM
// SIG // VPVuPknt34ddKjBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBACHP
// SIG // Ks3iNz/ChIlP/P4HjBF2mCazD1HzdkLvW6PC153+aJvh
// SIG // LMgGQgdQvh5NekJ3Gb42remrkxnRBiKq+iERH4zDHUTK
// SIG // EGXEhZ4FixQznPoye5ioupFXF4D//oefdJEeNEXwIAmo
// SIG // knJCv1PJcFcREmMIG18ulqgLe2Fv/y9zmMBAutqlnUtk
// SIG // T1lHjX7/iRW60SSc4w/dkJl13nFPNw8jptc9F8hxlb+g
// SIG // GJroKPfTjx+t8ibld16B0RsaqT8/DVi7SjdLQDLP+txs
// SIG // 9Y7q50TvKdjWwmVcoJ0z1dtCy5jIAjZMUIrFF9YSqHm1
// SIG // PDq7QachiSfcRKav8s20/iUdayRTzPGhgheXMIIXkwYK
// SIG // KwYBBAGCNwMDATGCF4Mwghd/BgkqhkiG9w0BBwKgghdw
// SIG // MIIXbAIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQg3ip8qgQBUTkGkEsy
// SIG // Xe7ybulC2kwOUsiwtkqWIrSZrywCBmnnsQomBhgTMjAy
// SIG // NjA1MDExNzA1MzEuNzY1WjAEgAIB9KCB0aSBzjCByzEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
// SIG // b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
// SIG // blNoaWVsZCBUU1MgRVNOOjg5MDAtMDVFMC1EOTQ3MSUw
// SIG // IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
// SIG // aWNloIIR7TCCByAwggUIoAMCAQICEzMAAAIiQdL2qv/I
// SIG // tf8AAQAAAiIwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTkzOTU2
// SIG // WhcNMjcwNTE3MTkzOTU2WjCByzELMAkGA1UEBhMCVVMx
// SIG // EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
// SIG // ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
// SIG // dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
// SIG // T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
// SIG // RVNOOjg5MDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNy
// SIG // b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtbniibpCLlLA
// SIG // ACaPwGOQ2Uah+24YL+wlhjZRHW0RqCE63ROlrJ+ezWjb
// SIG // tQU3YwWxXL+0X4sbXtMfh0b10qrA/lnkl/+v8vcBNDM/
// SIG // sUT0xiGNtCu2kA2uvDss1clHlAsqcmQv4Fv98rTv2Tp1
// SIG // PR9q4u+5CT/AAa6sstVMV/zrHhILx7I/MopFk9AEba41
// SIG // m1zBxc0jqOYUHH1JjFyqlls+vjdPlMp4RstZ/naFuFmY
// SIG // KR/GOVu4aUqJFo9TPy7uMIt6Og8/b1VrpHIFBRoywJeG
// SIG // GaToWoex7ogv2pVyJjEH/AtwPKv+v9YRaHiGQeFBpMsM
// SIG // QfzkkzkrC+vt/aQ6szOwoDqX+Fe/fZDfeMjPblySOU/0
// SIG // ogOTHSGSIRFtPm4fOUag4eWFt/6Gr+eET8cOTj5R+uEF
// SIG // eiiZJdBSBJTFaCzaPFFkUHDA9e/ce1gEowui7GjWe8it
// SIG // KnBEiLC9cIkJnX0AcXKqxQqSEH55kBZDqfSMl1Fqs2vL
// SIG // Zqc/BOml4PW9XogE9z1U4KzpT4v4WGQnz8V/+oxrcj48
// SIG // tQosDpiWpqIZklP/wjgHp30U9hthzEVKQl9c7PgJg5nU
// SIG // DNV0Wm+GEgCywJQ8xgrICO+557iY6FwJYiZr+zX671gH
// SIG // AOSqglDlkOpEj7ea9vDHyl1iSaUl7RXkvzJA8ycv4iUV
// SIG // ch3BcvwfjLcCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBRZ
// SIG // B8BqAyeWWxBIrvCrLYrrKmqM0DAfBgNVHSMEGDAWgBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
// SIG // UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
// SIG // UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
// SIG // MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
// SIG // bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
// SIG // HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
// SIG // MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
// SIG // AgEAYgDPp6q6cBtvbcUl7+NqPgrE3tguG6GkXxY7vSWl
// SIG // pC0x8Ku6ZJzTjS95/lBt8fwdPNxCl4hWKwJrpewUxwhl
// SIG // 1Ot/8UbGdsI92ZkdAOHfZ3/bGgiVZuI7j1RQWov6JLTj
// SIG // mB9o/tfszO9MKDeaJ4Af6b8u1/AH2OiQeFz72/NEM+32
// SIG // OXnXW58I84NbGYVDxW23MHlngAiDa86hSutpjHlypobb
// SIG // nzK2qKICXiV31mN8eP6W7m4BDU9/qV0+udtNwjxfZH3S
// SIG // hOxigCEWMt8ZAUw7xXfHbn4zqQp9/JyuqjJVbZwYw4Vk
// SIG // BtDzNxP6MQbOVAayOqQWJJiB7W44nw6rh0/k4WlVe8R3
// SIG // OiJ6EnN2jc1+PSR1IEJrrw3TIy5G2F3gNP9auSMUoNlP
// SIG // snGQTrwIt7nWTyoQOVczg43/7nLv7xbV62HEZJhijd47
// SIG // o2it/8jGYtibuTRC9yElqK8Ke0Y3mYPiTCCtH6LLlY/m
// SIG // Apua+uCx/w/UCQwI/l32WjXhXb/dCuQNEEURj/6aAfck
// SIG // yFYxF4/7ic6fC+A3eOLAKrqgzoh3ZC4MXyvJz6qQklj2
// SIG // fRvkQj5vOaPXAH8RDba0rjsHKcis8bEQmAi/jyuPvfKK
// SIG // 4rfRFSfyy6Anhvoy5Y9Cmg+EMurGXuK1jK9W60C6LEwW
// SIG // TcBZ18TYyJwlgXdIu4rNck0v+KkwggdxMIIFWaADAgEC
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
// SIG // BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo4OTAwLTA1RTAt
// SIG // RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
// SIG // bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAu8nF1Wcd
// SIG // 27A6SZK+1bnIKZLKM7iggYMwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIF
// SIG // AO2etC4wIhgPMjAyNjA1MDEwNTEwMDZaGA8yMDI2MDUw
// SIG // MjA1MTAwNlowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA
// SIG // 7Z60LgIBADAKAgEAAgITuwIB/zAHAgEAAgISmDAKAgUA
// SIG // 7aAFrgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
// SIG // AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0G
// SIG // CSqGSIb3DQEBCwUAA4IBAQAnteRuvK+aZp8d0IrNgYXK
// SIG // 9OrKHKfqbAfqP7pYerQDtfP4Z5Dvpryw2DcYbvGRg1nV
// SIG // imR/AdobMTVV+SBdRgHUaHNYNbF31AwJ/OFWfbxeBfKk
// SIG // Tcl4xuIw54zyvwETZWQQcrS6eeqg5wN2EkTsQuNouHZt
// SIG // GVzTd2kNSLkKf+S9mmWuxtXH0hcwV40Lex31pEKQDhG0
// SIG // kwQ8/Kb8vqdULtb/ruy7D/6eWeU2+VYp+YB/WHGVh32f
// SIG // POlbydDB1WHh/Yx4q5SRjcfPBSJasC0yXJkGWj8dhKeA
// SIG // ntWMLVDQg5QTuqGByLy7s5aIMQV60lr7dkLwYprxnKq6
// SIG // TqkNCkOmme+9MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTACEzMAAAIiQdL2qv/Itf8A
// SIG // AQAAAiIwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3
// SIG // DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
// SIG // IgQgljj5rRwJ8tobuK3eKpUC12ePjRQcCf1adkkxx9It
// SIG // rRUwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAF
// SIG // YF0BCgTnxoIzbJJgzpm3BCDpxxjcAPkHEbnw0eQJEzCB
// SIG // mDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
// SIG // YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
// SIG // VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
// SIG // BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
// SIG // AhMzAAACIkHS9qr/yLX/AAEAAAIiMCIEIGia2FXOm/Vw
// SIG // 0OWV1oQQBMOXOieAVCvH5l/rvBNtDnFHMA0GCSqGSIb3
// SIG // DQEBCwUABIICAA1EKyC3BY+Y026NgQY0nblDT8YtsCyz
// SIG // ndfM/Lwspt3ml2ZbNKFhnT0oxNdCQbfy+Tq8da/nutnH
// SIG // y+gRHYumGZVCI/6jpDaAl8GKct9K5dEKAexW1E6xg/ja
// SIG // gL44LTZBCvGi92/nTmiekT2RuJYK8WrT5IOjtnQwE1KI
// SIG // OyoxEXu5JSbJS5t5hVsam5JsOv3ji7p6xoLa4Eu1ILKc
// SIG // n+hyst1SH7nT1lq75xmN/HIWNqkSG4A6ufHjM8fxqsjl
// SIG // QTA7/3IGCOlSTSYs640WymFVf/5fH97QSQrvTUzZ9pQ0
// SIG // CqP2oIDnU/m/S6JC23Lbj54gqGOel6yp++UmxLqt9XqS
// SIG // Eos1T3lyJt6YZPxPTPuRT7eQG1U96eTfOE0SmBMaKyrm
// SIG // wKn8E8Qreei/IWoHHCM+4prXfnt2tEaxH39WUO7PAFCc
// SIG // 5dQbUagQukeY2f3m6t+SyKml90VvZrjUWLjkeVHCJJHd
// SIG // tJ37Gj2mrHedU71H1JivIkAYiAtZg8rG1meVjb3dHIet
// SIG // x9CpQ6+bqoXpUoj+UkOhy77PcPpaio6+kZunLGratOOv
// SIG // CIzghFKRe8E4qRkEcqy1HbXU98z0UHWDwLNXnG6KK+b2
// SIG // ke1G6gjqIVJieHZ6qHhf/Ef8nOjyv7U0EZB9l0e2eh/V
// SIG // G2VBOejuftKZgevZFg99DtT5n/bDD5ftTi30
// SIG // End signature block
