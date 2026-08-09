var jsonContent;
var jsonPageData;
var actionLabel;
var pageDescription;
var disclaimerText;
var currentProfileId;
var currentSelectedIndex;

function LoadRoleCenterFromJson(jsonText){
    jsonContent = JSON.parse(jsonText);
    DrawFeatureContent();
}

function LoadPageDataFromJson(jsonText){
    jsonPageData = JSON.parse(jsonText);
    DrawPage();
} 

function GetCurrentProfileId(profileId){
    profileId = currentProfileId;
    return currentProfileId;
}

function SelectDropdownItem(index) {
    var dropdownItems = document.getElementById("select");
    for (var i = 0; i < dropdownItems.options.length; ++i) {
        if (dropdownItems.options[i].value == index.toString()) {
            dropdownItems.options[i].selected = true;
        }
    }
}

function SetCurrentProfileId(ProfileId) {
    currentProfileId = ProfileId;
    var index = jsonPageData.DropContent.map(function (d) { return d['Name']; }).indexOf(currentProfileId);
    currentSelectedIndex = index;

    SelectDropdownItem(currentSelectedIndex);
}

function DrawPage() {
    DrawCanvas();
    DrawDropdown();
    DrawFooter();
}

function ReplaceFeaturesContent() {
    document.getElementById("featuretable")?.remove();
    InsertFeaturesContent();
}

function InsertFeaturesContent() {
    var features = jsonContent;

    var tableDiv = document.createElement("div");
    tableDiv.className = "tableDiv";
    tableDiv.id = "featuretable";

    var table = document.createElement("table");
    table.className = "ms-Table ms-Table--fixed";
    tableDiv.appendChild(table);

    var thead = document.createElement("thead");
    table.appendChild(thead);
    var theadRow = document.createElement("tr");
    thead.appendChild(theadRow);

    for (var i = 0; i < features.length; i++) {
        var th = document.createElement("th");
        th.className = "tableheader ms-fontSize-mPlus ms-fontWeight-semibold";
        var callOutDiv = document.createElement("div");
        callOutDiv.textContent = features[i].name;
        th.appendChild(callOutDiv);
        theadRow.appendChild(th);
    }

    var expand = true;
    var index = 0;
    var tbody = document.createElement("tbody");
    table.appendChild(tbody);

    while (expand) {
        expand = false;
        var tRow = document.createElement("tr");
        tbody.appendChild(tRow);
        for (var j = 0; j < features.length; j++) {
            var td = document.createElement("td");
            if (index < features[j].rows.length) {
                expand = true;
                td.className = "type2 ms-fontSize-m ms-fontWeight-regular";
                callOutDiv = CreateCalloutElement(features[j].rows[index].name, features[j].rows[index].tooltip, j + 4, 'td' + index + j);
                td.appendChild(callOutDiv);
            }
            tRow.appendChild(td);
        }
        index++;
    }
        
    var pageHeader = document.getElementById("pageheader");
    pageHeader.parentNode.insertBefore(tableDiv, pageHeader.nextSibling);

    var Callouts = document.querySelectorAll(".msCalloutDiv");
    for (var k = 0; k < Callouts.length; k++) {
        var callout = Callouts[k];
        var CalloutTriggerElement = callout.querySelector(".calloutlabeldiv .calloutspandiv");
        var CalloutElement = callout.querySelector(".ms-Callout");
        new fabric['Callout'](
            CalloutElement,
            CalloutTriggerElement,
            "right"
        );
    }
}

function DrawFeatureContent() {
    if (document.getElementById("featuretable") != null) {
        ReplaceFeaturesContent();
    }
    else {
        InsertFeaturesContent();
    }
}

function DrawCanvas()
{
    document.getElementById("controlAddIn").innerHTML = "";

    var canvas = document.createElement('div');
    canvas.className = "mainCanvas";
    canvas.id = "mainCanvas";
    document.getElementById("controlAddIn").appendChild(canvas);
}

