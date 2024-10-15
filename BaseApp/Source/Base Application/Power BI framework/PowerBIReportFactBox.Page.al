page 6306 "Power BI Report FactBox"
{
    Caption = 'Power BI Report';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            group(OptInControlGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::GetStarted;

                field(OptInGettingStarted; GettingStartedTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = TRUE;
                    ToolTipML = ENU = 'Specifies whether the Power BI functionality is enabled.';

                    trigger OnDrillDown()
                    var
                        PowerBIUserConfiguration: Record "Power BI User Configuration";
                        PowerBIEmbedSetupWizard: Page "Power BI Embed Setup Wizard";
                    begin
                        Session.LogMessage('0000E4A', PowerBiOptInTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

                        SetPowerBIUserConfig.CreateOrReadUserConfigEntry(PowerBIUserConfiguration, Context);
                        Commit();
                        LastOpenedReportID := PowerBIUserConfiguration."Selected Report ID";

                        if not PowerBISessionManager.GetHasPowerBILicense() then begin
                            PowerBIEmbedSetupWizard.SetContext(Context);
                            if PowerBIEmbedSetupWizard.RunModal() = Action::Cancel then
                                exit;
                        end else
                            StartAutoDeployment();

                        OpenPageOrRefresh(false); // The control add-in will load reports when ready
                    end;
                }
                field(OptInImageField1; MediaResources."Media Reference")
                {
                    CaptionML = ENU = '';
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
                    StyleExpr = TRUE;
                    ToolTipML = ENU = 'Specifies that the user can upload one or more demo reports for this page.';

                    trigger OnDrillDown()
                    begin
                        StartAutoDeployment();
                        Message(ReportsDeployingMsg);
                    end;
                }
            }
            group(Control3)
            {
                ShowCaption = false;
                Visible = PageState = PageState::ReportVisible;

                usercontrol(WebReportViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
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
                        if not TempPowerBiReportBuffer.IsEmpty() then
                            CurrPage.WebReportViewer.PostMessage(PowerBiEmbedHelper.GetLoadReportMessage(), PowerBiEmbedHelper.TargetOrigin(), false);
                    end;

                    trigger Callback(data: Text)
                    begin
                        HandleAddinCallback(data);
                    end;

                    trigger Refresh(callbackUrl: Text)
                    begin
                        if AddInReady and not TempPowerBiReportBuffer.IsEmpty() then
                            SetReport();
                    end;
                }
            }
            grid(Control12)
            {
                GridLayout = Columns;
                ShowCaption = false;

                group(Control11)
                {
                    ShowCaption = false;

#if not CLEAN18
                    group(Control10)
                    {
                        ShowCaption = false;
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'This control has been removed from this subpage. Option to set up Power BI is still available in "Power BI Report Spinner" page.';
                        ObsoleteTag = '18.0';

                        field(GettingStarted; GettingStartedTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            Style = StrongAccent;
                            StyleExpr = TRUE;
                            Visible = false;
                            ObsoleteState = Pending;
                            ObsoleteReason = 'This control has been removed from this subpage. Option to set up Power BI is still available in "Power BI Report Spinner" page.';
                            ToolTip = 'Specifies that the Azure AD setup window opens. ';
                            ObsoleteTag = '18.0';
                        }
                    }
#endif
                    group(Control8)
                    {
                        ShowCaption = false;
                        Visible = PageState = PageState::ErrorVisible;

                        field(ErrorMessageText; ErrorMessageText)
                        {
                            ApplicationArea = Basic, Suite;
                            MultiLine = true;
                            ShowCaption = false;
                            ToolTip = 'Specifies the error message from Power BI.';
                        }
#if not CLEAN18
                        field(ErrorUrlTextField; PowerBiServiceMgt.GetPowerBIUrl())
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = URL;
                            ShowCaption = false;
                            ToolTip = 'Specifies the link that generated the error.';
                            Visible = false;
                            ObsoleteState = Pending;
                            ObsoleteReason = 'Functionality to display a URL here in case of error is deprecated.';
                            ObsoleteTag = '18.0';
                        }
                        group(Control30)
                        {
                            ShowCaption = false;
                            Visible = false;
                            ObsoleteState = Pending;
                            ObsoleteReason = 'Functionality to open a page to select reports in case of error is deprecated';
                            ObsoleteTag = '18.0';

                            field(GetReportsLink; GetReportsTxt)
                            {
                                ApplicationArea = All;
                                Editable = false;
                                ShowCaption = false;
                                Style = StrongAccent;
                                StyleExpr = TRUE;
                                ToolTip = 'Specifies the reports.';
                                Visible = false;
                                ObsoleteState = Pending;
                                ObsoleteReason = 'Functionality to open a page to select reports in case of error is deprecated';
                                ObsoleteTag = '18.0';

                                trigger OnDrillDown()
                                begin
                                    SelectReports();
                                end;
                            }
                        }
#endif
                    }
                    group(Control6)
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
                            StyleExpr = TRUE;
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
                            StyleExpr = TRUE;
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
                            StyleExpr = TRUE;
                            ToolTip = 'Specifies that the user can refresh the page part. If reports have been deployed in the background, refreshing the page part will make them visible.';

                            trigger OnDrillDown()
                            begin
                                OpenPageOrRefresh(true);
                            end;
                        }
                    }
#if not CLEAN18
                    group(Control22)
                    {
                        ShowCaption = false;
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Functionality has been moved to page "Power BI Embed Setup Wizard"';
                        ObsoleteTag = '18.0';

                        label(InProgressMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Power BI report deployment is in progress.';
                            ToolTip = 'Specifies that the page is deploying reports to Power BI.';
                            Visible = false;
                            ObsoleteState = Pending;
                            ObsoleteReason = 'Functionality has been moved to page "Power BI Embed Setup Wizard"';
                            ObsoleteTag = '18.0';
                        }
                    }
                    group(Control28)
                    {
                        ShowCaption = false;
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Functionality has been moved to page "Power BI Embed Setup Wizard"';
                        ObsoleteTag = '18.0';

                        label(CheckLicenseMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Verifying your Power BI license.';
                            Editable = false;
                            ShowCaption = false;
                            Visible = false;
                            ObsoleteState = Pending;
                            ObsoleteReason = 'Functionality has been moved to page "Power BI Embed Setup Wizard"';
                            ToolTip = 'Specifies that the page is checking for Power BI license.';
                            ObsoleteTag = '18.0';
                        }
                    }
                    group(Control26)
                    {
                        ShowCaption = false;
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'This control has been merged with ErrorMessageText';
                        ObsoleteTag = '18.0';

                        label(ServiceUnavailableMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Power BI report deployment is currently unavailable.';
                            ToolTip = 'Specifies that the page cannot currently deploy reports to Power BI.';
                            Visible = false;
                            ObsoleteState = Pending;
                            ObsoleteReason = 'This control has been merged with ErrorMessageText';
                            ObsoleteTag = '18.0';
                        }
                    }
                    group(Control21)
                    {
                        ShowCaption = false;
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Setup is now done in the page "Power BI Embed Setup Wizard"';
                        ObsoleteTag = '18.0';

                        // UserControls do not support Obsolete properties
                        // Bug 380401: UserControl elements in a page do not support Obsolete* properties, but app fails to build if they are removed.
                        usercontrol(DeployTimer; "Microsoft.Dynamics.Nav.Client.PowerBIManagement")
                        {
                            ApplicationArea = All;
                            Visible = false;
                        }
                    }
#endif
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
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Expand Report';
                Enabled = PageState = PageState::ReportVisible;
                Image = View;
                ToolTip = 'View all information in the report.';

                trigger OnAction()
                var
                    PowerBiReportDialog: Page "Power BI Report Dialog";
                begin
                    PowerBiReportDialog.SetReportUrl(GetEmbedUrlWithNavigationWithFilters());
                    PowerBiReportDialog.Caption(TempPowerBiReportBuffer.ReportName);
                    PowerBiReportDialog.SetFilterValue(CurrentListSelection, CurrentReportFirstPage);
                    PowerBiReportDialog.Run();
                end;
            }
            action("Previous Report")
            {
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Page';
                Enabled = PageState <> PageState::GetStarted;
                Image = Refresh;
                ToolTip = 'Refresh the visible content.';

                trigger OnAction()
                begin
                    OpenPageOrRefresh(true);
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        IsSaaSUser := EnvironmentInfo.IsSaaS();
    end;

    trigger OnOpenPage()
    begin
        if IsVisible then
            OpenPageOrRefresh(false);
    end;

    var
        TempPowerBiReportBuffer: Record "Power BI Report Buffer" temporary;
        MediaResources: Record "Media Resources";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
        SetPowerBIUserConfig: Codeunit "Set Power BI User Config";
        PowerBiServiceMgt: Codeunit "Power BI Service Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        PowerBiEmbedHelper: Codeunit "Power BI Embed Helper";
        PowerBiOptInImageNameLbl: Label 'PowerBi-OptIn-480px.png', Locked = true;
        GettingStartedTxt: Label 'Get started with Power BI';
        DeployReportsTxt: Label 'Upload demo reports for this page';
        ReportsDeployingMsg: Label 'We are uploading a demo report to Power BI in the background for you. Once the upload finishes, choose Refresh to see it in this page.\\If you have already reports in your Power BI workspace, you can choose Select Reports instead.';
        StillDeployingMsg: Label 'We are still uploading your demo report. Once the upload finishes, choose Refresh again to see it in this page.\\If you have already reports in your Power BI workspace, you can choose Select Reports instead.';
        RefreshPartTxt: Label 'Refresh';
        SelectReportsTxt: Label 'Select reports';
        PageState: Option GetStarted,ShouldDeploy,NoReport,NoReportButDeploying,ReportVisible,ErrorVisible;
        LastOpenedReportID: Guid;
        Context: Text[30];
        NameFilter: Text;
        HasReports: Boolean;
        AddInReady: Boolean;
        ErrorMessageText: Text;
        CurrentListSelection: Text;
        LatestReceivedFilterInfo: Text;
        CurrentReportFirstPage: Text;
        IsSaaSUser: Boolean;
        IsVisible: Boolean;
        // Telemetry labels
        NoOptInImageTxt: Label 'There is no Power BI Opt-in image in the Database with ID: %1', Locked = true;
        PowerBIReportLoadTelemetryMsg: Label 'Loading Power BI report for user', Locked = true;
        PowerBiOptInTxt: Label 'User has opted in to enable Power BI services in factbox', Locked = true;

#if not CLEAN18
        GetReportsTxt: Label 'Get reports';
#endif

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
        ExceptionMessage: Text;
        ExceptionDetails: Text;
    begin
        // No license has been verified yet
        if not PowerBISessionManager.GetHasPowerBILicense() then begin
            LoadOptInImage();
            PageState := PageState::GetStarted;
            exit;
        end;

        SetPowerBIUserConfig.CreateOrReadUserConfigEntry(PowerBIUserConfiguration, Context);
        LastOpenedReportID := PowerBIUserConfiguration."Selected Report ID";
        RefreshTempReportBuffer(ExceptionMessage, ExceptionDetails); // Also points the record to last opened report id

        if ExceptionMessage <> '' then begin
            ShowErrorMessage(ExceptionMessage);
            exit;
        end;

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
        DummyPowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        // Ensure user config for context before deployment
        if Context = '' then
            exit;

        SetPowerBIUserConfig.CreateOrReadUserConfigEntry(DummyPowerBIUserConfiguration, Context);
        PowerBIReportSynchronizer.SelectDefaultReports();
        PowerBiServiceMgt.SynchronizeReportsInBackground();
    end;

    local procedure GetEmbedUrl(): Text
    begin
        if TempPowerBiReportBuffer.IsEmpty() then begin
            // Clear out last opened report if there are no reports to display.
            Clear(LastOpenedReportID);
            SetLastOpenedReportID(LastOpenedReportID);
        end else begin
            // update last loaded report
            SetLastOpenedReportID(TempPowerBiReportBuffer.ReportID);

            Session.LogMessage('0000C36', PowerBIReportLoadTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
            // Hides both filters and tabs for embedding in small spaces where navigation is unnecessary.
            exit(TempPowerBiReportBuffer.ReportEmbedUrl + '&filterPaneEnabled=false&navContentPaneEnabled=false');
        end;
    end;

    local procedure GetEmbedUrlWithNavigationWithFilters(): Text
    begin
        // update last loaded report
        SetLastOpenedReportID(TempPowerBiReportBuffer.ReportID);
        // Shows filters and shows navigation tabs.
        exit(TempPowerBiReportBuffer.ReportEmbedUrl);
    end;

    local procedure RefreshTempReportBuffer(var ExceptionMessage: Text; var ExceptionDetails: Text)
    var
        NullGuid: Guid;
    begin
        TempPowerBiReportBuffer.Reset();
        TempPowerBiReportBuffer.DeleteAll();

        PowerBiServiceMgt.GetReportsForUserContext(TempPowerBiReportBuffer, ExceptionMessage, ExceptionDetails, Context);
        if ExceptionMessage <> '' then
            exit;

        PowerBiServiceMgt.UpdateEmbedUrlCache(TempPowerBiReportBuffer, Context);

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

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
    procedure SetNameFilter(ParentFilter: Text)
    begin
        // Sets a text value that tells the selection page how to filter the reports list. This should be called
        // by the parent page hosting this page part, if possible.
        NameFilter := ParentFilter;
    end;

    local procedure ShowErrorMessage(TextToShow: Text)
    begin
        PageState := PageState::ErrorVisible;

        if TextToShow = '' then
            TextToShow := PowerBiServiceMgt.GetGenericError();
        ErrorMessageText := TextToShow;
        CurrPage.Update();
    end;

    local procedure SetReport()
    var
        JsonArray: DotNet Array;
        DotNetString: DotNet String;
    begin
        if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::Phone, ClientType::Windows]) then
            CurrPage.WebReportViewer.InitializeIFrame('4:3');
        // subscribe to events
        CurrPage.WebReportViewer.SubscribeToEvent('message', GetEmbedUrl());
        CurrPage.WebReportViewer.Navigate(GetEmbedUrl());
        JsonArray := JsonArray.CreateInstance(GetDotNetType(DotNetString), 1);
        JsonArray.SetValue('{"statusCode":202,"headers":{}}', 0);
        CurrPage.WebReportViewer.SetCallbacksFromSubscribedEventToIgnore('message', JsonArray);
    end;

    [Scope('OnPrem')]
    procedure SetLastOpenedReportID(LastOpenedReportIDInputValue: Guid)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
    begin
        SetPowerBIUserConfig.CreateOrReadUserConfigEntry(PowerBIUserConfiguration, Context);
        PowerBIUserConfiguration."Selected Report ID" := LastOpenedReportIDInputValue;
        PowerBIUserConfiguration.Modify();

        LastOpenedReportID := LastOpenedReportIDInputValue;
    end;

    local procedure SelectReports()
    var
        PowerBIReportSelection: Page "Power BI Report Selection";
        PrevNameFilter: Text;
    begin
        // Opens the report selection page, then updates the onscreen report depending on the user's
        // subsequent selection and enabled/disabled settings.
        PowerBIReportSelection.SetContext(Context);
        PrevNameFilter := NameFilter;
        if Context <> '' then begin
            NameFilter := PowerBiServiceMgt.GetFactboxFilterFromID(Context);
            if NameFilter = '' then
                NameFilter := PrevNameFilter;
        end;
        PowerBIReportSelection.SetNameFilter(NameFilter);
        PowerBIReportSelection.LookupMode(true);

        PowerBIReportSelection.RunModal();
        if PowerBIReportSelection.IsPageClosedOkay() then begin
            PowerBIReportSelection.GetRecord(TempPowerBiReportBuffer);

            if TempPowerBiReportBuffer.Enabled then begin
                LastOpenedReportID := TempPowerBiReportBuffer.ReportID; // RefreshAvailableReports handles fallback logic on invalid selection.
                SetLastOpenedReportID(LastOpenedReportID); // Resolves bug to set last selected report
            end;

            OpenPageOrRefresh(false);
        end;
    end;

    procedure SetFactBoxVisibility(var VisibilityInput: Boolean)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
    begin
        if VisibilityInput then
            VisibilityInput := false
        else
            VisibilityInput := true;

        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("Page ID", '%1', Context);
        PowerBIUserConfiguration.SetFilter("User Security ID", '%1', UserSecurityId());
        PowerBIUserConfiguration.SetFilter("Profile ID", '%1', PowerBiServiceMgt.GetEnglishContext());
        if PowerBIUserConfiguration.FindFirst() then begin
            PowerBIUserConfiguration."Report Visibility" := VisibilityInput;
            PowerBIUserConfiguration.Modify();
        end;
        if VisibilityInput then
            OpenPageOrRefresh(false);
    end;

