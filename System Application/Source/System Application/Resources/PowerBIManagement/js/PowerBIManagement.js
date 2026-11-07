/*! Copyright (C) Microsoft Corporation. All rights reserved. */
"use strict";

/*!-----------------------------------------------------------------------------------------------------------
|    This addin uses the PowerBI SDK to create an embedded experience of Power BI within Business Central.   |
|    Package: https://github.com/microsoft/PowerBI-JavaScript                                                |
|    Docs:    https://docs.microsoft.com/en-us/javascript/api/powerbi/powerbi-client/                        |
------------------------------------------------------------------------------------------------------------*/

var embed = null;
var activePage = null;
var legacySettingsObject = null;
var models = null;
var pbiAuthToken = null;
// Settings:
var _showBookmarkSelection = false;
var _showFilters = false;
var _showPageSelection = false;
var _showZoomBar = true;
var _forceTransparentBackground = false;
var _forceFitToPage = false;
var _addBottomPadding = false;
var _localeSettings = {};

function Initialize() {
    models = window['powerbi-client'].models;

    RaiseAddInReady();
}

// Addin Callbacks

function RaiseAddInReady() {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', null);
}

function RaiseErrorOccurred(operation, errorMessage) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ErrorOccurred', [operation, errorMessage]);
}

function RaiseReportPageChanged(newpagename, newpagefilters) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ReportPageChanged', [newpagename, newpagefilters]);
}

function RaiseReportLoaded(reportfilters, activepagename, activepagefilters, correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ReportLoaded', [reportfilters, activepagename, activepagefilters, correlationId]);
}

function RaiseDashboardLoaded(correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DashboardLoaded', [correlationId]);
}

function RaiseDashboardTileLoaded(correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DashboardTileLoaded', [correlationId]);
}

function RaiseReportVisualLoaded(correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ReportVisualLoaded', [correlationId]);
}

// Obsolete Functions

function InitializeReport(reportLink, reportId, authToken, powerBIEnv) {
    // OBSOLETE
    EmbedReport(reportLink, reportId, authToken, '');
}

function EmbedReportWithOptions(reportLink, reportId, authToken, pageName, showPanes) {
    // OBSOLETE
    EmbedReport(reportLink, reportId, authToken, pageName)
}

function EmbedReport(reportLink, reportId, authToken, pageName) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIReport(reportLink, reportId, pageName);
}

function EmbedDashboard(dashboardLink, dashboardId, authToken) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIDashboard(dashboardLink, dashboardId);
}

function EmbedDashboardTile(dashboardTileLink, dashboardId, tileId, authToken) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIDashboardTile(dashboardTileLink, dashboardId, tileId);
}

function EmbedReportVisual(reportVisualLink, reportId, pageName, visualName, authToken) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIReportVisual(reportVisualLink, reportId, pageName, visualName);
}

function ViewMode() {
    // OBSOLETE
    embed.switchMode('View').catch(function (error) {
        ProcessError('ViewMode', error);
    });
}

function EditMode() {
    // OBSOLETE
    embed.switchMode('Edit').catch(function (error) {
        ProcessError('EditMode', error);
    });
}

function InitializeFrame(fullpage, ratio) {
    // OBSOLETE
    legacySettingsObject = {
        panes: {
            bookmarks: {
                visible: false
            },
            fields: {
                visible: fullpage,
                expanded: false
            },
            filters: {
                visible: fullpage,
                expanded: fullpage
            },
            pageNavigation: {
                visible: fullpage
            },
            selection: {
                visible: fullpage
            },
            syncSlicers: {
                visible: fullpage
            },
            visualizations: {
                visible: fullpage,
                expanded: false
            }
        },

        background: models.BackgroundType.Transparent,

        layoutType: models.LayoutType.Custom,
        customLayout: {
            displayOption: models.DisplayOption.FitToPage
        }
    }
}

function SetSettings(showBookmarkSelection, showFilters, showPageSelection, showZoomBar, forceTransparentBackground, forceFitToPage, addBottomPadding) {
    // OBSOLETE
    _showBookmarkSelection = showBookmarkSelection;
    _showFilters = showFilters;
    _showPageSelection = showPageSelection;
    _showZoomBar = showZoomBar;
    _forceTransparentBackground = forceTransparentBackground;
    _addBottomPadding = addBottomPadding;
    _forceFitToPage = forceFitToPage;
}

