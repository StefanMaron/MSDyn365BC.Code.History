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
// SIG // MIInRAYJKoZIhvcNAQcCoIInNTCCJzECAQExDzANBglg
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
// SIG // JkDeVuJ9dNXGNi+AOxk0BtYd9hxwL30BElj9MYIZ4jCC
// SIG // Gd4CAQEwbjBXMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
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
// SIG // TpKkNGvsORjBDCd8je5qhx8Mxu16UGKhgheUMIIXkAYK
// SIG // KwYBBAGCNwMDATGCF4Awghd8BgkqhkiG9w0BBwKgghdt
// SIG // MIIXaQIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQgvvkr7X9fYHaAF2Je
// SIG // GmpFFaEKTXChgamxxN+a92cYaI8CBmnnXh8P2hgTMjAy
// SIG // NjA1MDExNzA1MzIuMTkxWjAEgAIB9KCB0aSBzjCByzEL
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
// SIG // AO2fCfYwIhgPMjAyNjA1MDExMTE2MDZaGA8yMDI2MDUw
// SIG // MjExMTYwNlowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA
// SIG // 7Z8J9gIBADAHAgEAAgIuUjAHAgEAAgISfDAKAgUA7aBb
// SIG // dgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZ
// SIG // CgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqG
// SIG // SIb3DQEBCwUAA4IBAQA2R1WNGS+Yp4cz8cuajU+s4xg8
// SIG // IX50RtFzdmhiWHylNLZZ5AFBYzROnevd73ha5Rh09ZMN
// SIG // GXuV3ucHxIx0x5cnuJHmczYcrrQrLD5FPooZsH+uDOWu
// SIG // YLBtnAR1TmemVR7iu+xP9lZ2R3mQwf7zBJHpPVu1OV+N
// SIG // nI81cK0JojPswVHxCSYl9uwOk8wc+TDhRhBFkgFw+SlF
// SIG // iYrccBQcshYsEH1CeZQbSVBabmrdxQaldeSD7zj7lYUT
// SIG // ht36cetdX7YEudAyY53nZP86g+UmJnTZgoh3nnMNBisK
// SIG // NoGc8suDrArQ/uMxGaujrj5Sffl0Auw1E4Htg0OMYJT1
// SIG // VJMfGUDFMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTACEzMAAAIo8KWH1/PIHkAAAQAA
// SIG // AigwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
// SIG // AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
// SIG // 91rTUsTU/pUiRqRpZhRZmy7vkBS3mw0/SAC0juI8jVow
// SIG // gfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBVsYpG
// SIG // UWBjX+KBFWStXk+OR/txkN/6sVe+VcLgbfoi1zCBmDCB
// SIG // gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
// SIG // HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
// SIG // AAACKPClh9fzyB5AAAEAAAIoMCIEICa+K4jo1ZXQtsAe
// SIG // hSn2WIEduW+PyfkzEbth+oNiljrTMA0GCSqGSIb3DQEB
// SIG // CwUABIICAID491EUIjdt/NuulyTzt2bWgzG9A8PTs0+R
// SIG // DBQDMH1Fjvc+20OeYdP45dkk2qy0LLTzhYLIxDap0lDk
// SIG // 3HiynYsjoYtk/WQJELp807LfxQucH/KyuT9ne9f1B0gr
// SIG // w1+r1zzJo0Ce6LExAieFHpDL1CG9mGZMbKyelWtIXSsh
// SIG // ONGKNYTSO6XSJQ+hu2nIfE00VPIQUJbjR17pYq9DG2Yj
// SIG // VSyniF8ebbDdQXxSNFuuSavtYZAkxmDzbMyjvtNpPcse
// SIG // tOkbBgiEzN+t7BpYVEKlPtsHmb8lkllpTOndHlYsqBZn
// SIG // MCCFyEPR/xmPZoUTqf9l779XU/GM7ajc2kRTFWOE3d8y
// SIG // DyQt2X5SLSQSdoUOI7c3CGnLldftEVtIpzGw6OKSa+48
// SIG // FNDcSMMTU0Fs/+YmBpl8DW8uvzOBRyhdG3ropKTEOHnq
// SIG // wXceiImjNdYjWuZ13OXVQVpXvkJS8UYxlWBgG6fl2hi3
// SIG // OAunL1aWx7AaCeVHke1i4TNxvXGggL35vDChQS+yBM7M
// SIG // c0iKJ+HKkL7kiGmg9r59ncJ9eCpa8mZ9+n0OOROCjT/e
// SIG // Bts5IMRd3P/jXVwKuPCtJgt4y+SwHUKd30WBBUiVBoVw
// SIG // ueLndq+uNs/p4alJyQFiPQBAhCxV+Xhxe+UBkr+uouxr
// SIG // uHYby4sisEu2wQWMrFau5EtTAScP0bkX
// SIG // End signature block
