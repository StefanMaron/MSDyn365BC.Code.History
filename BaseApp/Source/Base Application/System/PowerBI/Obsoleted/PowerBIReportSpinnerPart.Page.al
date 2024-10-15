#if not CLEAN23
namespace System.Integration.PowerBI;

using System.Environment;
using System.Utilities;
using System.Integration;

page 6303 "Power BI Report Spinner Part"
{
    Caption = 'Power BI Reports (Obsolete)';
    PageType = CardPart;
    ObsoleteState = Pending;
    ObsoleteReason = 'This page has been replaced by page 6325 Power BI Embedded Report';
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(control28)
            {
                ShowCaption = false;
                Visible = PageState = PageState::GetStarted;

                field(OptInGettingStarted; GettingStartedTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Specifies whether the Power BI functionality is enabled.';

                    trigger OnDrillDown()
                    var
                        PowerBIUserConfiguration: Record "Power BI User Configuration";
                        PowerBIEmbedSetupWizard: Page "Power BI Embed Setup Wizard";
                    begin
                        Session.LogMessage('0000B72', PowerBiOptInTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

                        Commit();
                        LastOpenedReportID := PowerBIUserConfiguration."Selected Report ID";

                        if not PowerBiServiceMgt.CheckForPowerBILicenseInForeground() then begin
                            PowerBIEmbedSetupWizard.SetContext(Context);
                            if PowerBIEmbedSetupWizard.RunModal() = Action::Cancel then
                                exit;
                        end else
                            StartAutoDeployment();

                        OpenPageOrRefresh(false); // The control add-in will load reports when ready
                    end;
                }
                field(OptInImageField; MediaResources."Media Reference")
                {
                    Caption = '';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(DeployReportsGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::ShouldDeploy;

                field(DeployReportsLink; DeployReportsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Specifies that the user can upload one or more demo reports for this page.';

                    trigger OnDrillDown()
                    begin
                        StartAutoDeployment();
                        Message(ReportsDeployingMsg);
                    end;
                }
            }
            group(Control11)
            {
                ShowCaption = false;
                Visible = PageState = PageState::ReportVisible;

                usercontrol(WebReportViewer; WebPageViewer)
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        AddInReady := true;
                        if not TempPowerBiReportBuffer.IsEmpty() then
                            SetReport();
                    end;

                    trigger DocumentReady()
                    begin
                        InitalizeAddIn();
                    end;

                    trigger Callback(data: Text)
                    begin
                    end;

                    trigger Refresh(callbackUrl: Text)
                    begin
                        if AddInReady and not TempPowerBiReportBuffer.IsEmpty() then
                            SetReport();
                    end;
                }
            }
            grid(Control15)
            {
                GridLayout = Columns;
                ShowCaption = false;

                group(Control13)
                {
                    ShowCaption = false;
                    group(Control10)
                    {
                        ShowCaption = false;
                        Visible = PageState = PageState::ErrorVisible;

                        field(ErrorMessageText; ErrorMessageText)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the error message from Power BI.';
                        }
                    }
                    group(Control12)
                    {
                        ShowCaption = false;
                        Visible = PageState = PageState::NoReport;

                        label(EmptyMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'There are no enabled reports.';
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(SelectReportsLink; SelectReportsTxt)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            Style = StrongAccent;
                            StyleExpr = true;
                            ToolTip = 'Specifies that the user can select the reports to show from here.';

                            trigger OnDrillDown()
                            begin
                                SelectReports();
                            end;
                        }
                    }
                    group(DeployingReports)
                    {
                        ShowCaption = false;
                        Visible = PageState = PageState::NoReportButDeploying;

                        label(EmptyMessage2)
                        {
                            ApplicationArea = All;
                            Caption = 'There are no enabled reports.';
                            Editable = false;
                            ShowCaption = false;
                        }
                        label(NoReportsMessage2)
                        {
                            ApplicationArea = All;
                            Caption = 'If you just started the upload of new reports from Business Central, choose Refresh to see if they''ve completed.';
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(SelectReportsLink2; SelectReportsTxt)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            Style = StrongAccent;
                            StyleExpr = true;
                            ToolTip = 'Specifies that the user can select the reports to show from here.';

                            trigger OnDrillDown()
                            begin
                                SelectReports();
                            end;
                        }
                        field(RefreshPartLink; RefreshPartTxt)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            Style = StrongAccent;
                            StyleExpr = true;
                            ToolTip = 'Specifies that the user can refresh the page part. If reports have been deployed in the background, refreshing the page part will make them visible.';

                            trigger OnDrillDown()
                            begin
                                OpenPageOrRefresh(true);
                            end;
                        }
                    }
                    group(Control20)
                    {
                        ShowCaption = false;
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Setup is now done in the page "Power BI Embed Setup Wizard"';
                        ObsoleteTag = '18.0';

                        // UserControls do not support Obsolete properties
                        // Bug 380401: UserControl elements in a page do not support Obsolete* properties, but app fails to build if they are removed.
                        usercontrol(DeployTimer; PowerBIManagement)
                        {
                            ApplicationArea = All;
                            Visible = false;
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Select Report")
            {
                ApplicationArea = All;
                Caption = 'Select Report';
                Enabled = (PageState = PageState::ReportVisible) or (PageState = PageState::NoReport) or (PageState = PageState::NoReportButDeploying) or (PageState = PageState::ShouldDeploy);
                Image = SelectChart;
                ToolTip = 'Select the report.';

                trigger OnAction()
                begin
                    SelectReports();
                end;
            }
            action("Expand Report")
            {
                ApplicationArea = All;
                Caption = 'Expand Report';
                Enabled = PageState = PageState::ReportVisible;
                Image = View;
                ToolTip = 'View all information in the report.';

                trigger OnAction()
                var
                    PowerBiReportDialog: Page "Power BI Report Dialog";
                begin
                    PowerBiReportDialog.SetReportUrl(GetEmbedUrlWithNavigation());
                    PowerBiReportDialog.Caption(StrSubstNo(ReportCaptionTxt, TempPowerBiReportBuffer.ReportName, TempPowerBiReportBuffer."Workspace Name"));
                    PowerBiReportDialog.Run();
                end;
            }
            action("Previous Report")
            {
                ApplicationArea = All;
                Caption = 'Previous Report';
                Enabled = PageState = PageState::ReportVisible;
                Image = PreviousSet;
                ToolTip = 'Go to the previous report.';

                trigger OnAction()
                begin
                    // need to reset filters or it would load the LastLoadedReport otherwise
                    TempPowerBiReportBuffer.Reset();
                    TempPowerBiReportBuffer.SetRange(Enabled, true);
                    if TempPowerBiReportBuffer.Next(-1) = 0 then
                        TempPowerBiReportBuffer.FindLast();

                    if AddInReady then
                        CurrPage.WebReportViewer.Navigate(GetEmbedUrl());
                end;
            }
            action("Next Report")
            {
                ApplicationArea = All;
                Caption = 'Next Report';
                Enabled = PageState = PageState::ReportVisible;
                Image = NextSet;
                ToolTip = 'Go to the next report.';

                trigger OnAction()
                begin
                    // need to reset filters or it would load the LastLoadedReport otherwise
                    TempPowerBiReportBuffer.Reset();
                    TempPowerBiReportBuffer.SetRange(Enabled, true);
                    if TempPowerBiReportBuffer.Next() = 0 then
                        TempPowerBiReportBuffer.FindFirst();

                    if AddInReady then
                        CurrPage.WebReportViewer.Navigate(GetEmbedUrl());
                end;
            }
            action("Manage Report")
            {
                ApplicationArea = All;
                Caption = 'Manage Report';
                Enabled = PageState = PageState::ReportVisible;
                Image = PowerBI;
                ToolTip = 'Opens current selected report for edits.';
                Visible = IsSaaSUser;

                trigger OnAction()
                var
                    PowerBIManagement: Page "Power BI Management";
                begin
                    PowerBIManagement.SetTargetReport(LastOpenedReportID, GetEmbedUrl());
                    PowerBIManagement.LookupMode(true);
                    PowerBIManagement.Run();

                    OpenPageOrRefresh(false);
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh Page';
                Enabled = PageState <> PageState::GetStarted;
                Image = Refresh;
                ToolTip = 'Refresh the visible content.';

                trigger OnAction()
                begin
                    OpenPageOrRefresh(true);
                end;
            }
            action("Upload Report")
            {
                ApplicationArea = All;
                Caption = 'Upload Report';
                Image = Add;
                ToolTip = 'Uploads a report from a PBIX file.';
                Visible = IsSaaSUser and HasPowerBIPermissions;
                Enabled = (PageState = PageState::ReportVisible) or (PageState = PageState::NoReport) or (PageState = PageState::NoReportButDeploying) or (PageState = PageState::ShouldDeploy);

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"Upload Power BI Report");
                    OpenPageOrRefresh(false);
                end;
            }
            action("Reset All Reports")
            {
                ApplicationArea = All;
                Caption = 'Reset All Reports';
                Image = Reuse;
                ToolTip = 'Resets all Power BI setup in Business Central, for all users. Reports in your Power BI workspaces are not affected and need to be removed manually.';
                Visible = IsPBIAdmin and HasPowerBIPermissions;

                trigger OnAction()
                var
                    PowerBIReportUploads: Record "Power BI Report Uploads";
                    PowerBIReportConfiguration: Record "Power BI Report Configuration";
                    PowerBIUserConfiguration: Record "Power BI User Configuration";
                    PowerBICustomerReports: Record "Power BI Customer Reports";
                    PowerBIUserStatus: Record "Power BI User Status";
                    ChosenOption: Integer;
                begin
                    ChosenOption := StrMenu(ResetReportsOptionsTxt, 1, ResetReportsQst);

                    Session.LogMessage('0000DE8', StrSubstNo(ReportsResetTelemetryMsg, ChosenOption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

                    if ChosenOption in [1, 2] then begin // Delete reports only or delete all
                        PowerBIReportConfiguration.DeleteAll();
                        PowerBIUserStatus.DeleteAll();
                        PowerBIUserConfiguration.DeleteAll();

                        if ChosenOption = 2 then begin // Delete all
                            PowerBICustomerReports.DeleteAll();
                            PowerBIReportUploads.DeleteAll();
                        end;

                        Commit();
                        OpenPageOrRefresh(false);
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        HasPowerBIPermissions := PowerBiServiceMgt.CheckPowerBITablePermissions(); // check if user has all table permissions necessary for Power BI usage
        IsPBIAdmin := PowerBiServiceMgt.IsUserAdminForPowerBI(UserSecurityId());
        IsSaaSUser := EnvironmentInfo.IsSaaS();
    end;

    trigger OnOpenPage()
    begin
        OpenPageOrRefresh(false);
    end;

    var
        TempPowerBiReportBuffer: Record "Power BI Report Buffer" temporary;
        MediaResources: Record "Media Resources";
        PowerBiServiceMgt: Codeunit "Power BI Service Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        PowerBiEmbedHelper: Codeunit "Power BI Embed Helper";
        ResetReportsQst: Label 'This action will clear some or all of of the Power BI report setup for all users in the company you''re currently working with. Note: This action doesn''t delete reports in Power BI workspaces.';
        ResetReportsOptionsTxt: Label 'Clear Power BI report selections for all pages and users,Reset the entire Power BI report setup', Comment = 'A comma-separated list of options';
        PowerBiOptInImageNameLbl: Label 'PowerBi-OptIn-480px.png', Locked = true;
        GettingStartedTxt: Label 'Get started with Power BI';
        DeployReportsTxt: Label 'Upload demo reports for this page';
        ReportsDeployingMsg: Label 'We are uploading a demo report to Power BI in the background for you. Once the upload finishes, choose Refresh to see it in this page.\\If you have already reports in your Power BI workspace, you can choose Select Reports instead.';
        StillDeployingMsg: Label 'We are still uploading your demo report. Once the upload finishes, choose Refresh again to see it in this page.\\If you have already reports in your Power BI workspace, you can choose Select Reports instead.';
        RefreshPartTxt: Label 'Refresh';
        SelectReportsTxt: Label 'Select reports';
        ReportCaptionTxt: Label '%1 (Workspace: %2)', Comment = '%1: a report name, for example "Top customers by sales"; %2: a Power BI workspace name, for example "Contoso"';
        PageState: Option GetStarted,ShouldDeploy,NoReport,NoReportButDeploying,ReportVisible,ErrorVisible;
        LastOpenedReportID: Guid;
        Context: Text[30];
        HasReports: Boolean;
        AddInReady: Boolean;
        ErrorMessageText: Text;
        IsSaaSUser: Boolean;
        IsPBIAdmin: Boolean;
        HasPowerBIPermissions: Boolean;
        // Telemetry labels
        InvalidEmbedUriErr: Label 'Invalid embed URI with length: %1', Locked = true;
        NoOptInImageTxt: Label 'There is no Power BI Opt-in image in the Database with ID: %1', Locked = true;
        PowerBiOptInTxt: Label 'User has opted in to enable Power BI services', Locked = true;
        PowerBIReportLoadTelemetryMsg: Label 'Loading Power BI report for user', Locked = true;
        ReportsResetTelemetryMsg: Label 'User has reset Power BI setup, option chosen: %1', Locked = true;

    local procedure OpenPageOrRefresh(ShowMessages: Boolean)
    var
        PreviousPageState: Option;
    begin
        PreviousPageState := PageState;

        UpdateContext();
        SetInitialPageState();

        CurrPage.Update();

        if ShowMessages then
            if (PageState = PageState::NoReportButDeploying) and (PreviousPageState = PageState::NoReportButDeploying) then
                Message(StillDeployingMsg);
    end;

    local procedure SetInitialPageState()
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        // No license has been verified yet
        if not PowerBiServiceMgt.CheckForPowerBILicenseInForeground() then begin
            LoadOptInImage();
            PageState := PageState::GetStarted;
            exit;
        end;

        LastOpenedReportID := PowerBIUserConfiguration."Selected Report ID";
        RefreshTempReportBuffer(); // Also points the record to last opened report id

        if TempPowerBiReportBuffer.IsEmpty() then begin
            if PowerBiServiceMgt.IsUserSynchronizingReports() then begin
                PageState := PageState::NoReportButDeploying;
                exit;
            end;

            if PowerBIReportSynchronizer.UserNeedsToSynchronize(Context) then begin
                LoadOptInImage();
                PageState := PageState::ShouldDeploy;
                exit;
            end;

            PageState := PageState::NoReport;
            exit;
        end;

        PageState := PageState::ReportVisible;

        if AddInReady then
            SetReport();
    end;

    local procedure StartAutoDeployment()
    var
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        // Ensure user config for context before deployment
        if Context = '' then
            exit;

        PowerBIReportSynchronizer.SelectDefaultReports();
        PowerBiServiceMgt.SynchronizeReportsInBackground();
    end;

    local procedure GetEmbedUrl(): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
    begin
        if TempPowerBiReportBuffer.IsEmpty() then begin
            // Clear out last opened report if there are no reports to display.
            Clear(LastOpenedReportID);
            SetLastOpenedReportID(LastOpenedReportID);
        end else begin
            // update last loaded report
            SetLastOpenedReportID(TempPowerBiReportBuffer.ReportID);

            Session.LogMessage('0000C35', PowerBIReportLoadTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

            if not Uri.IsValidUri(TempPowerBiReportBuffer.ReportEmbedUrl) then begin
                Session.LogMessage('0000FFF', StrSubstNo(InvalidEmbedUriErr, StrLen(TempPowerBiReportBuffer.ReportEmbedUrl)), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
                exit(TempPowerBiReportBuffer.ReportEmbedUrl);
            end;

            // Hides both filters and tabs for embedding in small spaces where navigation is unnecessary.
            UriBuilder.Init(TempPowerBiReportBuffer.ReportEmbedUrl);
            UriBuilder.AddQueryParameter('filterPaneEnabled', 'false');
            UriBuilder.AddQueryParameter('disableBroswerDeprecationDialog', 'true');
            UriBuilder.AddQueryParameter('navContentPaneEnabled', 'false');

            UriBuilder.GetUri(Uri);
            exit(Uri.GetAbsoluteUri());
        end;
    end;

    local procedure GetEmbedUrlWithNavigation(): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
    begin
        // update last loaded report
        SetLastOpenedReportID(TempPowerBiReportBuffer.ReportID);

        if not Uri.IsValidUri(TempPowerBiReportBuffer.ReportEmbedUrl) then begin
            Session.LogMessage('0000FFG', StrSubstNo(InvalidEmbedUriErr, StrLen(TempPowerBiReportBuffer.ReportEmbedUrl)), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
            exit(TempPowerBiReportBuffer.ReportEmbedUrl);
        end;

        // Hides filters and shows tabs for embedding in large spaces where navigation is necessary.
        UriBuilder.Init(TempPowerBiReportBuffer.ReportEmbedUrl);
        UriBuilder.AddQueryParameter('filterPaneEnabled', 'false');
        UriBuilder.AddQueryParameter('disableBroswerDeprecationDialog', 'true');

        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    local procedure RefreshTempReportBuffer()
    var
        NullGuid: Guid;
    begin
        TempPowerBiReportBuffer.Reset();
        TempPowerBiReportBuffer.DeleteAll();

        TempPowerBiReportBuffer.Reset();
        TempPowerBiReportBuffer.SetFilter(Enabled, '%1', true);
        if not IsNullGuid(LastOpenedReportID) then begin
            TempPowerBiReportBuffer.SetRange(ReportID, LastOpenedReportID);

            if TempPowerBiReportBuffer.IsEmpty() then begin
                // If last selection is invalid, clear it and default to showing the first enabled report.
                SetLastOpenedReportID(NullGuid);
                TempPowerBiReportBuffer.SetRange(ReportID);
            end;
        end;

        HasReports := TempPowerBiReportBuffer.FindFirst();
    end;

    procedure SetContext(ParentContext: Text[30])
    begin
        // Sets an ID that tracks which page to show reports for - called by the parent page hosting the part,
        // if possible (see UpdateContext).
        Context := ParentContext;
    end;

    local procedure UpdateContext()
    begin
        // Automatically sets the parent page ID based on the user's selected role center (role centers can't
        // have codebehind, so they have no other way to set the context for their reports).
        if Context = '' then
            SetContext(PowerBiServiceMgt.GetEnglishContext());
    end;

    local procedure SetReport()
    begin
        if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::Phone, ClientType::Windows]) then
            CurrPage.WebReportViewer.InitializeIFrame(PowerBiServiceMgt.GetMainPageRatio());

        CurrPage.WebReportViewer.Navigate(GetEmbedUrl());
    end;

    procedure SetLastOpenedReportID(LastOpenedReportIDInputValue: Guid)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
    begin
        PowerBIUserConfiguration."Selected Report ID" := LastOpenedReportIDInputValue;
        PowerBIUserConfiguration.Modify();

        LastOpenedReportID := LastOpenedReportIDInputValue;
    end;

    local procedure SelectReports()
    var
        PowerBIWSReportSelection: Page "Power BI WS Report Selection";
    begin
        // Opens the report selection page, then updates the onscreen report depending on the user's
        // subsequent selection and enabled/disabled settings.
        PowerBIWSReportSelection.SetContext(Context);

        PowerBIWSReportSelection.LookupMode(true);

        PowerBIWSReportSelection.RunModal();
        if PowerBIWSReportSelection.IsPageClosedOkay() then begin
            if TempPowerBiReportBuffer.Enabled then begin
                LastOpenedReportID := TempPowerBiReportBuffer.ReportID; // RefreshAvailableReports handles fallback logic on invalid selection.
                SetLastOpenedReportID(LastOpenedReportID); // Resolves bug to set last selected report
            end;

            OpenPageOrRefresh(false);
            // At this point, NAV will load the web page viewer since HasReports should be true. WebReportViewer::ControlAddInReady will then fire, calling Navigate()
        end;
    end;

    local procedure LoadOptInImage()
    var
        MediaRepository: Record "Media Repository";
    begin
        if not MediaResources."Media Reference".HasValue() then begin
            if MediaRepository.GetForCurrentClientType(PowerBiOptInImageNameLbl) then
                if MediaResources.Get(MediaRepository."Media Resources Ref") then
                    exit;

            // Very old tenants might not have this image: let's not spam telemetry with warnings
            Session.LogMessage('0000BKH', StrSubstNo(NoOptInImageTxt, PowerBiOptInImageNameLbl), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
        end;
    end;

    [Scope('OnPrem')]
    procedure GetOptinImageName(): Text[250]
    begin
        exit(PowerBiOptInImageNameLbl);
    end;

    local procedure ShowError(NewErrorMessageText: Text)
    begin
        PageState := PageState::ErrorVisible;
        ErrorMessageText := NewErrorMessageText;
    end;

    [NonDebuggable]
    local procedure InitalizeAddIn()
    var
        LoadReportMessage: SecretText;
    begin
        if not TempPowerBiReportBuffer.IsEmpty() then
            if PowerBiEmbedHelper.TryGetLoadReportMessage(LoadReportMessage) then
                CurrPage.WebReportViewer.PostMessage(LoadReportMessage.Unwrap(), PowerBiEmbedHelper.TargetOrigin(), false)
            else
                ShowError(GetLastErrorText());
    end;
}
#endif