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


// SIG // Begin signature block
// SIG // MIInQgYJKoZIhvcNAQcCoIInMzCCJy8CAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // JVmh1EHXDMzNOYehT3jzWDgcuMQCSGGhpPO6PKMi5J2g
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
// SIG // JkDeVuJ9dNXGNi+AOxk0BtYd9hxwL30BElj9MYIZ4DCC
// SIG // GdwCAQEwbjBXMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9N
// SIG // aWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDI0AhMz
// SIG // AAACHU0ZyE7XD1dIAAAAAAIdMA0GCWCGSAFlAwQCAQUA
// SIG // oIGuMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
// SIG // CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
// SIG // SIb3DQEJBDEiBCBJyKEtmnMU2AsllHHbN/7/QKLRZrxy
// SIG // JDG3p7DnlQ4WdjBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAC3T
// SIG // 5BAXGHhw8b7XSkFNS+zS8++UsaGGt2wB6DBxYQXtAAiX
// SIG // najVLLU+Vom1OXEuHxbm/RNygC83DCSHF9WFIK8zCxaq
// SIG // 0ORqgfKPaUHl7wVxHxhKlDwkQ8TwBtSlFiRNUAjO892E
// SIG // Fg8FZxOluEII7ubWn5iNEYfo2ahGCF/vRDgdSXl4wCDl
// SIG // 99yu0/R+QLOidVC0UGZTN2iuLqnl2itl6cm8vKfV556T
// SIG // VanTfcHHn+f1+Ub6AtPGnKgCY8jTgAULGfxVw2YXKtVY
// SIG // Ue8FBlmhj6IphpXorXXvjY/16stTRPGvgVqxyQBhV9hG
// SIG // d8jQjZPg90F1sbdn21PEKhyl13uXGiihgheSMIIXjgYK
// SIG // KwYBBAGCNwMDATGCF34wghd6BgkqhkiG9w0BBwKgghdr
// SIG // MIIXZwIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUAYLKoZI
// SIG // hvcNAQkQAQSgggE/BIIBOzCCATcCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQg6L/BIS+yVUCkYgoh
// SIG // yROckUMvtwiMyq/neV39V2+SjpoCBmqqLd010xgRMjAy
// SIG // NjEwMDMyMDAwNDEuM1owBIACAfSggdGkgc4wgcsxCzAJ
// SIG // BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
// SIG // DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
// SIG // ZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
// SIG // dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5T
// SIG // aGllbGQgVFNTIEVTTjo4OTAwLTA1RTAtRDk0NzElMCMG
// SIG // A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
// SIG // ZaCCEeowggcgMIIFCKADAgECAhMzAAACIkHS9qr/yLX/
// SIG // AAEAAAIiMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYT
// SIG // AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
// SIG // EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
// SIG // cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
// SIG // LVN0YW1wIFBDQSAyMDEwMB4XDTI2MDIxOTE5Mzk1NloX
// SIG // DTI3MDUxNzE5Mzk1NlowgcsxCzAJBgNVBAYTAlVTMRMw
// SIG // EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
// SIG // b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
// SIG // b24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
// SIG // ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
// SIG // Tjo4OTAwLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZI
// SIG // hvcNAQEBBQADggIPADCCAgoCggIBALW54om6Qi5SwAAm
// SIG // j8BjkNlGoftuGC/sJYY2UR1tEaghOt0Tpayfns1o27UF
// SIG // N2MFsVy/tF+LG17TH4dG9dKqwP5Z5Jf/r/L3ATQzP7FE
// SIG // 9MYhjbQrtpANrrw7LNXJR5QLKnJkL+Bb/fK079k6dT0f
// SIG // auLvuQk/wAGurLLVTFf86x4SC8eyPzKKRZPQBG2uNZtc
// SIG // wcXNI6jmFBx9SYxcqpZbPr43T5TKeEbLWf52hbhZmCkf
// SIG // xjlbuGlKiRaPUz8u7jCLejoPP29Va6RyBQUaMsCXhhmk
// SIG // 6FqHse6IL9qVciYxB/wLcDyr/r/WEWh4hkHhQaTLDEH8
// SIG // 5JM5Kwvr7f2kOrMzsKA6l/hXv32Q33jIz25ckjlP9KID
// SIG // kx0hkiERbT5uHzlGoOHlhbf+hq/nhE/HDk4+UfrhBXoo
// SIG // mSXQUgSUxWgs2jxRZFBwwPXv3HtYBKMLouxo1nvIrSpw
// SIG // RIiwvXCJCZ19AHFyqsUKkhB+eZAWQ6n0jJdRarNry2an
// SIG // PwTppeD1vV6IBPc9VOCs6U+L+FhkJ8/Ff/qMa3I+PLUK
// SIG // LA6YlqaiGZJT/8I4B6d9FPYbYcxFSkJfXOz4CYOZ1AzV
// SIG // dFpvhhIAssCUPMYKyAjvuee4mOhcCWIma/s1+u9YBwDk
// SIG // qoJQ5ZDqRI+3mvbwx8pdYkmlJe0V5L8yQPMnL+IlFXId
// SIG // wXL8H4y3AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUWQfA
// SIG // agMnllsQSK7wqy2K6ypqjNAwHwYDVR0jBBgwFoAUn6cV
// SIG // XQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
// SIG // UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
// SIG // cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBD
// SIG // QSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
// SIG // BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
// SIG // Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
// SIG // LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0T
// SIG // AQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
// SIG // BgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIB
// SIG // AGIAz6equnAbb23FJe/jaj4KxN7YLhuhpF8WO70lpaQt
// SIG // MfCrumSc040vef5QbfH8HTzcQpeIVisCa6XsFMcIZdTr
// SIG // f/FGxnbCPdmZHQDh32d/2xoIlWbiO49UUFqL+iS045gf
// SIG // aP7X7MzvTCg3mieAH+m/LtfwB9jokHhc+9vzRDPt9jl5
// SIG // 11ufCPODWxmFQ8VttzB5Z4AIg2vOoUrraYx5cqaG258y
// SIG // tqiiAl4ld9ZjfHj+lu5uAQ1Pf6ldPrnbTcI8X2R90oTs
// SIG // YoAhFjLfGQFMO8V3x25+M6kKffycrqoyVW2cGMOFZAbQ
// SIG // 8zcT+jEGzlQGsjqkFiSYge1uOJ8Oq4dP5OFpVXvEdzoi
// SIG // ehJzdo3Nfj0kdSBCa68N0yMuRthd4DT/WrkjFKDZT7Jx
// SIG // kE68CLe51k8qEDlXM4ON/+5y7+8W1ethxGSYYo3eO6No
// SIG // rf/IxmLYm7k0QvchJaivCntGN5mD4kwgrR+iy5WP5gKb
// SIG // mvrgsf8P1AkMCP5d9lo14V2/3QrkDRBFEY/+mgH3JMhW
// SIG // MReP+4nOnwvgN3jiwCq6oM6Id2QuDF8ryc+qkJJY9n0b
// SIG // 5EI+bzmj1wB/EQ22tK47BynIrPGxEJgIv48rj73yiuK3
// SIG // 0RUn8sugJ4b6MuWPQpoPhDLqxl7itYyvVutAuixMFk3A
// SIG // WdfE2MicJYF3SLuKzXJNL/ipMIIHcTCCBVmgAwIBAgIT
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
// SIG // BmoQtB1VM1izoXBm8qGCA00wggI1AgEBMIH5oYHRpIHO
// SIG // MIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
// SIG // Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
// SIG // aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYD
// SIG // VQQLEx5uU2hpZWxkIFRTUyBFU046ODkwMC0wNUUwLUQ5
// SIG // NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
// SIG // IFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVALvJxdVnHduw
// SIG // OkmSvtW5yCmSyjO4oIGDMIGApH4wfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDu
// SIG // a7vNMCIYDzIwMjYxMDAzMTczNzE3WhgPMjAyNjEwMDQx
// SIG // NzM3MTdaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAO5r
// SIG // u80CAQAwBwIBAAICFXcwBwIBAAICE3AwCgIFAO5tDU0C
// SIG // AQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoD
// SIG // AqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkqhkiG
// SIG // 9w0BAQsFAAOCAQEALorbC5FY/9++2jRXLLz7B/9L3O0z
// SIG // 0fQQ7B3oQUyC5WssrBBlnq0fG+4HT6YGpTEB2CYuPzKB
// SIG // XTNqib0q01RB6M0x/9Nl5dO0xkxwmmE8wtR7EYJsa+bv
// SIG // eWjexv+0SDsjtweH85diprKF4X6lIYjoXy57AG92bQvx
// SIG // Bes1uXAOqLXzyF0xjrymkfIeVIAVFIrNKc+nrxVNgVRG
// SIG // s7jBr0c/HNr7bcZRwKVajtlJ1VQP06HEkOwEDMUO+6Mh
// SIG // 3UR/gmRdIGYqLfxwamA+tonjuHcM7Ydr95VPmZZwymqe
// SIG // jzE8MblPQQs3oNvWYjSlXRcgdx8IMsaQlZIUTIXt3EVh
// SIG // 9vyeeTGCBA0wggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVT
// SIG // MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
// SIG // ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
// SIG // YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
// SIG // YW1wIFBDQSAyMDEwAhMzAAACIkHS9qr/yLX/AAEAAAIi
// SIG // MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMx
// SIG // DQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIGjE
// SIG // dDaBpyxtwKIV6XaTSjUVU6JJeK1faUAE6zOAJE6+MIH6
// SIG // BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgBWBdAQoE
// SIG // 58aCM2ySYM6ZtwQg6ccY3AD5BxG58NHkCRMwgZgwgYCk
// SIG // fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
// SIG // Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
// SIG // aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAA
// SIG // AiJB0vaq/8i1/wABAAACIjAiBCDYvtzI/TPicj9VYoJk
// SIG // EL3J2pmRs2JTyy35l8ZtQ4nTAjANBgkqhkiG9w0BAQsF
// SIG // AASCAgAGtMWtiPPBMscJ3Q4NA8yd4Zl3BZWHF4RF83ow
// SIG // W+e/DWHZYFcgB43jTz3qMLrzpsgbDGQaJOM5bgZ91LnC
// SIG // ofo366uIyZIA8s1cgyBuuVrEWN/daE45bfo65JJcgsHH
// SIG // OLqiSINLtukdsM4jDksZY6bVpjr5UGml26yECoTNRt7v
// SIG // qgTrFarlWjd02Iu4FlDeYKWHvVNoE3oiPkvhFyGFlXDv
// SIG // jq+Ry5OkxetrQrZlEdr9SqPzikGHVvM4CSU6U3hP+i5b
// SIG // p170TLb9ftr3QhilwKhBVaq1RF2kUC8lx9gYwjYaYvSi
// SIG // tgXrXjpV4BmEv7BKh31lrC7fIYlq38VmclxV3qC3vMC7
// SIG // zY9Ddgy6beST9ZijTonEr220gnaxSwEfrqH3vRZPpNFo
// SIG // 0dA1UjFUA6CT5HOEK/U3a+BmZkNzgZTOQJ6f9EzqvLgl
// SIG // 0Zb1IhOLGbrjf1BDa6oI/H8arX4pZHCS933YTaLdCdj5
// SIG // O9W8RviFeoNghx6q2IM3JFVR0/VYTxTimAzQ2QV4gyaO
// SIG // 4+6RdWXRMprfQ0gLnTIlID6LUOjE9NWgazfZ5wWlX/05
// SIG // 2Xumo387YhFU4miCPu7eHLG5Yf/15M1M3Ue2+BEk6f/t
// SIG // n4X604OzgeJJIWW6aA/dVQ3w4bkEG+g0GdZMcgMZ5eEf
// SIG // eTLmGzQyTMzeVpFooKiEpvJUBkh2UA==
// SIG // End signature block