// Exposed Functions

function EmbedPowerBIReport(reportLink, reportId, pageName) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(reportLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'report';
    embedConfiguration.id = SanitizeId(reportId);
    embedConfiguration.embedUrl = reportLink;
    if (pageName && (pageName != '')) {
        embedConfiguration.pageName = pageName;
    }
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("rendered");
    embed.on('rendered', function (event) {
        var reportPages = null;
        var reportFilters = null;
        var pageFilters = null;
        var embedCorrelationId = null;

        var promises =
            [
                embed.getCorrelationId().then(function (correlationId) {
                    embedCorrelationId = correlationId;
                }),

                embed.getPages().then(function (pages) {
                    var pagesArray = pages.reduce(ReduceByNameFunction, []);
                    reportPages = JSON.stringify(pagesArray);
                }),

                embed.getFilters().then(function (filters) {
                    reportFilters = JSON.stringify(filters);
                }),

                embed.getActivePage().then(function (page) {
                    activePage = page;
                    return page.getFilters().then(function (filters) {
                        pageFilters = JSON.stringify(filters);
                    });
                })
            ]

        Promise.all(promises).then(
            function (values) {
                embed.off("rendered");
                RaiseReportLoaded(reportFilters, reportPages, pageFilters, embedCorrelationId);
            },
            function (error) {
                ProcessError('LoadReportDetails', error);
            });
    });

    embed.off("pageChanged");
    embed.on('pageChanged', function (event) {
        activePage = event.detail.newPage;
        activePage.getFilters().then(function (filters) {
            RaiseReportPageChanged(activePage.name, JSON.stringify(filters));
        },
            function (error) {
                ProcessError('LoadPageFilters', error);
            });
    });
}

function EmbedPowerBIDashboard(dashboardLink, dashboardId) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(dashboardLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'dashboard';
    embedConfiguration.id = SanitizeId(dashboardId);
    embedConfiguration.embedUrl = dashboardLink;
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("loaded");
    embed.on('loaded', function (event) {
        embed.getCorrelationId().then(function (correlationId) {
            RaiseDashboardLoaded(correlationId);
        },
            function (error) {
                ProcessError('LoadDashboardCorrelationId', error);
            });
    });
}

function EmbedPowerBIDashboardTile(dashboardTileLink, dashboardId, tileId) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(dashboardTileLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'tile';
    embedConfiguration.id = SanitizeId(tileId);
    embedConfiguration.dashboardId = SanitizeId(dashboardId);
    embedConfiguration.embedUrl = dashboardTileLink;
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("loaded");
    embed.on('loaded', function (event) {
        embed.getCorrelationId().then(function (correlationId) {
            RaiseDashboardTileLoaded(correlationId);
        },
            function (error) {
                ProcessError('LoadDashboardTileCorrelationId', error);
            });
    });
}

function EmbedPowerBIReportVisual(reportVisualLink, reportId, pageName, visualName) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(reportVisualLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'visual';
    embedConfiguration.id = SanitizeId(reportId);
    embedConfiguration.pageName = SanitizeId(pageName);
    embedConfiguration.visualName = SanitizeId(visualName);
    embedConfiguration.embedUrl = reportVisualLink;
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("loaded");
    embed.on('loaded', function (event) {
        embed.getCorrelationId().then(function (correlationId) {
            RaiseReportVisualLoaded(correlationId);
        },
            function (error) {
                ProcessError('LoadReportVisualCorrelationId', error);
            });
    });
}

function FullScreen() {
    embed.fullscreen();
}

function UpdateReportFilters(filters) {
    var newFilters = null;
    try {
        newFilters = JSON.parse(filters);
    } catch (err) {
        ProcessError('ParseReportFilters', err);
    }

    embed.updateFilters(models.FiltersOperations.Replace, newFilters).catch(function (error) {
        ProcessError('UpdateReportFilters', error);
    });
}