#if not CLEAN16
    [Scope('OnPrem')]
    [Obsolete('Use HandleAddinCallback instead', '16.0')]
    procedure GetAndSetReportFilter(data: Text)
    begin
        HandleAddinCallback(data);
    end;
#endif

    [Scope('OnPrem')]
    procedure HandleAddinCallback(CallbackMessage: Text)
    var
        MessageForWebPage: Text;
    begin
        PowerBiEmbedHelper.HandleAddInCallback(CallbackMessage, CurrentListSelection, CurrentReportFirstPage, LatestReceivedFilterInfo, MessageForWebPage);
        if MessageForWebPage <> '' then
            CurrPage.WebReportViewer.PostMessage(MessageForWebPage, PowerBiEmbedHelper.TargetOrigin(), true);
    end;

    procedure InitFactBox(PageId: Text[30]; PageCaption: Text; var PowerBIVisible: Boolean)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
    begin
        // Initialize Factbox and make it visibile only if the user has a Power BI License
        IF PowerBISessionManager.GetHasPowerBILicense() then begin
            SetNameFilter(PageCaption);
            SetContext(PageId);
            PowerBIVisible := SetPowerBIUserConfig.SetUserConfig(PowerBIUserConfiguration, PageId);
        end;
        IsVisible := PowerBIVisible;
    end;

    procedure SetCurrentListSelection(CurrentSelection: Text; IsValueIntInput: Boolean; PowerBIVisible: Boolean)
    begin
        if not PowerBIVisible then
            exit;
        // get the name of the selected element from the corresponding list of the parent page and filter the report
        CurrentListSelection := PowerBiServiceMgt.FormatSpecialChars(CurrentSelection);
        if not IsValueIntInput then
            CurrentListSelection := '"' + CurrentListSelection + '"';

        // Selection changed: send the latest message to the Addin again with the updated selection, if we have the filter info already
        if LatestReceivedFilterInfo <> '' then
            HandleAddinCallback(LatestReceivedFilterInfo);
    end;

    local procedure LoadOptInImage()
    var
        MediaRepository: Record "Media Repository";
    begin
        if not MediaResources."Media Reference".HasValue() then begin
            if MediaRepository.Get(PowerBiOptInImageNameLbl, Format(ClientTypeManagement.GetCurrentClientType())) then
                if MediaResources.Get(MediaRepository."Media Resources Ref") then
                    exit;

            Session.LogMessage('0000E4U', StrSubstNo(NoOptInImageTxt, PowerBiOptInImageNameLbl), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
        end;
    end;

}

