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
// SIG // MIIoKwYJKoZIhvcNAQcCoIIoHDCCKBgCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // MHuD+Jd7RaUoY+JY9dBzS6FDLBLed1jlALFpLQEjQDug
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
// SIG // DQEJBDEiBCABP5Oxl4ICe0uHJzx59ERf8vThYsKMVPVu
// SIG // Pknt34ddKjBCBgorBgEEAYI3AgEMMTQwMqAUgBIATQBp
// SIG // AGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5taWNy
// SIG // b3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAGkfBZbb
// SIG // khx18sM048WIf9gUe0XS8f/gov5io9qKsl7UuEQn358b
// SIG // iFE3ktzdP6ZJpYUWDprTApWYwM5SIdmaXc2ez+aDjavc
// SIG // mannMVfmw9IkIDDRlAXjS64OriyOp5GFsLJIawu9wOSx
// SIG // /UfqOLPcQ8bM1D/Q/ZO7HKjmFhW9QaKQLouKeX3i7ANV
// SIG // 4aGbvcFS69GHdR/OX2NkiH7oED0GwEzveKo1whqKo1Nh
// SIG // yI6hh9MGqIC+3ciQOj1EbSRJc60D3vjFYaegVZelceqN
// SIG // Gwm/DU0pEFLCulX28ebHY2tTHHt9mh/5dvCzpK8rPAPq
// SIG // q/zyyxZWO9EZlHmzbtwQv2EW/g6hgheXMIIXkwYKKwYB
// SIG // BAGCNwMDATGCF4Mwghd/BgkqhkiG9w0BBwKgghdwMIIX
// SIG // bAIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZIhvcN
// SIG // AQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkKAwEw
// SIG // MTANBglghkgBZQMEAgEFAAQgoMAGfATe7HIrr4PKPMbc
// SIG // vZZDXNXOMHSUjRFoPL1u1HUCBmnBS43bPBgTMjAyNjAz
// SIG // MzExNzMwNTQuODk1WjAEgAIB9KCB0aSBzjCByzELMAkG
// SIG // A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
// SIG // BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
// SIG // dCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
// SIG // IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNo
// SIG // aWVsZCBUU1MgRVNOOjg2MDMtMDVFMC1EOTQ3MSUwIwYD
// SIG // VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
// SIG // oIIR7TCCByAwggUIoAMCAQICEzMAAAIlgMc3xs2qd0kA
// SIG // AQAAAiUwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTk0MDAxWhcN
// SIG // MjcwNTE3MTk0MDAxWjCByzELMAkGA1UEBhMCVVMxEzAR
// SIG // BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
// SIG // bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
// SIG // bjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3Bl
// SIG // cmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNO
// SIG // Ojg2MDMtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3Nv
// SIG // ZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG
// SIG // 9w0BAQEFAAOCAg8AMIICCgKCAgEApvESD9HiwOOlXAj6
// SIG // L75qrCJTeqpJs+SLB1plFNJ3lKqfLhsWnXqPksFgQsEO
// SIG // WpWSPwzXaV38omS2Uel2IKUTxc3qSJezgg2+DbRLJCQi
// SIG // GQ5EDDcKx/WMFMru9RhooLCyMXpXh7QN7raFU3h40tW/
// SIG // FJ8DkUbZJypMq1AK0+maQdq6HSHJnC3L98d8MIGJTrNB
// SIG // RIORLFa2W+yzXP53dG1w6fh0zllrovHqE1cCXi8XFT/O
// SIG // vaBfJYuUlPNWmtrRievybHo4s/STFvEiVygU9gwlzDlJ
// SIG // ArBo6Jz2Uan76DEiEGYLWjk8gCZa77MtE2e/F6xqqMoL
// SIG // UIpkJ2zgC+CjS0grluU2REBkxyzkCRoIIG94+YCgu+/P
// SIG // kSDyQPp/4Zhyf8eKk/x00z6FXjAnLgSlq0F0dfv6WGrt
// SIG // xcHtLViMhvi1s5Ea/2TTz7qXANmHIt6p/B0fUcL0KKak
// SIG // jScJ9kYumpvAEMn1VcvwQcNLeo6aET48Cr7lI3ws6Wnu
// SIG // nbjsULUNVwzfTwNspfbA5KP/gF1f0jnvHmvEKEHL97Nx
// SIG // K5Bvi6eoZ78OjjD4mp+IIDZEbYLQe66NToqKTlFyZ/WO
// SIG // RDtyVAFzXLjPZvuTMtVRLrxsrYAB97sZrJU51t2G632s
// SIG // 2skgkkp1pIWjmd94YG7lEHx+59jRRAFHP3Bc35gkFIpF
// SIG // orJyWMsCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSxONKq
// SIG // F07jB19wH2VLtZ/J8dofdzAfBgNVHSMEGDAWgBSfpxVd
// SIG // AF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQ
// SIG // hk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
// SIG // L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
// SIG // JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwG
// SIG // CCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
// SIG // b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUt
// SIG // U3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMB
// SIG // Af8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4G
// SIG // A1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEA
// SIG // B533NslMqB2W778lShbl4eR8cRyLyGkfSVqSHyEyZXPy
// SIG // otN47kfr3JM6t7aeXxR+Sy+3iBV0SLqHsDLL1nha1rn6
// SIG // 61uB4ZoQsJKgK3wNQtMZPh2mLNjuPGEsTF/ZYEtZE0yG
// SIG // 92LH6BXRaSrqz39p3NmHeMC4PhYMJpMZHshNzFClZ2vE
// SIG // mXlaRI50ubnBXJOLKz8CtjkQH+9CNtxhsj4aoCCmaYTV
// SIG // 4UrHEwELMiKgeRsAzHUVeSyt+zX1OGJsbwmId0xWBPxo
// SIG // dNUOsib3/R8YhGacFvqFJNIK7h6G4N7ICEea34FKPJd9
// SIG // L1J2g2DHDwApWhTAv0Gx2UmlIVl2RtTjnDKdIPb2EDSw
// SIG // xKhV9o5arr81UksLR7ZtSk5XQo0RA/pHQsm3D8Wz2pcC
// SIG // YoF3NQbCPQorZ039JY8G/TZGfyVSPPw+tq1184c+Bd7t
// SIG // IlRs8J3BmsUcRxv17+J066ZDnnqaGGzQWzFkthtaj914
// SIG // +6VX9PuKkcgKidLLY0I6FTiSJlT1kY8+T0dw5+mnUFTA
// SIG // SQzOoA649a2UxVYArU4o6hmUhs716RpBd72LMhOmQ5mv
// SIG // 5BnYlHubGniOpR+uj4lll4Ksbe7MthM79MiI0lb/njDk
// SIG // 9kDFImelgnO4FbQJl6X3iLrPjZoBbzPiHNV+fHuCPRC+
// SIG // GUgInUqVltBmUyzQtNpq8i4wggdxMIIFWaADAgECAhMz
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
// SIG // BAsTHm5TaGllbGQgVFNTIEVTTjo4NjAzLTA1RTAtRDk0
// SIG // NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
// SIG // U2VydmljZaIjCgEBMAcGBSsOAwIaAxUAU2/myjjwIwgX
// SIG // 5Yc8ORFwbklsXg6ggYMwgYCkfjB8MQswCQYDVQQGEwJV
// SIG // UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
// SIG // UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
// SIG // cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
// SIG // dGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAO12
// SIG // VM8wIhgPMjAyNjAzMzExNDEyMzFaGA8yMDI2MDQwMTE0
// SIG // MTIzMVowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA7XZU
// SIG // zwIBADAKAgEAAgIZEgIB/zAHAgEAAgITUzAKAgUA7Xem
// SIG // TwIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZ
// SIG // CgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqG
// SIG // SIb3DQEBCwUAA4IBAQCAZcXJAnb5k3SmkkaBeevZA1sa
// SIG // NamlS8lq3kLbDDBvd8FK0gyDvlp2ok/r4c2hLoLW8v3+
// SIG // CPCo/IKJCTIcVVev5ccUy4XaRuIL5oRqg0aFsCkjGlah
// SIG // 5vus+5q5zt9N/YDf4wTrsV4tNE+OxJPJYt/09oe2OXmd
// SIG // C0hKIU33s8QP3VtCZga4Eyhj3s5mwJunJiBfpvpwrvO+
// SIG // UZoQWdje653B6mADzAO0EXYgaYWe4tHjX0eLkzqf9h9v
// SIG // A8F8KRmgLDGVqGOHpLVviYZXvOIqeLNuKa2pL+HtNKvJ
// SIG // FzYQHgkCWyREXzlaKY2vbuIcXk0KIFPC70sbJ+icyRDr
// SIG // smnptm1IMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTACEzMAAAIlgMc3xs2qd0kAAQAA
// SIG // AiUwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
// SIG // AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
// SIG // xk860iz6C2SIa8DvWv2DzTv3mabVj8xDGRxaNBNZqpcw
// SIG // gfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBWDe6I
// SIG // ejjd8vdgpgJf5RdAmMK41lkD+nQlMWoz0hyhEDCBmDCB
// SIG // gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
// SIG // HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
// SIG // AAACJYDHN8bNqndJAAEAAAIlMCIEINvF0hWBCSTLl0S5
// SIG // jEOx5kDGxSAXekdNSqb/yCmxPUOCMA0GCSqGSIb3DQEB
// SIG // CwUABIICAE4GV7s1hZrqzKM47YL1ySrUo32gF8La1Naa
// SIG // 0oY/pMhUZAUO8DyXc4us/YGx+BRWUSWotc+gd7mUtuXH
// SIG // PuaOdaN/0jq7VcPmPKHOi4zsr91GJXmmGLp2XR/MBUUl
// SIG // dr25HvDecrD6V4cF6qX6tmaKO9uNuS6M+40me6z5ab3g
// SIG // dbXI551qSpc+RrcE3UHQw70JN0JwuCsc0eZKSkLO2iBU
// SIG // QyEixsKLO99AvqT8kHjSpWSBTm2UjgifVuDC71wNqmtl
// SIG // t2lrvO8Xhdy0jzNi63dTYW78tWdaYV/4s7Sxuffzt8uh
// SIG // 1iTakdbjwaHjLg0bqdmCTmkylwX4gXY+2DpLhIeIXFCb
// SIG // coWi9BvOdkXbOdZdLjLnUEqHXdCv/QAa/FyhKibqP0hY
// SIG // yWT9T+o4xAuQsAc4RFTVC9vOilX0qpEgStZPu19rY++N
// SIG // LWpyYPe9WlBOQ1bW5Tcb1bqUnQhm0ZuKfL7nAEKv8HC9
// SIG // 30uTfw9+Kk9vcNfRA9lK3KFu7VbFXgi+rGyza0v7jXqw
// SIG // VaKGuDsxj1q9wA+1aSZDPf6QoxdZD1/DFIlFT61yjMcj
// SIG // x5ADNUgFFHdYgrN9Bmdo8pP+jUh9Cpa6rxVNx7eRqqW7
// SIG // MMbH1o4vksTfKINEmcuMcPcMWmnwvgPilbaJNZBdo3RS
// SIG // vXw6NN6MWDGn9auc0IuxWkvooJa3eFGS
// SIG // End signature block