function RemoveReportFilters() {
    embed.removeFilters().catch(function (error) {
        ProcessError('RemoveReportFilters', error);
    });
}

function UpdatePageFilters(filters) {
    var newFilters = null;
    try {
        newFilters = JSON.parse(filters);
    } catch (err) {
        ProcessError('ParsePageFilters', err);
    }

    activePage.updateFilters(models.FiltersOperations.Replace, newFilters).catch(function (error) {
        ProcessError('UpdatePageFilters', error);
    });
}

function RemovePageFilters() {
    activePage.removeFilters().catch(function (error) {
        ProcessError('RemovePageFilters', error);
    });
}

function SetPage(pageName) {
    report.setPage(pageName).catch(function (error) {
        ProcessError('SetPage', error);
    });
}

function SetLocale(newLocale) {
    _localeSettings = {
        language: newLocale
    }
}

function SetToken(authToken) {
    pbiAuthToken = authToken;
}

function SetBookmarksVisible(visible) {
    _showBookmarkSelection = visible;
}

function SetFiltersVisible(visible) {
    _showFilters = visible;
}

function SetPageSelectionVisible(visible) {
    _showPageSelection = visible;
}

function SetTransparentBackground(transparent) {
    _forceTransparentBackground = transparent;
}

function AddBottomPadding(addPadding) {
    _addBottomPadding = addPadding;
}

// Internal functions

function CompileSettings() {
    if (legacySettingsObject) {
        // Already initialized. This case is only used for backwards compatibility.
        return legacySettingsObject;
    }

    if (_addBottomPadding) {
        var iframe = window.frameElement;
        iframe.style.paddingBottom = '42px';
    }
    else {
        var iframe = window.frameElement;
        iframe.style.removeProperty('paddingBottom');
    }

    var settingsObject = {
        panes: {
            bookmarks: {
                visible: _showBookmarkSelection
            },
            filters: {
                visible: _showFilters,
                expanded: false
            },
            pageNavigation: {
                visible: _showPageSelection
            },
            fields: { // In edit mode, allows selecting fields to add to the report
                visible: false
            },
            selection: { // In edit mode, allows selecting visuals from a list instead of clicking in the UI
                visible: false
            },
            syncSlicers: { // In edit mode, allows syncing slicers through pages
                visible: false
            },
            visualizations: { // In edit mode, allows adding new visualizations
                visible: false
            }
        },

        bars: {
            statusBar: {
                visible: _showZoomBar
            }
        },

        localeSettings: _localeSettings
    }

    if (_forceTransparentBackground) {
        settingsObject.background = models.BackgroundType.Transparent;
    }

    if (_forceFitToPage) {
        settingsObject.layoutType = models.LayoutType.Custom;
        settingsObject.customLayout = {
            displayOption: models.DisplayOption.FitToPage
        }
    }

    return settingsObject;
}

function ExtractBootstrapConfiguration(embedConfiguration) {
    return {
        type: embedConfiguration.type,
        hostname: GetHost(embedConfiguration.embedUrl),
        settings: {
            localeSettings: embedConfiguration.settings.localeSettings
        }
    };
}

function ClearEmbedGlobals() {
    embed = null;
    activePage = null;
}

function InitializeEmbedConfig() {
    if (!pbiAuthToken || (pbiAuthToken == '')) {
        RaiseErrorOccurred('Initialize Config', 'No token was provided');
    }

    var embedConfiguration = {
        tokenType: models.TokenType.Aad,
        accessToken: pbiAuthToken,

        viewMode: models.ViewMode.View,
        permissions: models.Permissions.All,
        settings: CompileSettings()
    };

    return embedConfiguration;
}

function DisplayEmbed(embedConfiguration) {
    var reportContainer = document.getElementById('controlAddIn');

    powerbi.reset(reportContainer);


    // NOTE: Bootstrap is here to work around an issue with how the powerbi.js library handles ScoreCards.
    // ScoreCards are classified as Reports, but have different URL structure. If we call powerbi.embed directly on a ScoreCard, the library
    // tries to load non-existing ScoreCard resources. Bootstrapping without the final URL forces the library to load the correct Report resources.
    var bootstrapConfiguration = ExtractBootstrapConfiguration(embedConfiguration);
    powerbi.bootstrap(reportContainer, bootstrapConfiguration);

    embed = powerbi.embed(reportContainer, embedConfiguration);
}