function OnChangeSelection()
{
    var selectedValue = document.getElementById("select").value;
    currentSelectedIndex = parseInt(selectedValue);
    currentProfileId = jsonPageData.DropContent[selectedValue].Name;
    SetCurrentProfileId(currentProfileId);
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnProfileSelected', [currentProfileId]);
}
function DrawDropdown() {
    var canvas = document.getElementById("mainCanvas");

    var headerDiv = document.createElement("div");
    headerDiv.className = "header";
    headerDiv.id = "pageheader";
    canvas.appendChild(headerDiv);

    var titleLabel = document.createElement("label");
    titleLabel.className = "ms-Label";
    titleLabel.id = "dropdownLabel";
    titleLabel.textContent = jsonPageData.HeaderLabel;
    headerDiv.appendChild(titleLabel);

    var dropDownDiv = document.createElement("div");
    dropDownDiv.className = "ms-Dropdown";
    headerDiv.appendChild(dropDownDiv);
    var select = document.createElement("select");
    select.id = "select";
    select.tabIndex = 3;
    select.setAttribute("onChange", "OnChangeSelection()");
    select.setAttribute("aria-labelledby", "dropdownLabel");

    for (var i = 0; i < jsonPageData.DropContent.length; i++) {
        var option = document.createElement("option");
        option.value = i;
        option.text = jsonPageData.DropContent[i].Description;
        select.options.add(option);
    }
    dropDownDiv.appendChild(select);

    //var desc = document.createElement("label");
    //desc.className = "ms-Label";
    //desc.id = "actiondesc";
    //desc.textContent = jsonPageData.ActionDescription;
    //headerDiv.appendChild(desc);

    var button = document.createElement("button");
    button.className = "ms-Button";
    button.setAttribute("aria-labelledby", "actiondesc");
    button.tabIndex = 4;
    headerDiv.appendChild(button);

    var buttonSpan = document.createElement("span");
    buttonSpan.className = "ms-Button-label";
    buttonSpan.textContent = jsonPageData.DefaultActionLabel;
    button.appendChild(buttonSpan);

    button.addEventListener("click", function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnAcceptAction', null);
    });
}

function DrawFooter()
{
    var canvas = document.getElementById("mainCanvas");
    var footer = document.createElement("div");
    footer.className = "footer";
    footer.id = "footer";
    canvas.appendChild(footer);

    var messageBar = document.createElement("div");
    messageBar.className = "ms-MessageBar ms-MessageBar--warning";

    var messageBarContent = document.createElement("div");
    messageBarContent.className = "ms-MessageBar-content";

    var messageBarIconDiv = document.createElement("div");
    messageBarIconDiv.className = "ms-MessageBar-icon";

    var messageBarIcon = document.createElement("i");
    messageBarIcon.className = "ms-Icon ms-Icon--Important";

    messageBarIconDiv.appendChild(messageBarIcon);

    var messageBarText = document.createElement("div");
    messageBarText.className = "ms-MessageBar-text";
    messageBarText.textContent = jsonPageData.DisclaimerText;

    messageBarContent.appendChild(messageBarIconDiv);
    messageBarContent.appendChild(messageBarText);

    messageBar.appendChild(messageBarContent);

    footer.appendChild(messageBar);
}

