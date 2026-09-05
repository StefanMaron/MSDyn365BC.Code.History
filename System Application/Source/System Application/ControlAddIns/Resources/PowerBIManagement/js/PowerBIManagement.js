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
// SIG // MIInbAYJKoZIhvcNAQcCoIInXTCCJ1kCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // wn26Qgtc4uNOtMvwB8pGgJefHQibHYqjx+3mp/bUkwyg
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
// SIG // 9hxwL30BElj9MYIZ+zCCGfcCAQEwbjBXMQswCQYDVQQG
// SIG // EwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
// SIG // aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWdu
// SIG // aW5nIFBDQSAyMDI0AhMzAAACHPrNxZvoL37EAAAAAAIc
// SIG // MA0GCWCGSAFlAwQCAQUAoIGuMBkGCSqGSIb3DQEJAzEM
// SIG // BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
// SIG // BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCe9uanxaQy
// SIG // VgU6xZdD2Y3vAf0E24TFZwDSr2LTJjlE+zBCBgorBgEE
// SIG // AYI3AgEMMTQwMqAUgBIATQBpAGMAcgBvAHMAbwBmAHSh
// SIG // GoAYaHR0cDovL3d3dy5taWNyb3NvZnQuY29tMA0GCSqG
// SIG // SIb3DQEBAQUABIIBAEFb1I4mC/VwcYSO0tsIFYOqztG9
// SIG // M3Mf6+lum0IqW+VSoomHPitHvGfbopMd74IGXz42N2OB
// SIG // slQt6XBBOayO2qSRisgYT+jXBHBigiqgCHW/WPf/GnAC
// SIG // WsqF76qTvxssdTG3zEhiAJvtRVQR89QdILwPp9hnqHVp
// SIG // qYLgGOQEwCPx9ytblHwGXeYD4XxO3yG9foaxGfbRvJGJ
// SIG // yeQTDnN6RchcZtVl/Kv21uJ0GC1qo2UmKw7mwJjLWnK7
// SIG // H28ck+yvJ9CLNumEheTMERWbH2IKY3ahJX6lQYWN1XaF
// SIG // DPi+wCFIjZr1x8l0d3nd5weg9iJJpEmJI1Nz0bfy33qN
// SIG // mHU6XBWhghetMIIXqQYKKwYBBAGCNwMDATGCF5kwgheV
// SIG // BgkqhkiG9w0BBwKggheGMIIXggIBAzEPMA0GCWCGSAFl
// SIG // AwQCAQUAMIIBWgYLKoZIhvcNAQkQAQSgggFJBIIBRTCC
// SIG // AUECAQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEF
// SIG // AAQgsdRTtbhIbc0/ff+3uPF6MJOdscQcg+JVkZSFnVSq
// SIG // +lgCBmpjbgttfRgTMjAyNjA4MDIyMTQ5NDMuNTk2WjAE
// SIG // gAIB9KCB2aSB1jCB0zELMAkGA1UEBhMCVVMxEzARBgNV
// SIG // BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
// SIG // HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEt
// SIG // MCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0
// SIG // aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRT
// SIG // UyBFU046NDAxQS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1p
// SIG // Y3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghH7MIIH
// SIG // KDCCBRCgAwIBAgITMwAAAhlesthUdfSxjQABAAACGTAN
// SIG // BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMDAeFw0yNTA4MTQxODQ4MjZaFw0yNjExMTMx
// SIG // ODQ4MjZaMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
// SIG // V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
// SIG // A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYD
// SIG // VQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25z
// SIG // IExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
// SIG // Tjo0MDFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZI
// SIG // hvcNAQEBBQADggIPADCCAgoCggIBAKahSMlJMyMsaS90
// SIG // NN1pi7suBvWCFEnM54Sq/nBzk/v7uz2q8SPeoMcW9Vq1
// SIG // rgMQfKoxi37GyJsfFd6LitZ1HH/kf57J12rOf4k4Ff05
// SIG // d0E0Rk9A3rlwTW6R6nPsAtTYk8gO+oC54q70gRKAc5a6
// SIG // TUBRJ7sHWzywi6U0tylkgruSdNm/kRVkf5HBc1cZ4aBN
// SIG // 4CGnlEbaxihgWRiiwV76oIJAxDbSpL7b0U99sS7wLy/0
// SIG // aUXruc9fGaIwrO9mUqGu+A8vGG2lrA5tzmTqSUWcWbDy
// SIG // gh2esTaoBSn9MTR49Lfb9EN1vts+YAFWmrCSQr0edkpd
// SIG // FydgDn95dC0nrV4FAOYA+SENUbxLJU5jZ0qLk6xiA9w9
// SIG // Z42O5gbtKboiHTytoyv9Vnnn9vmEeHEKVkJHgWZl4nYf
// SIG // QLlnZcMSkC9eSyeitncPMv7fzwYZi8rekAH9AnqVkXYG
// SIG // ZzMrVQFLlh8JWUVfSS2O2l/A+eXi/fnDi6V92xjTpjdu
// SIG // FKSFvKrWWql2nrBbyDlttyTS4WmkFbzm69XruxhP+TJ+
// SIG // N3vvw27XWJf2yz9iENcWBCXUm3FJAxX1typWRIfpwSg7
// SIG // WkZzUZG4CIMSGynU9/DikMGf2gOLkrIgIOpxD4lgRxrs
// SIG // rSKOcFO+TOVXY4RKqkx312LvASYuhk871k/vXpHzF3s6
// SIG // gpJLMWhvAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUgGjq
// SIG // OR1mrTc6mZ9SBdX3A+p69yEwHwYDVR0jBBgwFoAUn6cV
// SIG // XQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
// SIG // UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
// SIG // cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBD
// SIG // QSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
// SIG // BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
// SIG // Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
// SIG // LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0T
// SIG // AQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
// SIG // BgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIB
// SIG // AF8c1WSy1wRX6Aggk4mOzB13W+3IryUk36x2CQuTpNjT
// SIG // e+Tac0zE/Vdk3CEI30NwBVG4dTQQGLTFLsMQug+HHhFx
// SIG // uZVwJ275AvWI3i1Q0ciJl2GJn7e8/kKZfbdwv/GtLYqp
// SIG // zs/FHvPw2C7TE4L1jJ7KizYyCw2iJjn5xyN+kywoxhXv
// SIG // EWC1xnQlHTi5XwHTBnj8UkwN0wADnPhkG5j1o64Li1m8
// SIG // b55dzVY0b6wWVZMRTKFWR9H+6hsAzkoY6Z7+Z2J0OPLn
// SIG // y9Lgc+dkWzxnV+Bb/flBjqwaa5nB85iLrRbSXnNmOJLo
// SIG // zbUytsARoFrHBDlYRYmlXY3vFSyezFTShOU5rLhjN40y
// SIG // 69Z7keQBRrN1CpD+4N3EA+HByu13S4k5u3utOkCflqnk
// SIG // LAA2BPXb1PcCFGyPQ5eFHCBKxcPhR2lkk65HyeEry5oS
// SIG // p5eZIYaSdbBd8+ntQcXqVJYlx6s0S4h1ooViFhEhfCBx
// SIG // JRdzzsWz+FSahwYmL2lzFdEskYMKA+s13XW1J1/VkeiS
// SIG // 9gZagI4x8SDcHpbKf1YcQFk4c7jAOfC8bxP1QM43xReF
// SIG // pu2tWQC5iVcN6C/7P7saNTqeLXE/oX2fbjdYbQtSTeA7
// SIG // kahXy7bY7qAJlEKGzuc1BUc7wp/ApP4Yjvm80debKpI5
// SIG // cSzMjI6ZHP3n+ElFIpA+OvL1MIIHcTCCBVmgAwIBAgIT
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
// SIG // BmoQtB1VM1izoXBm8qGCA1YwggI+AgEBMIIBAaGB2aSB
// SIG // 1jCB0zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMk
// SIG // TWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1p
// SIG // dGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NDAx
// SIG // QS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
// SIG // aW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
// SIG // ADF2Kf1qqncm9Hp4oKy38ZdCJwM+oIGDMIGApH4wfDEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcN
// SIG // AQELBQACBQDuGck9MCIYDzIwMjYwODAyMTM0ODQ1WhgP
// SIG // MjAyNjA4MDMxMzQ4NDVaMHQwOgYKKwYBBAGEWQoEATEs
// SIG // MCowCgIFAO4ZyT0CAQAwBwIBAAICCEowBwIBAAICEesw
// SIG // CgIFAO4bGr0CAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYK
// SIG // KwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGG
// SIG // oDANBgkqhkiG9w0BAQsFAAOCAQEAJMEQZLizBBNiP06V
// SIG // 8mCP50076hC851MQtWdi9fGDEQwwSZtwlwFoGNNOml6r
// SIG // sUwUcZVgeOF1RwA0f05CAdhWpMHJWgOeVIvGxuBTDit3
// SIG // /Xlp4ePiFAjb+Uxtt3EERtK7jUXXnuXGNmaW1PPpLBJp
// SIG // wachug8lV1R8nIy6srV9zzr9BFvrYmEEi6pDl04iFwr5
// SIG // TZKCV9QE/LOcv72U5p6/+2qb+lcXx46G1cueMo6ksaoN
// SIG // RjSknkpAbJ/oHDPqZT/lJq3vxaNO8bFIztsenhKwiRXH
// SIG // 3dv0cvlyndicgx5KobUjkH3+TAA+NY37hdtW2R/0aov+
// SIG // MBctDWoWm8ZviQ1d6zGCBA0wggQJAgEBMIGTMHwxCzAJ
// SIG // BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
// SIG // DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
// SIG // ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
// SIG // dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAACGV6y2FR1
// SIG // 9LGNAAEAAAIZMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkq
// SIG // hkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcN
// SIG // AQkEMSIEIP8QzX/nNHQz4t3+q7p1IuoOLvfSf36/CXhs
// SIG // p/LsrG6bMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCB
// SIG // vQQg3JF+t9xNctRBd9ldfM0HK7II8yPfty3u5pb5Njnm
// SIG // 7YYwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UE
// SIG // CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
// SIG // MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
// SIG // JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
// SIG // MjAxMAITMwAAAhlesthUdfSxjQABAAACGTAiBCDHhE/0
// SIG // OX9i8SGnqmGZtNJCcr804TLohTfak3GmHXW0TDANBgkq
// SIG // hkiG9w0BAQsFAASCAgBQXF9CKdxKKI46ABFk+MATJrDo
// SIG // mAUjs9IDoZhBLFL8sy+CCUe7AxXMOZYtVDz9VqoeNeMX
// SIG // LkPcUpt0TXOqy+XLCApyr+7EA9iIiXmbUPFTIgp5wZYO
// SIG // YILbE9MQzK1/ezoJn2oKFO4RGALMJrTPJOMOyjz5i0fi
// SIG // 5uBeHL5G3lQiQgssbCu+X55NZvad6rrgyZnmj9DDZjzx
// SIG // 0L4nQAvFcqtmOH7nTCj+zlm1cZ21+cSKA3arlsj8/O+S
// SIG // EMpHGZSmcfx0oaxEX+g3civwBS+INjGr4Gz362y6GSFF
// SIG // 92p9gzGV4CaxrV4yRwRei3wI3rdz2iV6FCCn45ySrT+r
// SIG // 7vsEhuyzBLSuDkT9Mm2IdsGyyIylJ64lkT33VfJohpiZ
// SIG // CBUSExNGpKNfg+ZpABjUW3IMwq25aCCNstYLZ5efBLNw
// SIG // lMKUPniwobM11/nlyCLSmdwBci5calCjXJXIYengXLlB
// SIG // IojAP2LUL95TycyeK9NvLSao4LuIa+Ss9uMPNsj9xdrh
// SIG // GteDQS3UUNbw6LTCQa9guCcAB/HXPpL59mC+LGhtSr67
// SIG // PxIkgL87HMZpIrlbGJOACKlKF3QStvZrYil2eT2/3lok
// SIG // un57kmwOZ1IefnySDNzgQfUeUlQOsJXXLtCZwFZ48FyK
// SIG // 5/DLezhCgqyeJWtloFloOv9UPB+38or5o/atE964IQ==
// SIG // End signature block