function RegisterCommonEmbedEvents() {
    embed.off("error");
    embed.on("error", function (event) {
        ProcessError('OnError', event);
    });
}

function ReduceByNameFunction(accumulator, current) {
    accumulator.push(current.name);
    return accumulator;
}

function SanitizeId(id) {
    // From: {79a5e047-a665-4c83-900b-f5ccf19e01c7}
    // To:    79a5e047-a665-4c83-900b-f5ccf19e01c7
    return id.replace(/[{}]/g, "");
}

function GetHost(url) {
    var urlObject = new URL(url);
    return urlObject.protocol.concat('//').concat(urlObject.host)
}

function ProcessError(operation, error) {
    LogErrorToConsole(operation, error);

    var errorMessage = GetErrorMessage(error);
    RaiseErrorOccurred(operation, errorMessage);
}

function LogErrorToConsole(operation, error) {
    console.error('Error occurred (' + operation + '). See the detailed error in the following message.');
    console.error(error);
}

function GetErrorMessage(error) {
    if (error && error.detail && error.detail.detailedMessage) {
        return error.detail.detailedMessage;
    }

    if (error && error.detail && error.detail.message) {
        return error.detail.message;
    }

    if (error && error.message) {
        return error.message;
    }

    return error.toString();
}

function ValidatePowerBIHost(embedUrl) {
    var urlHost = GetHost(embedUrl);
    if (!urlHost.endsWith(".powerbi.com") && !urlHost.endsWith('.analysis-df.windows.net')) {
        var errorMsg = 'The host "' + urlHost + '" is not a valid Power BI host.';
        ProcessError('InvalidHost', errorMsg);
        throw new Error(errorMsg);
    }
}

