var WelcomeWizardAddIn = function () {
    var notifyError = function(error,description) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ErrorOccurred', [error, description]);
    };
    return {
        notifyError: notifyError
    };
}();

var roleCenterTitle;
var roleCenterDesc;

function Initialize(titletxt, subtitletxt, explanationtxt, intro, introDescription, getStarted, getStartedDescription, getHelp, getHelpDescription, roleCenters, roleCentersDescription, roleCenter, legalDescription) {
    DrawCanvas();
    DrawLayout(titletxt, subtitletxt, explanationtxt, intro, introDescription, getStarted, getStartedDescription, getHelp, getHelpDescription, roleCenters, roleCentersDescription, roleCenter, legalDescription);
}


function DrawCanvas()
{
    document.getElementById("controlAddIn").innerHTML = "";

    var canvas = document.createElement('div');
    canvas.className = "mainCanvas";
    canvas.id = "mainCanvas";
    document.getElementById("controlAddIn").appendChild(canvas);
}

function DrawLayout(titletxt, subtitletxt, explanationtxt, intro, introDescription, getStarted, getStartedDescripion, getHelp, getHelpDescription, roleCenters, roleCentersDescription, roleCenter, legalDescription)
{
    roleCenterTitle = roleCenters;
    roleCenterDesc = roleCentersDescription;
    var canvas = document.getElementById("mainCanvas");

    var container = document.createElement('div');
    container.className = "container";
    container.id = "welcomeContainer";
    
    var bottomBorder = document.createElement('div');
    bottomBorder.className = "sectionborder";

    var welcomeDiv = document.createElement('div');
    welcomeDiv.id = "welcomeDivTag";
    welcomeDiv.className = "welcomediv";

    var title = document.createElement('div');
    title.className = "title titlefont";
    var t = document.createTextNode(titletxt);
    title.appendChild(t);

    var br = document.createElement('br');

    var subtitle = document.createElement('div');
    subtitle.className = "subtitle brandPrimary titlefont";
    t = document.createTextNode(subtitletxt);
    subtitle.appendChild(t);

    var explanationdiv = document.createElement('div');
    explanationdiv.id = "expDiv";

    var explanationdesc = document.createElement('div');
    explanationdesc.className = "explanation brandSecondary";
    t = document.createTextNode(explanationtxt);
    explanationdesc.appendChild(t);


    welcomeDiv.appendChild(title);
    welcomeDiv.appendChild(br);
    welcomeDiv.appendChild(subtitle);
    explanationdiv.appendChild(explanationdesc);
    welcomeDiv.appendChild(explanationdiv);

    var welcomeimageDiv = document.createElement('div');
    welcomeimageDiv.className = "welcomeimagediv";

    var imageDiv = document.createElement('div');
    var welcomeImg = document.createElement("img");
    welcomeImg.className = "welcomeimage";
    welcomeImg.id = "welcomePic";
    welcomeImg.alt = "";
    var imageUrl = Microsoft.Dynamics.NAV.GetImageResource('01_welcome.png');
    welcomeImg.src = imageUrl;

    imageDiv.appendChild(welcomeImg);
    welcomeimageDiv.appendChild(imageDiv);

    bottomBorder.appendChild(welcomeDiv);
    bottomBorder.appendChild(welcomeimageDiv);

    container.appendChild(bottomBorder);

    var links = document.createElement('div');
    links.className = "links";
    links.id = "linksDiv";
    
    tile1 = document.createElement('button');
    tile1.className = "tile tilemarginright button";
    tile1.id = "tile1Button";

    var tile1Description = document.createElement('div');
    tile1Description.className = "tileDescription";
    tile1Description.id = "tileDescription1";
    t = document.createTextNode(intro);
    tile1Description.appendChild(t);

    var tile1SubDescription = document.createElement('div');
    tile1SubDescription.className = "segoeRegularfont brandSecondary";
    tile1SubDescription.id = "tileSubDescription1";
    t = document.createTextNode(introDescription);
    tile1SubDescription.appendChild(t);

    var tile1Img = document.createElement("img");
    tile1Img.id = "introductionImg";
    tile1Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('02_introduction.png');
    tile1Img.src = imageUrl;

    tile1.appendChild(tile1Description);
    tile1.appendChild(tile1SubDescription);
    tile1.appendChild(tile1Img);

    tile2 = document.createElement('button');
    tile2.className = "tile tilemarginright button";
    tile2.id = "tile2Button";

    var tile2Description = document.createElement('div');
    tile2Description.className = "tileDescription";
    tile2Description.id = "tileDescription2";
    t = document.createTextNode(getStarted);
    tile2Description.appendChild(t);

    var tile2SubDescription = document.createElement('div');
    tile2SubDescription.className = "segoeRegularfont brandSecondary";
    tile2SubDescription.id = "tileSubDescription2";
    t = document.createTextNode(getStartedDescripion);
    tile2SubDescription.appendChild(t);

    var tile2Img = document.createElement("img");
    tile2Img.id = "outlookImg";
    tile2Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('03_outlook.png');
    tile2Img.src = imageUrl;

    tile2.appendChild(tile2Description);
    tile2.appendChild(tile2SubDescription);
    tile2.appendChild(tile2Img);

    tile3 = document.createElement('button');
    tile3.className = "tile tilemarginright button";
    tile3.id = "tile3Button";

    var tile3Description = document.createElement('div');
    tile3Description.className = "tileDescription";
    tile3Description.id = "tileDescription3";
    t = document.createTextNode(getHelp);
    tile3Description.appendChild(t);

    var tile3SubDescription = document.createElement('div');
    tile3SubDescription.className = "segoeRegularfont tooltip brandSecondary";
    tile3SubDescription.id = "tileSubDescription3";
    tile3SubDescriptionText = getHelpDescription.length > 36 ? getHelpDescription.substring(0,36) + "..." : getHelpDescription;
    t = document.createTextNode(tile3SubDescriptionText);
    tile3SubDescription.appendChild(t);
    var span = document.createElement('span');
    span.className = "tooltiptext";
    span.appendChild(document.createTextNode(getHelpDescription));

    var tile3Img = document.createElement("img");
    tile3Img.id = "extensionsImg";
    tile3Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('04_extensions.png');
    tile3Img.src = imageUrl;

    tile3.appendChild(tile3Description);
    tile3.appendChild(tile3SubDescription);
    tile3.appendChild(tile3Img);

    tile4 = document.createElement('div');
    tile4.className = "tile";
    tile4.id = 'tile4';

    var button = CreateRoleCenterSection();

    tile4.appendChild(button);
    var roleCenterDiv = CreateRoleCenterDiv(roleCenter);
    tile4.appendChild(roleCenterDiv);

    links.appendChild(tile1);
    links.appendChild(tile2);
    links.appendChild(tile3);

    container.appendChild(links);

    links = document.createElement('div');
    links.id = "thumbnailLinksDiv"
    links.className = "links";

    var legalDescriptionDiv = document.createElement('div');
    legalDescriptionDiv.id = 'legalDescriptionDiv';
    legalDescriptionDiv.className = "legalDescription";
    var legalDiv = document.createElement('div');
    legalDiv.className = "segoeRegularfont brandSecondary legalDescriptionHeight";
    legalDiv.id = 'legalDiv';
    t = document.createTextNode(legalDescription);
    legalDiv.appendChild(t);

    legalDescriptionDiv.appendChild(legalDiv);

    links.appendChild(legalDescriptionDiv);

    container.appendChild(links);

    canvas.appendChild(container);

    const welcomeContainer = document.getElementById("welcomeContainer");
    welcomeContainer?.setAttribute('role', 'dialog');
    welcomeContainer?.setAttribute('aria-describedby', 'welcomeDivTag');
    document.getElementById('welcomePic')?.setAttribute('role', 'presentation');
    document.getElementById('tile1Button')?.setAttribute('aria-labelledby', 'tileDescription1 tileSubDescription1');
    document.getElementById('tile2Button')?.setAttribute('aria-labelledby', 'tileDescription2 tileSubDescription2');
    document.getElementById('tile3Button')?.setAttribute('aria-labelledby', 'tileDescription3 tileSubDescription3');
    document.getElementById('legalDescriptionDiv')?.setAttribute('aria-labelledby', 'legalDiv');

    document.getElementById('tile1Button')?.addEventListener("click", () => ThumbnailClick(1));
    document.getElementById('tile2Button')?.addEventListener("click", () => ThumbnailClick(2));
    document.getElementById('tile3Button')?.addEventListener("click", () => ThumbnailClick(3));
}