/*
<div class="msCalloutDiv">
    <div class="ms-Callout is-hidden">
        <div class="ms-Callout-main">
            <div class="ms-Callout-header">
                <p class="ms-Callout-title">All of your favorite people</p>
            </div>
            <div class="ms-Callout-inner">
                <div class="ms-Callout-content">
                    <p class="ms-Callout-subText ms-Callout-subText--">tooltip.</p>
                </div>
            </div>
        </div>
    </div>
    <div class="calloutlabeldiv">
        <div class="calloutspandiv">
            <a>Open Callout</a>
        </div>
    </div>
</div>
*/
function CreateCalloutElement(featureName, featureDescription, tabIndex, cellId) {
    var callOutDiv = document.createElement("div");
    callOutDiv.className = "msCalloutDiv";

    var callOutWnd = document.createElement("div");
    callOutWnd.className = "ms-Callout is-hidden";

    var callOutMain = document.createElement("div");
    callOutMain.className = "ms-Callout-main";

    var callOutHdr = document.createElement("div");
    callOutHdr.className = "ms-Callout-header";

    var callOutTitle = document.createElement("p");
    callOutTitle.className = "ms-Callout-title";
    callOutTitle.innerText = featureName;
    
    var callOutInner = document.createElement("div");
    callOutInner.className = "ms-Callout-inner";

    var callOutcontent = document.createElement("div");
    callOutcontent.className = "ms-Callout-content";

    var callOutSubtext = document.createElement("p");
    callOutSubtext.className = "ms-Callout-subText";
    callOutSubtext.innerText = featureDescription;
    callOutSubtext.id = cellId;
    
    callOutHdr.appendChild(callOutTitle);
    callOutcontent.appendChild(callOutSubtext);
    callOutInner.appendChild(callOutcontent);
    callOutMain.appendChild(callOutHdr);
    callOutMain.appendChild(callOutInner);
    callOutWnd.appendChild(callOutMain);

    var callOutlabelDiv = document.createElement("div");
    callOutlabelDiv.className = "calloutlabeldiv";

    var callOutButton = document.createElement("div");
    callOutButton.className = "calloutspandiv";

    var callOutButtonSpan = document.createElement("a");
    callOutButtonSpan.innerText = featureName;
    callOutButtonSpan.setAttribute("aria-describedby", cellId);
    callOutButtonSpan.tabIndex = tabIndex;
    callOutButton.appendChild(callOutButtonSpan);
    callOutlabelDiv.appendChild(callOutButton);
    callOutDiv.appendChild(callOutWnd);
    callOutDiv.appendChild(callOutlabelDiv);

    return callOutDiv;
}

