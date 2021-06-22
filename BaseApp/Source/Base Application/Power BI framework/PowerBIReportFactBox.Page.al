page 6306 "Power BI Report FactBox"
{
    Caption = 'Power BI Report';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            group(Control3)
            {
                ShowCaption = false;
                Visible = NOT IsGettingStartedVisible AND NOT IsErrorMessageVisible AND HasReports;
                usercontrol(WebReportViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                {
                    ApplicationArea = Basic, Suite;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        AddInReady := true;
                        if not TempPowerBiReportBuffer.IsEmpty then
                            SetReport;
                    end;

                    trigger DocumentReady()
                    begin
                        if not TempPowerBiReportBuffer.IsEmpty then
                            CurrPage.WebReportViewer.PostMessage(PowerBiEmbedHelper.GetLoadReportMessage(), PowerBiEmbedHelper.TargetOrigin(), false);
                    end;

                    trigger Callback(data: Text)
                    begin
                        HandleAddinCallback(data);
                    end;

                    trigger Refresh(callbackUrl: Text)
                    begin
                        if AddInReady and not TempPowerBiReportBuffer.IsEmpty then
                            SetReport;
                    end;
                }
            }
            group(Control12)
            {
                //The GridLayout property is only supported on controls of type Grid
                //GridLayout = Columns;
                ShowCaption = false;
                group(Control11)
                {
                    ShowCaption = false;
                    group(Control10)
                    {
                        ShowCaption = false;
                        Visible = IsGettingStartedVisible;
                        field(GettingStarted; GettingStartedTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            Style = StrongAccent;
                            StyleExpr = TRUE;
                            ToolTip = 'Specifies the process of connecting to Power BI.';

                            trigger OnDrillDown()
                            begin
                                if not TryAzureAdMgtGetAccessToken then
                                    ShowErrorMessage(GetLastErrorText);

                                PowerBiServiceMgt.SelectDefaultReports;
                                LoadContent;
                            end;
                        }
                    }
                    group(Control8)
                    {
                        ShowCaption = false;
                        Visible = IsErrorMessageVisible;
                        field(ErrorMessageText; ErrorMessageText)
                        {
                            ApplicationArea = Basic, Suite;
                            MultiLine = true;
                            ShowCaption = false;
                            ToolTip = 'Specifies the error message from Power BI.';
                        }
                        field(ErrorUrlTextField; PowerBiServiceMgt.GetPowerBIUrl)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = URL;
                            ShowCaption = false;
                            ToolTip = 'Specifies the link that generated the error.';
                            Visible = IsUrlFieldVisible;
                        }
                        group(Control30)
                        {
                            ShowCaption = false;
                            Visible = IsGetReportsVisible;
                            field(GetReportsLink; GetReportsTxt)
                            {
                                ApplicationArea = All;
                                Editable = false;
                                ShowCaption = false;
                                Style = StrongAccent;
                                StyleExpr = TRUE;
                                ToolTip = 'Specifies the reports.';

                                trigger OnDrillDown()
                                begin
                                    SelectReports;
                                end;
                            }
                        }
                    }
                    group(Control6)
                    {
                        ShowCaption = false;
                        Visible = NOT IsGettingStartedVisible AND NOT IsErrorMessageVisible AND NOT HasReports AND NOT IsDeployingReports AND NOT IsLicenseTimerActive AND NOT CheckingLicenseInBackground;
                        label(EmptyMessage)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'There are no enabled reports. Choose Select Report to see a list of reports that you can display.';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies that the user needs to select Power BI reports.';
                            Visible = NOT IsDeployingReports;
                        }
                    }
                    group(Control22)
                    {
                        ShowCaption = false;
                        Visible = NOT IsDeploymentUnavailable AND IsDeployingReports AND NOT HasReports AND NOT CheckingLicenseInBackground;
                        label(InProgressMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Power BI report deployment is in progress.';
                            ToolTip = 'Specifies that the page is deploying reports to Power BI.';
                        }
                    }
                    group(Control28)
                    {
                        ShowCaption = false;
                        Visible = IsLicenseTimerActive OR CheckingLicenseInBackground AND NOT IsDeployingReports AND NOT IsErrorMessageVisible;
                        label(CheckLicenseMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Verifying your Power BI license.';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies that the page is checking for Power BI license.';
                        }
                    }
                    group(Control26)
                    {
                        ShowCaption = false;
                        Visible = IsDeploymentUnavailable AND NOT IsDeployingReports AND NOT HasReports;
                        label(ServiceUnavailableMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Power BI report deployment is currently unavailable.';
                            ToolTip = 'Specifies that the page cannot currently deploy reports to Power BI.';
                        }
                    }
                    group(Control21)
                    {
                        ShowCaption = false;
                        usercontrol(DeployTimer; "Microsoft.Dynamics.Nav.Client.PowerBIManagement")
                        {
                            ApplicationArea = All;

                            trigger AddInReady()
                            begin
                                // Timer for refreshing the page during Out of Box report deployment started by another page.
                                IsTimerReady := true;
                                StartLicenseTimer;
                                if not CheckingLicenseInBackground and IsDeployingReports and not IsErrorMessageVisible then
                                    StartDeploymentTimer;
                            end;

                            trigger Pong()
                            var
                                HasPowerBILicense: Boolean;
                                MaxTimerCount: Integer;
                            begin
                                HasPowerBILicense := PowerBiServiceMgt.CheckForPowerBILicense;
                                IsLicenseTimerActive := not HasPowerBILicense;
                                CheckingLicenseInBackground := not HasPowerBILicense;

                                MaxTimerCount := (60000 * 5) / TimerDelay; // Set the max count so that it doesn't exceed five minutes

                                if HasPowerBILicense then begin
                                    RefreshPart;

                                    if IsTimerActive and not IsLicenseTimerActive and not CheckingLicenseInBackground
                                    then begin
                                        PowerBiServiceMgt.SelectDefaultReports;
                                        DeployDefaultReports;

                                        IsDeployingReports := PowerBiServiceMgt.GetIsDeployingReports;

                                        CurrentTimerCount := CurrentTimerCount + 1;
                                        IsTimerActive := IsDeployingReports and (CurrentTimerCount < MaxTimerCount) and not IsErrorMessageVisible;
                                        if IsTimerActive then
                                            CurrPage.DeployTimer.Ping(TimerDelay)
                                        else begin
                                            PowerBiServiceMgt.SetIsDeployingReports(false);
                                            IsDeployingReports := false;
                                            CurrPage.DeployTimer.Stop;
                                            CurrPage.Update;
                                        end;
                                    end;
                                end else begin
                                    ShowErrorMessage(PowerBiServiceMgt.GetUnauthorizedErrorText);
                                    CurrPage.DeployTimer.Stop;
                                end;

                                if not IsDeployingReports and HasReports then
                                    CurrPage.DeployTimer.Stop;
                            end;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Select Report';
                Enabled = NOT IsGettingStartedVisible AND NOT IsErrorMessageVisible;
                Image = SelectChart;
                ToolTip = 'Select the report.';

                trigger OnAction()
                begin
                    SelectReports;
                end;
            }
            action("Expand Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expand Report';
                Enabled = HasReports AND NOT IsErrorMessageVisible;
                Image = View;
                ToolTip = 'View all information in the report.';

                trigger OnAction()
                var
                    PowerBiReportDialog: Page "Power BI Report Dialog";
                begin
                    PowerBiReportDialog.SetUrl(GetEmbedUrlWithNavigationWithFilters, PowerBiEmbedHelper.GetLoadReportMessage());
                    PowerBiReportDialog.Caption(TempPowerBiReportBuffer.ReportName);
                    PowerBiReportDialog.SetFilter(messagefilter, CurrentReportFirstPage);
                    PowerBiReportDialog.Run;
                end;
            }
            action("Previous Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Report';
                Enabled = HasReports AND NOT IsErrorMessageVisible;
                Image = PreviousSet;
                ToolTip = 'Go to the previous report.';

                trigger OnAction()
                begin
                    // need to reset filters or it would load the LastLoadedReport otherwise
                    TempPowerBiReportBuffer.Reset();
                    TempPowerBiReportBuffer.SetFilter(Enabled, '%1', true);
                    if TempPowerBiReportBuffer.Next(-1) = 0 then
                        TempPowerBiReportBuffer.FindLast;

                    if AddInReady then
                        CurrPage.WebReportViewer.Navigate(GetEmbedUrl);
                end;
            }
            action("Next Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Report';
                Enabled = HasReports AND NOT IsErrorMessageVisible;
                Image = NextSet;
                ToolTip = 'Go to the next report.';

                trigger OnAction()
                begin
                    // need to reset filters or it would load the LastLoadedReport otherwise
                    TempPowerBiReportBuffer.Reset();
                    TempPowerBiReportBuffer.SetFilter(Enabled, '%1', true);
                    if TempPowerBiReportBuffer.Next = 0 then
                        TempPowerBiReportBuffer.FindFirst;

                    if AddInReady then
                        CurrPage.WebReportViewer.Navigate(GetEmbedUrl);
                end;
            }
            action(Refresh)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Page';
                Enabled = NOT IsGettingStartedVisible;
                Image = Refresh;
                ToolTip = 'Refresh the visible content.';

                trigger OnAction()
                begin
                    RefreshPart;
                end;
            }
            action("Manage Report")
            {
                ApplicationArea = All;
                Caption = 'Manage Report';
                Enabled = HasReports AND NOT IsErrorMessageVisible;
                Image = PowerBI;
                ToolTip = 'Opens current selected report for edits.';
                Visible = IsSaaSUser;

                trigger OnAction()
                var
                    PowerBIManagement: Page "Power BI Management";
                begin
                    PowerBIManagement.SetTargetReport(LastOpenedReportID, GetEmbedUrl);
                    PowerBIManagement.LookupMode(true);
                    PowerBIManagement.Run;
                    RefreshPart;
                end;
            }
        }
    }

    trigger OnInit()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
    begin
        IsSaaSUser := AzureAdMgt.IsSaaS();

        // Variables used by PingPong timer when deploying default PBI reports.
        TimerDelay := 30000; // 30 seconds
        IsVisible := false;
    end;

    trigger OnOpenPage()
    begin
        if IsVisible then
            LoadFactBox
    end;

    var
        NoReportsAvailableErr: Label 'There are no reports available from Power BI.';
        GettingStartedTxt: Label 'Get started with Power BI';
        GetReportsTxt: Label 'Get reports';
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        TempPowerBiReportBuffer: Record "Power BI Report Buffer" temporary;
        PowerBiServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBiEmbedHelper: Codeunit "Power BI Embed Helper";
        ClientTypeManagement: Codeunit "Client Type Management";
        LastOpenedReportID: Guid;
        Context: Text[30];
        NameFilter: Text;
        IsGettingStartedVisible: Boolean;
        HasReports: Boolean;
        AddInReady: Boolean;
        IsErrorMessageVisible: Boolean;
        ErrorMessageText: Text;
        IsUrlFieldVisible: Boolean;
        IsGetReportsVisible: Boolean;
        CurrentListSelection: Text;
        LatestReceivedFilterInfo: Text;
        messagefilter: Text;
        CurrentReportFirstPage: Text;
        TimerDelay: Integer;
        CurrentTimerCount: Integer;
        IsDeployingReports: Boolean;
        IsDeploymentUnavailable: Boolean;
        IsTimerReady: Boolean;
        IsTimerActive: Boolean;
        IsSaaSUser: Boolean;
        IsLoaded: Boolean;
        IsVisible: Boolean;
        IsLicenseTimerActive: Boolean;
        CheckingLicenseInBackground: Boolean;

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

    local procedure GetEmbedUrl(): Text
    begin
        if TempPowerBiReportBuffer.IsEmpty then begin
            // Clear out last opened report if there are no reports to display.
            Clear(LastOpenedReportID);
            SetLastOpenedReportID(LastOpenedReportID);
        end else begin
            // update last loaded report
            SetLastOpenedReportID(TempPowerBiReportBuffer.ReportID);
            // Hides both filters and tabs for embedding in small spaces where navigation is unnecessary.
            exit(TempPowerBiReportBuffer.ReportEmbedUrl + '&filterPaneEnabled=false&navContentPaneEnabled=false');
        end;
    end;

    local procedure LoadContent()
    var
        ExceptionMessage: Text;
        ExceptionDetails: Text;
    begin
        // The end to end process for loading reports onscreen, or defaulting to an error state if that fails,
        // including deploying default reports in case they haven't been loaded yet. Called when first logging
        // into Power BI or any time the part has reloaded from scratch.
        if not TryLoadPart(ExceptionMessage, ExceptionDetails) then
            ShowErrorMessage(GetLastErrorText);

        // Always call this after TryLoadPart. Since we can't modify record from a TryFunction.
        PowerBiServiceMgt.UpdateEmbedUrlCache(TempPowerBiReportBuffer, Context);

        // Always call this function after calling TryLoadPart to log exceptions to ActivityLog table
        if ExceptionMessage <> '' then
            SendTraceTag('0000B74', PowerBiServiceMgt.GetPowerBiTelemetryCategory(),
                VERBOSITY::Error, ExceptionMessage + ' : ' + ExceptionDetails, DATACLASSIFICATION::CustomerContent);

        if not IsGettingStartedVisible then
            CheckPowerBILicense;

        CurrPage.Update;

        DeployDefaultReports();
    end;

    local procedure RefreshAvailableReports()
    begin
        // Filters the report buffer to show the user's selected report onscreen if possible, otherwise defaulting
        // to other enabled reports.
        // (The updated selection will automatically get saved on render - can't save to database here without
        // triggering errors about calling MODIFY during a TryFunction.)

        TempPowerBiReportBuffer.Reset();
        TempPowerBiReportBuffer.SetFilter(Enabled, '%1', true);
        if not IsNullGuid(LastOpenedReportID) then begin
            TempPowerBiReportBuffer.SetFilter(ReportID, '%1', LastOpenedReportID);

            if TempPowerBiReportBuffer.IsEmpty then begin
                // If last selection is invalid, clear it and default to showing the first enabled report.
                Clear(LastOpenedReportID);
                RefreshAvailableReports();
            end;
        end;

        HasReports := TempPowerBiReportBuffer.FindFirst();
    end;

    local procedure RefreshPart()
    var
        SetPowerBIUserConfig: Codeunit "Set Power BI User Config";
    begin
        // Refreshes content by re-rendering the whole page part - removes any current error message text, and tries to
        // reload the user's list of reports, as if the page just loaded. Used by the Refresh button or when closing the
        // Select Reports page, to make sure we have the most up to date list of reports and aren't stuck in an error state.
        IsErrorMessageVisible := false;
        IsUrlFieldVisible := false;
        IsGetReportsVisible := false;

        IsDeployingReports := PowerBiServiceMgt.GetIsDeployingReports();
        IsDeploymentUnavailable := not PowerBiServiceMgt.IsPBIServiceAvailable();

        PowerBiServiceMgt.SelectDefaultReports();

        SetPowerBIUserConfig.CreateOrReadUserConfigEntry(PowerBIUserConfiguration, LastOpenedReportID, Context);
        LoadContent();

        if AddInReady then
            CurrPage.WebReportViewer.Navigate(GetEmbedUrl());
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
            SetContext(PowerBiServiceMgt.GetEnglishContext);
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
        // this condition checks if we caught the authorization error that contains a link to Power BI
        // the function divide the error message into simple text and url part
        if TextToShow = PowerBiServiceMgt.GetUnauthorizedErrorText() then begin
            IsUrlFieldVisible := true;
            // this message is required to have ':' at the end, but it has '.' instead due to C/AL Localizability requirement
            TextToShow := DelStr(PowerBiServiceMgt.GetUnauthorizedErrorText(), StrLen(PowerBiServiceMgt.GetUnauthorizedErrorText()), 1) + ':';
        end;

        IsGetReportsVisible := (TextToShow = NoReportsAvailableErr);

        IsErrorMessageVisible := true;
        IsGettingStartedVisible := false;
        TempPowerBiReportBuffer.DeleteAll(); // Required to avoid one INSERT after another (that will lead to an error)
        if TextToShow = '' then
            TextToShow := PowerBiServiceMgt.GetGenericError;
        ErrorMessageText := TextToShow;
        TempPowerBiReportBuffer.Insert(); // Hack to show the field with the text
        CurrPage.Update;
    end;

    [TryFunction]
    local procedure TryLoadPart(var ExceptionMessage: Text; var ExceptionDetails: Text)
    begin
        IsGettingStartedVisible := not PowerBiServiceMgt.IsUserReadyForPowerBI;

        TempPowerBiReportBuffer.Reset();
        TempPowerBiReportBuffer.DeleteAll();
        if IsGettingStartedVisible then begin
            if IsSaasUser then
                Error(PowerBiServiceMgt.GetGenericError);

            TempPowerBiReportBuffer.Insert // Hack to display Get Started link.
        end else begin
            PowerBiServiceMgt.GetReportsForUserContext(TempPowerBiReportBuffer, ExceptionMessage, ExceptionDetails, Context);
            RefreshAvailableReports;
        end;
    end;

    [TryFunction]
    local procedure TryAzureAdMgtGetAccessToken()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
    begin
        AzureAdMgt.GetAccessToken(PowerBiServiceMgt.GetPowerBIResourceUrl, PowerBiServiceMgt.GetPowerBiResourceName, true);
    end;

    local procedure SetReport()
    var
        JsonArray: DotNet Array;
        DotNetString: DotNet String;
    begin
        if (ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Phone) and
           (ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Windows)
        then
            CurrPage.WebReportViewer.InitializeIFrame('4:3');
        // subscribe to events
        CurrPage.WebReportViewer.SubscribeToEvent('message', GetEmbedUrl);
        CurrPage.WebReportViewer.Navigate(GetEmbedUrl);
        JsonArray := JsonArray.CreateInstance(GetDotNetType(DotNetString), 1);
        JsonArray.SetValue('{"statusCode":202,"headers":{}}', 0);
        CurrPage.WebReportViewer.SetCallbacksFromSubscribedEventToIgnore('message', JsonArray);
    end;

    [Scope('OnPrem')]
    procedure SetLastOpenedReportID(LastOpenedReportIDInput: Guid)
    begin
        // update the last loaded report field (the record at this point should already exist bacause it was created OnOpenPage)
        LastOpenedReportID := LastOpenedReportIDInput;
        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("Page ID", '%1', Context);
        PowerBIUserConfiguration.SetFilter("User Security ID", '%1', UserSecurityId);
        PowerBIUserConfiguration.SetFilter("Profile ID", '%1', PowerBiServiceMgt.GetEnglishContext);
        if not PowerBIUserConfiguration.IsEmpty then begin
            PowerBIUserConfiguration."Selected Report ID" := LastOpenedReportID;
            PowerBIUserConfiguration.Modify();
            Commit();
        end;
    end;

    procedure SetFactBoxVisibility(var VisibilityInput: Boolean)
    begin
        if VisibilityInput then
            VisibilityInput := false
        else
            VisibilityInput := true;

        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("Page ID", '%1', Context);
        PowerBIUserConfiguration.SetFilter("User Security ID", '%1', UserSecurityId);
        PowerBIUserConfiguration.SetFilter("Profile ID", '%1', PowerBiServiceMgt.GetEnglishContext);
        if PowerBIUserConfiguration.FindFirst then begin
            PowerBIUserConfiguration."Report Visibility" := VisibilityInput;
            PowerBIUserConfiguration.Modify();
        end;
        if VisibilityInput and not IsLoaded then
            LoadFactBox
    end;

    [Scope('OnPrem')]
    [Obsolete('Use HandleAddinCallback instead','16.0')]
    procedure GetAndSetReportFilter(data: Text)
    begin
        HandleAddinCallback(data);
    end;

    [Scope('OnPrem')]
    procedure HandleAddinCallback(CallbackMessage: Text)
    var
        MessageForWebPage: Text;
    begin
        PowerBiEmbedHelper.HandleAddInCallback(CallbackMessage, CurrentListSelection, CurrentReportFirstPage, LatestReceivedFilterInfo, MessageForWebPage);
        if MessageForWebPage <> '' then
            CurrPage.WebReportViewer.PostMessage(MessageForWebPage, PowerBiEmbedHelper.TargetOrigin(), true);
    end;

    local procedure GetEmbedUrlWithNavigationWithFilters(): Text
    begin
        // update last loaded report
        SetLastOpenedReportID(TempPowerBiReportBuffer.ReportID);
        // Shows filters and shows navigation tabs.
        exit(TempPowerBiReportBuffer.ReportEmbedUrl);
    end;

    local procedure SelectReports()
    var
        PowerBIReportSelection: Page "Power BI Report Selection";
        EmbedUrl: Text;
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

        PowerBIReportSelection.RunModal;
        if PowerBIReportSelection.IsPageClosedOkay then begin
            PowerBIReportSelection.GetRecord(TempPowerBiReportBuffer);

            if TempPowerBiReportBuffer.Enabled then begin
                LastOpenedReportID := TempPowerBiReportBuffer.ReportID; // RefreshAvailableReports handles fallback logic on invalid selection.
                SetLastOpenedReportID(LastOpenedReportID); // Resolves bug to set last selected report
            end;

            RefreshPart;
            EmbedUrl := GetEmbedUrl;
            if AddInReady and (EmbedUrl <> '') then
                CurrPage.WebReportViewer.Navigate(GetEmbedUrl);
            // At this point, NAV will load the web page viewer since HasReports should be true. WebReportViewer::ControlAddInReady will then fire, calling Navigate()
        end;
    end;

    local procedure DeployDefaultReports()
    begin
        if not PowerBiServiceMgt.IsPowerBIDeploymentEnabled then
            exit;

        // Checks if there are any default reports the user needs to upload/select, and automatically begins
        // those processes. The page will refresh when the PingPong control runs later.
        DeleteMarkedReports;
        FinishPartialUploads;
        if not CheckingLicenseInBackground and not IsGettingStartedVisible and not IsErrorMessageVisible and IsSaasUser and
           PowerBiServiceMgt.UserNeedsToDeployReports(Context) and not PowerBiServiceMgt.IsUserDeployingReports
        then begin
            IsDeployingReports := true;
            PowerBiServiceMgt.UploadDefaultReportInBackground;
            StartDeploymentTimer;
        end;
    end;

    local procedure FinishPartialUploads()
    begin
        // Checks if there are any default reports whose uploads only partially completed, and begins a
        // background process for those reports. The page will refresh when the PingPong control runs later.
        if not CheckingLicenseInBackground and not IsGettingStartedVisible and not IsErrorMessageVisible and IsSaasUser and
           PowerBiServiceMgt.UserNeedsToRetryUploads and not PowerBiServiceMgt.IsUserRetryingUploads
        then begin
            IsDeployingReports := true;
            PowerBiServiceMgt.RetryUnfinishedReportsInBackground;
            StartDeploymentTimer;
        end;
    end;

    local procedure DeleteMarkedReports()
    begin
        // Checks if there are any default reports that have been marked to be deleted on page 6321, and begins
        // a background process for those reports. The page will refresh when the timer control runs later.
        if not CheckingLicenseInBackground and not IsGettingStartedVisible and not IsErrorMessageVisible and IsSaasUser and
           PowerBiServiceMgt.UserNeedsToDeleteReports and not PowerBiServiceMgt.IsUserDeletingReports
        then begin
            IsDeployingReports := true;
            PowerBiServiceMgt.DeleteDefaultReportsInBackground;
            StartDeploymentTimer;
        end;
    end;

    local procedure StartDeploymentTimer()
    begin
        // Resets the timer for refreshing the page during Out of Box report deployment, if the add-in is
        // ready to go and the timer isn't already going. (This page doesn't deploy reports itself,
        // but it may be opened while another page is deploying reports that would show up here.)
        if IsTimerReady and not IsTimerActive and not IsLicenseTimerActive then begin
            CurrentTimerCount := 0;
            IsTimerActive := true;
            CurrPage.DeployTimer.Ping(TimerDelay);
        end;
    end;

    procedure InitFactBox(PageId: Text[30]; PageCaption: Text; var PowerBIVisible: Boolean)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        SetPowerBIUserConfig: Codeunit "Set Power BI User Config";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
    begin
        // Initialize Factbox and make it visibile only if the user has a Power BI License
        IF PowerBISessionManager.GetHasPowerBILicense() then begin
            SetNameFilter(PageCaption);
            SetContext(PageId);
            PowerBIVisible := SetPowerBIUserConfig.SetUserConfig(PowerBIUserConfiguration, PageId);
        end;
        IsVisible := PowerBIVisible;
    end;

    local procedure LoadFactBox()
    begin
        UpdateContext;
        RefreshPart;
        IsLoaded := true;
    end;

    local procedure StartLicenseTimer()
    begin
        if CheckingLicenseInBackground and IsTimerReady and not IsLicenseTimerActive and not IsTimerActive then begin
            CurrentTimerCount := 0;
            IsLicenseTimerActive := true;
            CurrPage.DeployTimer.Ping(TimerDelay);
        end;
    end;

    local procedure CheckPowerBILicense()
    begin
        if not PowerBiServiceMgt.CheckForPowerBILicense then begin
            CheckingLicenseInBackground := true;
            StartLicenseTimer;
        end;
    end;
}