// SIG // Begin signature block
// SIG // MIInRAYJKoZIhvcNAQcCoIInNTCCJzECAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // wn26Qgtc4uNOtMvwB8pGgJefHQibHYqjx+3mp/bUkwyg
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
// SIG // SIb3DQEJBDEiBCCe9uanxaQyVgU6xZdD2Y3vAf0E24TF
// SIG // ZwDSr2LTJjlE+zBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAJMK
// SIG // A2v6ZQOpAe4DyGK+soyfPKww6ndPXfDM6cCkCGnxbBeX
// SIG // 4z01XE8ht830MMeoU8WSJ/yr4/oNTnfYxwlEGIVbFxXo
// SIG // hBZyo3911xAYkmgji5zpUzvME3b6u3kBubm3k+fAIaXp
// SIG // LR5+GVHUz3BXd1Z30DIKAaZNt8WABNKDGqSOrfK9C4Gk
// SIG // wy+TlKaBas0b69S5gbyzQXR5cby1snicAlTqaG/vDXsj
// SIG // 9dD9mSNiOm31IycEbBDWq74mEQUwqC9jChYpjuCW0Kuv
// SIG // vbbuIhoQI9PMEsUxpestglcKpuZZ3Um+mmbRqBeTqI/r
// SIG // K6wsrVlnF3CzYPZDnL17aYwK5fCVI8ihgheUMIIXkAYK
// SIG // KwYBBAGCNwMDATGCF4Awghd8BgkqhkiG9w0BBwKgghdt
// SIG // MIIXaQIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQg2BknogtNQJjpXvGx
// SIG // 5t7sc/CFsEtOOJkX4bjliQr0328CBmqpgF5dGxgTMjAy
// SIG // NjEwMDMyMDAwNDEuODY0WjAEgAIB9KCB0aSBzjCByzEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
// SIG // b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
// SIG // blNoaWVsZCBUU1MgRVNOOkEwMDAtMDVFMC1EOTQ3MSUw
// SIG // IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
// SIG // aWNloIIR6jCCByAwggUIoAMCAQICEzMAAAIruwBQ/007
// SIG // mqEAAQAAAiswDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTk0MDEx
// SIG // WhcNMjcwNTE3MTk0MDExWjCByzELMAkGA1UEBhMCVVMx
// SIG // EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
// SIG // ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
// SIG // dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
// SIG // T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
// SIG // RVNOOkEwMDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNy
// SIG // b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAl95oujg97MlK
// SIG // kJuEKoJKyj23LCv0Md32HLS/PlTNbjmN26KIuRscGrk4
// SIG // EH+iRRyE06MUu4I6ipSvDhS8y+lE5dI8RCubeg7jnICV
// SIG // 3b7rYpqE5TktAt5MiE1wQF6I/4KeoUUfc+lkYqdSrZIp
// SIG // W93SVwo0Kk/T9grro6/lc/K/mfow5dPY4v4nP+Bt+K95
// SIG // lcI7P/xp8fT7t9VfK1xYnDYgM8abm2sKW3fKan85Vk9r
// SIG // 5xt5BfZejIkRG7yd1xy1MB0LIdLf060hcf7P8gqqSVmC
// SIG // eqApRu9Lb7BR9GkT/MAeHD/whWtiC75NuotznCQZfqai
// SIG // ox00gcvZr8EzxA5Z83KNDbfEeqUj012YAbLHB4aCnwtF
// SIG // kJjs2NpHl2wJkU3GTMl8+b/wCW5qCNMtOwWs77eTZF3X
// SIG // RvUxK0FsLbBciCqxJQ4Fnx3gqE7tcLtnIg93Su9s93Gt
// SIG // oM6BA8U9o/QVyFCmok803UD0bADGjt3VNM2hsDDJcLUi
// SIG // cg4deGBIGaFLub0vDLoDKnazY6Yci+ucioY6QFm4WJCB
// SIG // zv9LmY7vebT/M2TalyEYeLXX1hyTwE5/a/nMZMrodsdF
// SIG // S3X8dZZivV9zYx9DbYALOSQf8DpZMrrncZhU31lckay9
// SIG // +4rKTmfGjwBYL8kenDU5BqZBaN+SUY3IjZmYlOKk/VLc
// SIG // vleYLnRZNY8CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBQ+
// SIG // Fo7kE1CW7W3d45r2ZLtBWdnlNjAfBgNVHSMEGDAWgBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
// SIG // UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
// SIG // UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
// SIG // MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
// SIG // bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
// SIG // HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
// SIG // MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
// SIG // AgEAzvwirHIhDPJK9X6h+E5X0+uhDaE48V8PNdKchKtD
// SIG // 3a4C8H4E98ftYM+wkB7VHXr6jEOah8gy4ZuqU/ddQmJB
// SIG // jfuoPjFO3zGE6+nd0sYnicASKFpH0eIO0orRszClOOuS
// SIG // hGHo33XaFIKLwv8XEaWgCzuad/wNuPAcoSYjLbQUDQ7b
// SIG // E/x2ghcERQlEW8v3/HNZJMvBfMZAlxc/vzLWeXdZVhY8
// SIG // DiNoHmR1qvV4oQzoHnuZ0tpKKOVep/FxtttFE3r1X/qY
// SIG // JqSB+9Vyg1SGExhmSbOsj5Xydml6sNTBODUeqJDbGNz9
// SIG // TN9R+gzGEXyRjQTXqefeZFxod2MwN3AosoPo5iefIf30
// SIG // 7454CKblBXzg6Q4xcdInNWKCwDcYQhd0YUvamDOyuNDR
// SIG // ISrIWLmgJCBtlwSmIoN6/9P29LI74wcLOeQGKJzJtwPK
// SIG // nF/+pPVX3NJr/XbaJx7lhnwNm/qhNqqQp4cxm3Qx6u4j
// SIG // kmRMNNZzbqQDH9XONZPSKE0Ns94sOsOGWaCzsoOEyjG6
// SIG // dZK6U+La4qf8t9Ar+ZIcqggzaml0KQZDmDjfC4LaEN2p
// SIG // lTl+4seY3a58f71MU1EooF761nS+1JPJKZktM7aNk6Mu
// SIG // 2k+aAcwk734/YifwTfxNb4RQZISQr2ez1b7DEp005pMd
// SIG // hWpdpVZM7bgCOOHw/7siyXWjEEswggdxMIIFWaADAgEC
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
// SIG // BgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBMDAwLTA1RTAt
// SIG // RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
// SIG // bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUACaw/dMpB
// SIG // 6aP9ABm+5ZsL7ArakTmggYMwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIF
// SIG // AO5rtvIwIhgPMjAyNjEwMDMxNzE2MzRaGA8yMDI2MTAw
// SIG // NDE3MTYzNFowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA
// SIG // 7mu28gIBADAHAgEAAgINiTAHAgEAAgISIjAKAgUA7m0I
// SIG // cgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZ
// SIG // CgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqG
// SIG // SIb3DQEBCwUAA4IBAQBZD4tKfb8aw+MChY6DFgO5cawh
// SIG // PiPj0B3Wh9RM/TGp9A2utmr3NjsNXtowcS+taViZC5jF
// SIG // gELXAPxb7LURuPec1Cn3OTFQnHKicgbyASBmTW6pQpbI
// SIG // TrXILIu4M/vd4tBBmc4DXFooklvcUneoZvfTQS2w8JyV
// SIG // UPwBVcUC+TMDXuji7vw4ydIed3aj7XkovVe9XSyZHCdv
// SIG // 7VyY7M/uPmNpjZPehQ+WlgSrSNAautB3e3gNwXTE+SVB
// SIG // mHshQvm7DGRgt1qDqW2F5qRSi/BwDChqm0LsePzBqLNE
// SIG // 4W0xHgTTT4Hv6gagan9uJpdgIeMzswQv1SLDpBa046yW
// SIG // hpd+PSzDMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTACEzMAAAIruwBQ/007mqEAAQAA
// SIG // AiswDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
// SIG // AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
// SIG // d7ud+eXbDcNNkblKP5NeRDNRQ+Jv10HuX1OjDh3xK3ww
// SIG // gfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCByDiP0
// SIG // P5BX7WAPjNjmPtQcd2owQ+v1gwLT09rxZL9uUjCBmDCB
// SIG // gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
// SIG // HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
// SIG // AAACK7sAUP9NO5qhAAEAAAIrMCIEIIHzAq4zs0xTRM9x
// SIG // e4v9ceHY8jipmFc6MiosKtm7NmWJMA0GCSqGSIb3DQEB
// SIG // CwUABIICAH3ukO5Rlj/Ro8noW/ejsRQu4KGO/ZoPK/1f
// SIG // JJV3rDXcxee3F/E5dal2Gl9Vjiwi7SiT10v6z/k5tQvb
// SIG // 3Iy75bXFRAvkFia0hnh60dNjmGlOQUXZAQzTnZTVTBTq
// SIG // /8NzLlrMc6Caa0tdyOynBr9Rcb7qAa2Cyq8CEscIR1HY
// SIG // RCsAQKuqxwSzeMYIRuAsdFJUueVvsXsQbRENXD/QFfPH
// SIG // BrrjPaLdJjHUry46ATYnbmQwAO0OkcqdqOmRRouEbfDD
// SIG // c0gRfCoAbmTKiSwvePk03jcT0AxXgH+rtsDIZhUl+goO
// SIG // VpNMKsv12cDFW0L9uWKOvmYiC3L3dcx6RLbMy5wG9WIG
// SIG // bBg4p0RzGaM5RUPbmQrAUeg3Mgst7kQAt8qj/FntaHaX
// SIG // Bxca4FVXVPP70/RpEEPvJnEK3ce6KvQYdpgklAGBniy3
// SIG // Nmc/UNL3XFFGaopaTLB1YY0awIdlqQvevydvL63S3FxC
// SIG // dIS3iWnr8aozUBrD7lvX9l4lHUBr5vn1PBYIUljU5Ah9
// SIG // O/VgkSIx3rvfuQFTwwoE1du5cHpTXMyw5eh2mpTySzrE
// SIG // 2xHlJm1T0ReMeV8X8XJiDPhZgZKvQnvnYDbwpvGq34lg
// SIG // Z0SuCWFjREMCSf4x6zEUtyf/OyAFuE4THeFa+b4wtQTI
// SIG // 2iK+o5/gogO7XskJRhBD664n+dBPPPg9
// SIG // End signature block