function ThumbnailClick(id)
{ 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ThumbnailClicked', [id]);
}

function RoleCenterClick()
{ 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('RoleCenterClicked', [1]);
}

function UpdateProfileId(profileId)
{ 
}

function CreateRoleCenterSpan()
{
    var checkboxSpan = document.createElement('span');
    checkboxSpan.className = "checkbox";
    var checkboxImg = document.createElement('img');
    checkboxImg.id = "checkboxImg";
    checkboxImg.alt = "";
    var imageUrl = Microsoft.Dynamics.NAV.GetImageResource('GoChecked.png');
    checkboxImg.src = imageUrl;
    checkboxSpan.appendChild(checkboxImg);
    return checkboxSpan;
}

function CreateRoleCenterSection()
{

    var button = document.createElement('button');
    button.className = "button";
    button.id = "tile4Button";

    var tile4Description = document.createElement('div');
    tile4Description.className = "tileDescription";
    tile4Description.id = "tileDescription4";
    t = document.createTextNode(roleCenterTitle);
    tile4Description.appendChild(t);

    var tile4SubDescription = document.createElement('div');
    tile4SubDescription.className = "segoeRegularfont brandSecondary";
    tile4SubDescription.id = "tileSubDescription4";
    t = document.createTextNode(roleCenterDesc);
    tile4SubDescription.appendChild(t);

    var tile4Img = document.createElement("img");
    tile4Img.id = "roleCenterImg";
    tile4Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('05_rolecenter.png');
    tile4Img.src = imageUrl;

    button.appendChild(tile4Description);
    button.appendChild(tile4SubDescription);
    button.appendChild(tile4Img);
    return button;
}