// SIG // Begin signature block
// SIG // MIInQwYJKoZIhvcNAQcCoIInNDCCJzACAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // sYzqhqwdwpyloNN6emwWHzVhmLuDucBgHHmd3fwWmYOg
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
// SIG // JkDeVuJ9dNXGNi+AOxk0BtYd9hxwL30BElj9MYIZ4TCC
// SIG // Gd0CAQEwbjBXMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9N
// SIG // aWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDI0AhMz
// SIG // AAACHU0ZyE7XD1dIAAAAAAIdMA0GCWCGSAFlAwQCAQUA
// SIG // oIGuMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
// SIG // CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
// SIG // SIb3DQEJBDEiBCCwGQ12lE6agalcLQr793Xx9TqMahj8
// SIG // 8X+dV5QGZWoxPjBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAMDF
// SIG // +QTNPLLVoePFPE+jHGvBRH/SXCIiKXfYLsnTzI75HIHO
// SIG // rG1cYrgLVS6pQPkVATOVuHWfPq42UCOu1OzXMsUiDq5k
// SIG // 3cb+IFuTWWsT3ZFPjKS699ctknXE2qqNAQYSmuasJl6/
// SIG // tLoDoX+5s+eJe2Uio3gAVtd2MvtkrJGDDEZpUIvzYOgd
// SIG // SGY+EKFq/aN94SgwTMej+rsTE1XAqGGHzBhZ+791aVR/
// SIG // 5IelAcC13soQk9muB4aHs9UsM4xg1FjMi9wxFYy3h3M7
// SIG // dO5IFX03MNi3xXFYchK5II+PiQjh9Tc/Xnp1V82TFXPJ
// SIG // TpKkNGvsORjBDCd8je5qhx8Mxu16UGKhgheTMIIXjwYK
// SIG // KwYBBAGCNwMDATGCF38wghd7BgkqhkiG9w0BBwKgghds
// SIG // MIIXaAIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUQYLKoZI
// SIG // hvcNAQkQAQSgggFABIIBPDCCATgCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQgvvkr7X9fYHaAF2Je
// SIG // GmpFFaEKTXChgamxxN+a92cYaI8CBmoxtwcvWBgSMjAy
// SIG // NjA3MDIxNzM3MTYuODlaMASAAgH0oIHRpIHOMIHLMQsw
// SIG // CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
// SIG // MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
// SIG // b2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3Nv
// SIG // ZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5u
// SIG // U2hpZWxkIFRTUyBFU046OTYwMC0wNUUwLUQ5NDcxJTAj
// SIG // BgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZp
// SIG // Y2WgghHqMIIHIDCCBQigAwIBAgITMwAAAiY1tD5nQ5P2
// SIG // HwABAAACJjANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDAeFw0yNjAyMTkxOTQwMDJa
// SIG // Fw0yNzA1MTcxOTQwMDJaMIHLMQswCQYDVQQGEwJVUzET
// SIG // MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
// SIG // bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
// SIG // aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBP
// SIG // cGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBF
// SIG // U046OTYwMC0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jv
// SIG // c29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqG
// SIG // SIb3DQEBAQUAA4ICDwAwggIKAoICAQC//w+ZZIL5RFFp
// SIG // VI8D3ZyuNu8IzcAEOD30OLYjh337rXjcrIlOSzpJc4Ze
// SIG // UxEyli6x6F6zm4NR8dbPb9diDp/hOUzHWGxiA1Z3RXKB
// SIG // b/4F/ojyvN43SEGWqSfVc3I3BlsYT35ecVAJ9kVf90YO
// SIG // v29tFjJBBZkYvrT/DwwyRLscOyP4p+9/lyJjD+ULs3YX
// SIG // BhVrfZ+MbQB+BYKLqRvBKbj/wR9akNrMxQINoGaD5jZO
// SIG // /N/nSsmG2P1zv/cv4gSoMBnWeQIBkjd2I5w1DeXupp2v
// SIG // SiNmR5sA2ZkBK3yiQWaJvRxODlkfiyHk9Mkk/TrYTjmj
// SIG // PCbhe+uqhHNRy8UlbOvWsCq0tRtUykHv39DgqAfJNrE8
// SIG // OSt835rBzDprrcAhwmgfhoVi4AKeqwikY0nUa48K0Qy8
// SIG // 0XT4fiEA3ExEZNaRFo9Nq/GwbfgqKqGmc9xhKuRFcjtu
// SIG // a4KHZvnAvpWgEFSOCkovXs/BcLnkEHM9xZ8iUag5CyhN
// SIG // qXYYE/z0pcXdYaNIkQ68EWmuvLm7g9oofV2vOm5GVNog
// SIG // hnkWG6nGPo/JwEgmA9oSS0EfvFRMWPA/gpSvF3shArKH
// SIG // naEpVSSi3DNbyiuYiEs9Ko0IkZc8xKFeQRaqGRxrB+2r
// SIG // /7B3X81Tps99KhFwg+wD87od22F2MUg1x7twt3gaVnFk
// SIG // 0IZIwUPCGwIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFF3h
// SIG // n9fYJN2Y/Z9LVbBPIxAzXHsQMB8GA1UdIwQYMBaAFJ+n
// SIG // FV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBS
// SIG // oFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
// SIG // cHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQ
// SIG // Q0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
// SIG // XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
// SIG // LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGlt
// SIG // ZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1Ud
// SIG // EwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgw
// SIG // DgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IC
// SIG // AQA2Ux0tr9sYCjsq0FRyiVpx15OurNXv6Qk7iX+ArVPl
// SIG // z3w4tqjcTNm1dt3tTua2wJMpJhPH8n7UXhmT98d5Du44
// SIG // Ll4adnse4SQfVg3QL6aRkXHnJUn8y9iftB/Py22n9xnw
// SIG // PFfj3QlDOSgLuHleu97U0iH2ZaluYabWXJihdiYpK8cP
// SIG // HFlqZOAiot0+GD8dP+RMuvpxt/F2LmYelpoZwriiFOUm
// SIG // lxEUV7xJHyZZlDquskeyuq01DTv91N4qM8cfPPhl/2pc
// SIG // 4HeMf/nd2HouifJbDQFNd4WPhLzn0Sy3u1Zh3+S3tjQd
// SIG // qN+dyw60RaV+RXCoOLgFZ3MAg/GoDl+fvb5hy/1a71ct
// SIG // X8wEad1Pf6def2pqfl3wFc++hkF8DXXTZofJN4YVaN3I
// SIG // nwbAGQDDkNK4lqecCixxmSKwidPynGeE5OtvNoK1pkLs
// SIG // m/i8F1RjGczZ/kSF2VDkqG866iQ+jVbGOQ6Du3eyyFcF
// SIG // KZoDJ4B5mEAS9aT2SKqllLeybOboH6r67siR5B/2Hnu7
// SIG // +KYuYZy0BEadtA6ngG4cnSR9JsrkhhsKmb11ujqwgJyN
// SIG // x92MsoGGwNgN1aI0QID8CsjCFwpfmMzlA44xHKYv3hmj
// SIG // xeqBS4uU5rQeiAnVgpJeaVGKm/lzPDtnppGV+7XhRp5b
// SIG // 1ZxT/Z7Xxc+I7H7/jCtQDZoaZTCCB3EwggVZoAMCAQIC
// SIG // EzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZIhvcNAQEL
// SIG // BQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMT
// SIG // KU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
// SIG // cml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkz
// SIG // MDE4MzIyNVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
// SIG // Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
// SIG // BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
// SIG // A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
// SIG // MTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
// SIG // AQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXI
// SIG // yjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2
// SIG // Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPFdvWG
// SIG // UNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8d
// SIG // q6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/P
// SIG // XfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBpDco2LXCO
// SIG // Mcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnop
// SIG // N6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+
// SIG // cakXW2dg3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW/aUg
// SIG // fX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj
// SIG // 0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9
// SIG // Q07BMzlMjgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2
// SIG // AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU
// SIG // 2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6
// SIG // r1AFemzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1
// SIG // Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkw
// SIG // EgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIE
// SIG // FgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYE
// SIG // FJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARVMFMw
// SIG // UQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0
// SIG // dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9j
// SIG // cy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEF
// SIG // BQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
// SIG // BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
// SIG // HSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNV
// SIG // HR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29m
// SIG // dC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJB
// SIG // dXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBM
// SIG // MEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEw
// SIG // LTA2LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9
// SIG // /Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0x
// SIG // M7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZn
// SIG // OlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++
// SIG // Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449xvNo
// SIG // 32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5
// SIG // KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3D
// SIG // YXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7
// SIG // T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+
// SIG // CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2z
// SIG // AVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77
// SIG // IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFh
// SIG // bHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGE
// SIG // vL8CwYKiexcdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4
// SIG // JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEz
// SIG // fbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDB
// SIG // cQZqELQdVTNYs6FwZvKhggNNMIICNQIBATCB+aGB0aSB
// SIG // zjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMc
// SIG // TWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUG
// SIG // A1UECxMeblNoaWVsZCBUU1MgRVNOOjk2MDAtMDVFMC1E
// SIG // OTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
// SIG // cCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQCi/fMxFtkq
// SIG // r7XMXdsRyWU0lSKHZ6CBgzCBgKR+MHwxCzAJBgNVBAYT
// SIG // AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
// SIG // EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
// SIG // cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
// SIG // LVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA
// SIG // 7fCiiDAiGA8yMDI2MDcwMjA4NDA0MFoYDzIwMjYwNzAz
// SIG // MDg0MDQwWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDt
// SIG // 8KKIAgEAMAcCAQACAgRKMAcCAQACAhPDMAoCBQDt8fQI
// SIG // AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkK
// SIG // AwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
// SIG // hvcNAQELBQADggEBAEfiGLH2mwSBSpkN+C1j6eC8I2Yf
// SIG // g2maUL1TOaWli59ZNj8hbk62XXLmsPqSMJHgTYAB9+IF
// SIG // XdA3iGuUcz3pikZ4cIHVWCTFRl/fgKd2ASxIIJMzyU6M
// SIG // tNyMX6DDQWo+84u8woHBqzvLz66FkFWPHikLfvx7bf/B
// SIG // bnoKoB5OMAiHEEDOnPbb8U/CqT79TTh40Yyv0zp1Uu7x
// SIG // m8HBBxMbBzm7WmIYx8gSXy258r+dkr8nQpNd2ORh2f69
// SIG // UdfOkw5ZMgxIOoFP/sAP63lS1nIbhtJSDwUU9inlrBUY
// SIG // bxTmXC9Te4WK6xzic95dps5Q4s/R6NuaY4QKYLg3QZ33
// SIG // zfbKB8YxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJV
// SIG // UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
// SIG // UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
// SIG // cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
// SIG // dGFtcCBQQ0EgMjAxMAITMwAAAiY1tD5nQ5P2HwABAAAC
// SIG // JjANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkD
// SIG // MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCC/
// SIG // A/gR7ZVKXdOHQZ+V3CAScWmM0H4ENySt55MQKCOyPTCB
// SIG // +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIMwyXGFn
// SIG // TNsZRBrs6GN/BbV0okaNP3VBYqLFjUsFnbgqMIGYMIGA
// SIG // pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
// SIG // TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
// SIG // AAImNbQ+Z0OT9h8AAQAAAiYwIgQg5FbQKrNDZTIznRVU
// SIG // y9X8mLIWek0rFJfv886GmVz8oBEwDQYJKoZIhvcNAQEL
// SIG // BQAEggIALn8pcoobyrmzL4L80fGBLYYpcIXAiQuFLsZk
// SIG // cgKhwB+RaLvFksuJCNSOThdNczSkQWDJYcnnYggg+4Nr
// SIG // SSRdIK7c2BOk/xLW1XK7LqNDjxqRRc/5bGAAga1gY0ma
// SIG // AqhAf5TLb2MXvj5ATQ+5B4zfeVc087AOGaNEo0H/5XOd
// SIG // 7wq8c5fUbADWG65CVQbZwJgUpaMXMiqQBCXBGamgGVrE
// SIG // AWrZ8e/pbEav8XsJ8A0mvkORnyhpwpLjGffPCvRgGG4Z
// SIG // enJa6i3INUkA/ja/jCpo1gQDQbjfqHM/AL2dDTcU9QTE
// SIG // BGCf4HAvg0AfGpiesqCzeftCI2zF77+7FMECuOwEQ625
// SIG // uP7t3MapDqzivovV6ib4ZEUfSnkVwRJGduSiwbxY1Gnp
// SIG // QDCoFkwSP7vzBMAnCzqMtN25QsnINZhHwtibOr63Cf/g
// SIG // Ppv0VVo5BMZ8NZxoj3eP7Mi//KSTLJkV2Nzw0dcm+mMd
// SIG // kJx9ualAdtauAXzOaraOF5X2tlLIXXpDF7f0ftM7CGqE
// SIG // 7PBuLKDN/P7S5qLlmIhekX8HRBonaVDkq4L7yXYRVJpx
// SIG // fQYbwX4DOv1d4g1612NmyA7WDEufVsgK7HSuDXyxvHOy
// SIG // Q2/QrVHURJM/pixUalkikGxC6DmmUMcrR6/XMWbMgLyJ
// SIG // ILswpveTodYAgVticTfn9KLAT81H1i4=
// SIG // End signature block