function CreateRoleCenterDiv(roleCenter)
{
    var roleCentDiv = document.createElement('div');
    roleCentDiv.id = 'roleCenterName';
    roleCentDiv.className = "segoeRegularfont brandPrimary truncate";
    
    var checkboxSpan = CreateRoleCenterSpan();
    roleCentDiv.appendChild(checkboxSpan);
    
    t = document.createTextNode('  ' + roleCenter);
    roleCentDiv.appendChild(t);
    return roleCentDiv;
}

// SIG // Begin signature block
// SIG // MIInRwYJKoZIhvcNAQcCoIInODCCJzQCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // kV1etgwleoKHKwp66IfAmvy7sPIrIZaCpmpk/RmM6zCg
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
// SIG // SIb3DQEJBDEiBCDgtUrUZscocORzQa6eBEy1rgSQmYvV
// SIG // rCoMR6mTklEl0jBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAMWg
// SIG // px7bDxs0tAPemJUT0zieM3DlwLHiR/06zQ7z/i/FJLp2
// SIG // ovgSLz/3trt6DZGlKjW8uEbjMqBs9iOMNcOL758cIpnL
// SIG // 7AmycYTK+tDg808qW783xbOFooAi65qvOq4GE3aD9Dyc
// SIG // ig61dpVxGBCeQrZfbCBnDVeB6qNXIHC7LLEtCgyODJsO
// SIG // uQiVk2ro02jNROhReLMRO9sNWAWx1oV9ETwraz/gCtxJ
// SIG // munrA18zfMrfIEuZHq0a18SGjPuZg64tXokAqy+x0LRA
// SIG // czFoywWs7pEoSBwW3IVyOXIgQdeP5uYgGUpNtPJjLvZt
// SIG // iEogn+9OIYOdSIFGhf+FwbLb+Giq0vChgheXMIIXkwYK
// SIG // KwYBBAGCNwMDATGCF4Mwghd/BgkqhkiG9w0BBwKgghdw
// SIG // MIIXbAIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQgw/5lPpKpJKo8kG+D
// SIG // qzIQqBXu+xvmaHo7qwuP5b4r9+YCBmoXUQ3VexgTMjAy
// SIG // NjA2MDExNDU3MjkuMTgyWjAEgAIB9KCB0aSBzjCByzEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
// SIG // b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
// SIG // blNoaWVsZCBUU1MgRVNOOjk2MDAtMDVFMC1EOTQ3MSUw
// SIG // IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
// SIG // aWNloIIR7TCCByAwggUIoAMCAQICEzMAAAImNbQ+Z0OT
// SIG // 9h8AAQAAAiYwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTk0MDAy
// SIG // WhcNMjcwNTE3MTk0MDAyWjCByzELMAkGA1UEBhMCVVMx
// SIG // EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
// SIG // ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
// SIG // dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
// SIG // T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
// SIG // RVNOOjk2MDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNy
// SIG // b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv/8PmWSC+URR
// SIG // aVSPA92crjbvCM3ABDg99Di2I4d9+6143KyJTks6SXOG
// SIG // XlMRMpYusehes5uDUfHWz2/XYg6f4TlMx1hsYgNWd0Vy
// SIG // gW/+Bf6I8rzeN0hBlqkn1XNyNwZbGE9+XnFQCfZFX/dG
// SIG // Dr9vbRYyQQWZGL60/w8MMkS7HDsj+Kfvf5ciYw/lC7N2
// SIG // FwYVa32fjG0AfgWCi6kbwSm4/8EfWpDazMUCDaBmg+Y2
// SIG // Tvzf50rJhtj9c7/3L+IEqDAZ1nkCAZI3diOcNQ3l7qad
// SIG // r0ojZkebANmZASt8okFmib0cTg5ZH4sh5PTJJP062E45
// SIG // ozwm4XvrqoRzUcvFJWzr1rAqtLUbVMpB79/Q4KgHyTax
// SIG // PDkrfN+awcw6a63AIcJoH4aFYuACnqsIpGNJ1GuPCtEM
// SIG // vNF0+H4hANxMRGTWkRaPTavxsG34KiqhpnPcYSrkRXI7
// SIG // bmuCh2b5wL6VoBBUjgpKL17PwXC55BBzPcWfIlGoOQso
// SIG // Tal2GBP89KXF3WGjSJEOvBFprry5u4PaKH1drzpuRlTa
// SIG // IIZ5Fhupxj6PycBIJgPaEktBH7xUTFjwP4KUrxd7IQKy
// SIG // h52hKVUkotwzW8ormIhLPSqNCJGXPMShXkEWqhkcawft
// SIG // q/+wd1/NU6bPfSoRcIPsA/O6HdthdjFINce7cLd4GlZx
// SIG // ZNCGSMFDwhsCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBRd
// SIG // 4Z/X2CTdmP2fS1WwTyMQM1x7EDAfBgNVHSMEGDAWgBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
// SIG // UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
// SIG // UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
// SIG // MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
// SIG // bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
// SIG // HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
// SIG // MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
// SIG // AgEANlMdLa/bGAo7KtBUcolacdeTrqzV7+kJO4l/gK1T
// SIG // 5c98OLao3EzZtXbd7U7mtsCTKSYTx/J+1F4Zk/fHeQ7u
// SIG // OC5eGnZ7HuEkH1YN0C+mkZFx5yVJ/MvYn7Qfz8ttp/cZ
// SIG // 8DxX490JQzkoC7h5Xrve1NIh9mWpbmGm1lyYoXYmKSvH
// SIG // DxxZamTgIqLdPhg/HT/kTLr6cbfxdi5mHpaaGcK4ohTl
// SIG // JpcRFFe8SR8mWZQ6rrJHsrqtNQ07/dTeKjPHHzz4Zf9q
// SIG // XOB3jH/53dh6LonyWw0BTXeFj4S859Est7tWYd/kt7Y0
// SIG // HajfncsOtEWlfkVwqDi4BWdzAIPxqA5fn72+Ycv9Wu9X
// SIG // LV/MBGndT3+nXn9qan5d8BXPvoZBfA1102aHyTeGFWjd
// SIG // yJ8GwBkAw5DSuJannAoscZkisInT8pxnhOTrbzaCtaZC
// SIG // 7Jv4vBdUYxnM2f5EhdlQ5KhvOuokPo1WxjkOg7t3sshX
// SIG // BSmaAyeAeZhAEvWk9kiqpZS3smzm6B+q+u7IkeQf9h57
// SIG // u/imLmGctARGnbQOp4BuHJ0kfSbK5IYbCpm9dbo6sICc
// SIG // jcfdjLKBhsDYDdWiNECA/ArIwhcKX5jM5QOOMRymL94Z
// SIG // o8XqgUuLlOa0HogJ1YKSXmlRipv5czw7Z6aRlfu14Uae
// SIG // W9WcU/2e18XPiOx+/4wrUA2aGmUwggdxMIIFWaADAgEC
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
// SIG // BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5NjAwLTA1RTAt
// SIG // RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
// SIG // bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAov3zMRbZ
// SIG // Kq+1zF3bEcllNJUih2eggYMwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIF
// SIG // AO3HvbYwIhgPMjAyNjA2MDEwODEzNDJaGA8yMDI2MDYw
// SIG // MjA4MTM0MlowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA
// SIG // 7ce9tgIBADAKAgEAAgIeaQIB/zAHAgEAAgITzjAKAgUA
// SIG // 7ckPNgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
// SIG // AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0G
// SIG // CSqGSIb3DQEBCwUAA4IBAQCSEUpQt7wmXxasKzfKtp99
// SIG // hA746PetsvR5KbCVZCR0RCPOzHVO8SG1jibec5LpgPfk
// SIG // p/G3iHMupAQZcwzk/N13EKLLjbN6h2Bo3yuvfG/M8bwY
// SIG // 7pQCq7dpmU9FahXqNOXuLR64YJWZqHXzvfebNfYP4hSZ
// SIG // hvnQu3zJW0RgtU8KPEfbTQZlmIszThmoBfVn1Wy6k4Xs
// SIG // aaakkUqydAEpkD2UkS//ibAaUlCynWITD40RERkpTE3b
// SIG // 9V9xkq8EwcwLazos2Ubt6Y3Y0KCBHZtL22rxCJ6tIotL
// SIG // NY/GFgNNbGBXqe5wOSKyt0USCH4iBTyRUWdDRHyElcmN
// SIG // wqPoO+gSxLmOMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTACEzMAAAImNbQ+Z0OT9h8A
// SIG // AQAAAiYwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3
// SIG // DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
// SIG // IgQgBjf1ozcxjYuL69o5OgWZMzRdEco+PC79UVrI3cAi
// SIG // h+cwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDM
// SIG // MlxhZ0zbGUQa7OhjfwW1dKJGjT91QWKixY1LBZ24KjCB
// SIG // mDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
// SIG // YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
// SIG // VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
// SIG // BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
// SIG // AhMzAAACJjW0PmdDk/YfAAEAAAImMCIEIPVrGKNM+CDq
// SIG // 5qPZA3IBzV2O4neFWHHQt2OOJeTrzz5oMA0GCSqGSIb3
// SIG // DQEBCwUABIICACxKk5QvfMp2zUJKAOdEkCz/F+3G5bzF
// SIG // MYRbRL7WldAP7FkY7ZQnCii6LSH1gf+k0AbU3yjNr4o/
// SIG // T8s5prOqTPGuvuqKfhCQMJV1stCZo1uY8OKBiuwwrkBG
// SIG // ++S3Em8mJF4EVPXdmxTJctfF7XNJH3FJl+RUvyoLKRlm
// SIG // a2N3eLdVGEMmpHb179oydCvsc3os0M97XH7RiNX0Tie/
// SIG // e3/O4nAXOs7wC0hfqG96epZ0knsfZCB8OAda9oHY7nkW
// SIG // 1mbeucYqOfSCveZZMrwyCO5KovVnskfEGRuPa+GKfIXK
// SIG // MVT+LpVzrs28BQM/h8tc/ZslDudcySOj5Ii0ltOpo6U4
// SIG // y5HEEZZdCWh+8qfxU+ZFIvqxTyBG0K/SfKpsS9ug2ks6
// SIG // ayKvU/vaibrgQXwIUjiR/3k90ZksFRmj2zCK/2zwFbF+
// SIG // FLpChrdI7BpDr9KoOdSUcq6jt9HXZKTQ4z1BSXFXUl+G
// SIG // TNgS6uCDXQbImI9ZDAlhIBvRL68Wu9qotfRx7fhWltus
// SIG // yFVPpL3gAXqF+DvVoODbkmBT5b0JPpaQL+AsTdPU4LHJ
// SIG // snLnRcB3blGOehr1BXRoWlospK+gX6yYSvUOQfOy2zgT
// SIG // IhDob/u5UaPPFySnp3GspwTrF/seDNYQoYVkBkeTtDF5
// SIG // MXw/2IWlB0uy6Wv4aWjesjxxUT6eU0Qh5GJj
// SIG // End signature block
