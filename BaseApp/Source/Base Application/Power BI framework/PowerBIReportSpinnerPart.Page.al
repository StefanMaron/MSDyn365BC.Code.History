page 6303 "Power BI Report Spinner Part"
{
    Caption = 'Power BI Reports';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            group(control28)
            {
                ShowCaption = false;
                Visible = OptInVisible;

                field(OptInGettingStarted; GettingStartedTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = TRUE;
                    ToolTipML = ENU = 'Specifies whether the Power BI functionality is enabled.';

                    trigger OnDrillDown()
                    begin
                        UserOptedIn := true;
                        OptInVisible := false;
                        SendTraceTag('0000B72', PowerBiServiceMgt.GetPowerBiTelemetryCategory(), Verbosity::Normal, PowerBiOptInTxt, DataClassification::SystemMetadata);
                        HasPowerBIPermissions := PowerBiServiceMgt.CheckPowerBITablePermissions(); // check if user has all table permissions necessary for Power BI usage
                        RefreshPart();
                    end;
                }
                field(OptInImageField; MediaResources."Media Reference")
                {
                    CaptionML = ENU = '';
                    ApplicationArea = All;
                    Editable = FALSE;
                }
            }
            group(Control11)
            {
                ShowCaption = false;
                Visible = not IsGettingStartedVisible and not IsErrorMessageVisible and HasReports and not OptInVisible and HasPowerBIPermissions;

                usercontrol(WebReportViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                {
                    ApplicationArea = All;

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
                    end;

                    trigger Refresh(callbackUrl: Text)
                    begin
                        if AddInReady and not TempPowerBiReportBuffer.IsEmpty then
                            SetReport;
                    end;
                }
            }
            grid(Control15)
            {
                GridLayout = Columns;
                ShowCaption = false;

                group(Control13)
                {
                    Visible = not OptInVisible;
                    ShowCaption = false;
                    group(Control7)
                    {
                        ShowCaption = false;
                        Visible = IsGettingStartedVisible and not IsErrorMessageVisible;

                        field(GettingStarted; GettingStartedTxt)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            Style = StrongAccent;
                            StyleExpr = TRUE;
                            ToolTip = 'Specifies that the Azure AD setup window opens. ';

                            trigger OnDrillDown()
                            begin
                                if not TryAzureAdMgtGetAccessToken then
                                    ShowErrorMessage(GetLastErrorText);

                                HasPowerBIPermissions := PowerBiServiceMgt.CheckPowerBITablePermissions(); // check if user has all table permissions necessary for Power BI usage
                                PowerBiServiceMgt.SelectDefaultReports;
                                LoadContent;
                            end;
                        }
                    }
                    group(Control10)
                    {
                        ShowCaption = false;
                        Visible = IsErrorMessageVisible;

                        field(ErrorMessageText; ErrorMessageText)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the error message from Power BI.';
                        }
                        field(ErrorUrlText; PowerBiServiceMgt.GetPowerBIUrl)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ExtendedDatatype = URL;
                            ShowCaption = false;
                            ToolTip = 'Specifies the link that generated the error.';
                            Visible = IsUrlFieldVisible;
                        }
                        group(Control17)
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
                    group(Control12)
                    {
                        ShowCaption = false;
                        Visible = not IsGettingStartedVisible and not IsErrorMessageVisible and not HasReports and not IsDeployingReports and not IsLicenseTimerActive and not CheckingLicenseInBackground;

                        label(EmptyMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'There are no enabled reports. Choose Select Report to see a list of reports that you can display.';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies that the user needs to select Power BI reports.';
                            Visible = not IsDeployingReports;
                        }
                    }
                    group(Control24)
                    {
                        ShowCaption = false;
                        Visible = not IsDeploymentUnavailable and IsDeployingReports and not HasReports and not CheckingLicenseInBackground;

                        label(InProgressMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Power BI report deployment is in progress.';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies that the page is deploying reports to Power BI.';
                        }
                    }
                    group(Control31)
                    {
                        ShowCaption = false;
                        Visible = IsLicenseTimerActive or CheckingLicenseInBackground and not IsDeployingReports and not IsErrorMessageVisible;

                        label(CheckLicenseMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Verifying your Power BI license.';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies that the page is checking for Power BI license.';
                        }
                    }
                    group(Control30)
                    {
                        ShowCaption = false;
                        Visible = IsDeploymentUnavailable and not IsDeployingReports and not HasReports;

                        label(ServiceUnavailableMessage)
                        {
                            ApplicationArea = All;
                            Caption = 'Power BI report deployment is currently unavailable.';
                            ToolTip = 'Specifies that the page cannot currently deploy reports to Power BI.';
                        }
                    }
                    group(Control20)
                    {
                        ShowCaption = false;

                        usercontrol(DeployTimer; "Microsoft.Dynamics.Nav.Client.PowerBIManagement")
                        {
                            ApplicationArea = All;
                            Visible = HasPowerBIPermissions;

                            trigger AddInReady()
                            begin
                                // Timer for refreshing the page during OOB report deployment - usually deployment will
                                // start on page load before the add-in is ready.
                                IsTimerReady := true;
                                StartLicenseTimer;
                                if not CheckingLicenseInBackground and IsDeployingReports and not IsErrorMessageVisible and HasPowerBIPermissions then
                                    StartDeploymentTimer;
                            end;

                            trigger Pong()
                            var
                                HasPowerBILicense: Boolean;
                            begin
                                // Select default reports and refresh the page, or possibly wait and check again later
                                // if it looks like uploading hasn't finished yet.
                                HasPowerBILicense := PowerBiServiceMgt.CheckForPowerBILicense;
                                IsLicenseTimerActive := not HasPowerBILicense;
                                CheckingLicenseInBackground := not HasPowerBILicense;

                                if HasPowerBILicense and HasPowerBIPermissions then begin
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
                ApplicationArea = All;
                Caption = 'Select Report';
                Enabled = not IsGettingStartedVisible and not IsErrorMessageVisible and HasPowerBIPermissions;
                Image = SelectChart;
                ToolTip = 'Select the report.';

                trigger OnAction()
                begin
                    SelectReports;
                end;
            }
            action("Expand Report")
            {
                ApplicationArea = All;
                Caption = 'Expand Report';
                Enabled = HasReports and not IsErrorMessageVisible;
                Image = View;
                ToolTip = 'View all information in the report.';

                trigger OnAction()
                var
                    PowerBiReportDialog: Page "Power BI Report Dialog";
                begin
                    PowerBiReportDialog.SetUrl(GetEmbedUrlWithNavigation, PowerBiEmbedHelper.GetLoadReportMessage());
                    PowerBiReportDialog.Caption(TempPowerBiReportBuffer.ReportName);
                    PowerBiReportDialog.Run;
                end;
            }
            action("Previous Report")
            {
                ApplicationArea = All;
                Caption = 'Previous Report';
                Enabled = HasReports and not IsErrorMessageVisible;
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
                ApplicationArea = All;
                Caption = 'Next Report';
                Enabled = HasReports and not IsErrorMessageVisible;
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
            action("Manage Report")
            {
                ApplicationArea = All;
                Caption = 'Manage Report';
                Enabled = HasReports and not IsErrorMessageVisible;
                Image = PowerBI;
                ToolTip = 'Opens current selected report for edits.';
                Visible = IsSaaSUser;

                trigger OnAction()
                var
                    PowerBIManagement: Page "Power BI Management";
                begin
                    PowerBIManagement.SetTargetReport(LastOpenedReportID, GetEmbedUrl);
                    PowerBIManagement.LookupMode(true);
                    PowerBIManagement.RunModal;

                    RefreshPart;
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh Page';
                Enabled = not IsGettingStartedVisible and HasPowerBIPermissions;
                Image = Refresh;
                ToolTip = 'Refresh the visible content.';

                trigger OnAction()
                begin
                    RefreshPart;
                end;
            }
            action("Upload Report")
            {
                ApplicationArea = All;
                Caption = 'Upload Report';
                Image = Add;
                ToolTip = 'Uploads a report from a PBIX file.';
                Visible = IsSaaSUser and not IsErrorMessageVisible and HasPowerBIPermissions;

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"Upload Power BI Report");
                    RefreshPart;
                end;
            }
            action("Reset All Reports")
            {
                ApplicationArea = All;
                Caption = 'Reset All Reports';
                Image = Reuse;
                ToolTip = 'Resets all reports for redeployment.';
                Visible = IsAdmin and IsSaaSUser and not IsErrorMessageVisible and not IsGettingStartedVisible and HasUploads and HasPowerBIPermissions;

                trigger OnAction()
                var
                    PowerBIReportUploads: Record "Power BI Report Uploads";
                    PowerBIReportConfiguration: Record "Power BI Report Configuration";
                    PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
                    PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
                    PowerBIUserConfiguration: Record "Power BI User Configuration";
                    PowerBICustomerReports: Record "Power BI Customer Reports";
                begin
                    if Confirm(ResetReportsQst, false) then begin
                        PowerBIReportUploads.DeleteAll;
                        PowerBIReportConfiguration.DeleteAll;
                        PowerBIOngoingDeployments.DeleteAll;
                        PowerBIServiceStatusSetup.DeleteAll;
                        PowerBICustomerReports.DeleteAll;
                        PowerBIUserConfiguration.DeleteAll;
                        Commit;
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        // Variables used by PingPong timer when deploying default PBI reports.
        TimerDelay := 30000; // 30 seconds
        MaxTimerCount := (60000 / TimerDelay) * 5; // 5 minutes
    end;

    trigger OnOpenPage()
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        UpdateContext;
        IsAdmin := UserPermissions.IsSuper(UserSecurityId);
        IsSaaSUser := AzureAdMgt.IsSaaS();
        HasUploads := PowerBiServiceMgt.HasUploads;
        UserOptedIn := PowerBISessionManager.GetHasPowerBILicense and (HasUploads or not PowerBIReportConfiguration.IsEmpty);
        HasPowerBIPermissions := PowerBiServiceMgt.CheckPowerBITablePermissions();

        if IsSaaSUser and PowerBiServiceMgt.CanHandleServiceCalls then
            if not UserOptedIn then begin
                OptInVisible := true;
                LoadOptInImage
            end;

        RefreshPart;
    end;

    var
        NoReportsAvailableErr: Label 'There are no reports available from Power BI.';
        ResetReportsQst: Label 'This action will remove all Power BI reports in the database for all users. Reports in your Power BI workspace need to be removed manually. Continue?';
        PowerBiOptInTxt: Label 'User has opted in to enable Power BI services', Locked = true;
        PowerBiOptInImageNameLbl: Label 'PowerBi-OptIn-480px.png', Locked = true;
        NoOptInImageTxt: Label 'There is no Power BI Opt-in image in the Database with ID: %1', Locked = true;
        GettingStartedTxt: Label 'Get started with Power BI';
        GetReportsTxt: Label 'Get reports';
        TempPowerBiReportBuffer: Record "Power BI Report Buffer" temporary;
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        MediaResources: Record "Media Resources";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
        SetPowerBIUserConfig: Codeunit "Set Power BI User Config";
        PowerBiServiceMgt: Codeunit "Power BI Service Mgt.";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        PowerBiEmbedHelper: Codeunit "Power BI Embed Helper";
        UserPermissions: Codeunit "User Permissions";
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
        IsDeployingReports: Boolean;
        IsDeploymentUnavailable: Boolean;
        IsTimerReady: Boolean;
        IsTimerActive: Boolean;
        ExceptionMessage: Text;
        ExceptionDetails: Text;
        TimerDelay: Integer;
        MaxTimerCount: Integer;
        CurrentTimerCount: Integer;
        IsSaaSUser: Boolean;
        IsAdmin: Boolean;
        HasUploads: Boolean;
        IsLicenseTimerActive: Boolean;
        CheckingLicenseInBackground: Boolean;
        UserOptedIn: Boolean;
        OptInVisible: Boolean;
        HasPowerBIPermissions: Boolean;

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

    local procedure GetEmbedUrlWithNavigation(): Text
    begin
        // update last loaded report
        SetLastOpenedReportID(TempPowerBiReportBuffer.ReportID);
        // Hides filters and shows tabs for embedding in large spaces where navigation is necessary.
        exit(TempPowerBiReportBuffer.ReportEmbedUrl + '&filterPaneEnabled=false');
    end;

    local procedure LoadContent()
    begin
        // The end to end process for loading reports onscreen, or defaulting to an error state if that fails,
        // including deploying default reports in case they haven't been loaded yet. Called when first logging
        // into Power BI or any time the part has reloaded from scratch.
        if not TryLoadPart then
            ShowErrorMessage(GetLastErrorText);

        // Always call this after TryLoadPart. Since we can't modify record from TryFunction.
        PowerBiServiceMgt.UpdateEmbedUrlCache(TempPowerBiReportBuffer, Context);

        // Always call this function after calling TryLoadPart to log exceptions to ActivityLog table
        if ExceptionMessage <> '' then begin
            SendTraceTag('0000B73', PowerBiServiceMgt.GetPowerBiTelemetryCategory(),
                Verbosity::Error, ExceptionMessage + ' : ' + ExceptionDetails, DataClassification::CustomerContent);

            ExceptionMessage := '';
            ExceptionDetails := '';
            ClearLastError();
        end;

        if not IsGettingStartedVisible and not OptInVisible and HasPowerBIPermissions then
            CheckPowerBILicense;

        CurrPage.Update;

        DeployDefaultReports;
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
                RefreshAvailableReports;
            end;
        end;

        HasReports := TempPowerBiReportBuffer.FindFirst;
    end;

    local procedure RefreshPart()
    begin
        // Refreshes content by re-rendering the whole page part - removes any current error message text, and tries to
        // reload the user's list of reports, as if the page just loaded. Used by the Refresh button or when closing the
        // Select Reports page, to make sure we have the most up to date list of reports and aren't stuck in an error state.
        IsErrorMessageVisible := false;
        IsUrlFieldVisible := false;
        IsGetReportsVisible := false;

        IsDeployingReports := PowerBiServiceMgt.GetIsDeployingReports;

        IsDeploymentUnavailable := not PowerBiServiceMgt.IsPBIServiceAvailable;

        PowerBiServiceMgt.SelectDefaultReports;

        SetPowerBIUserConfig.CreateOrReadUserConfigEntry(PowerBIUserConfiguration, LastOpenedReportID, Context);
        LoadContent;

        if AddInReady then
            CurrPage.WebReportViewer.Navigate(GetEmbedUrl);
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
            SetContext(PowerBiServiceMgt.GetEnglishContext);
    end;

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
        if TextToShow = PowerBiServiceMgt.GetUnauthorizedErrorText then begin
            IsUrlFieldVisible := true;
            // this message is required to have ':' at the end, but it has '.' instead due to C/AL Localizability requirement
            TextToShow := DelStr(PowerBiServiceMgt.GetUnauthorizedErrorText, StrLen(PowerBiServiceMgt.GetUnauthorizedErrorText), 1) + ':';
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
    local procedure TryLoadPart()
    begin
        IsGettingStartedVisible := not PowerBiServiceMgt.IsUserReadyForPowerBI and not OptInVisible and not IsSaaSUser;

        TempPowerBiReportBuffer.Reset();
        TempPowerBiReportBuffer.DeleteAll();
        if IsGettingStartedVisible then begin
            if IsSaaSUser then
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
        AccessToken: Text;
    begin
        AccessToken := AzureAdMgt.GetAccessToken(PowerBiServiceMgt.GetPowerBIResourceUrl, PowerBiServiceMgt.GetPowerBiResourceName, true);

        if AccessToken = '' then
            Error(PowerBiServiceMgt.GetUnauthorizedErrorText());
    end;

    local procedure SetReport()
    begin
        if (ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Phone) and
           (ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Windows)
        then
            CurrPage.WebReportViewer.InitializeIFrame(PowerBiServiceMgt.GetReportPageSize);

        CurrPage.WebReportViewer.Navigate(GetEmbedUrl);
    end;

    procedure SetLastOpenedReportID(LastOpenedReportIDInputValue: Guid)
    begin
        LastOpenedReportID := LastOpenedReportIDInputValue;
        // filter to find the proper record
        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("Page ID", '%1', Context);
        PowerBIUserConfiguration.SetFilter("Profile ID", '%1', PowerBiServiceMgt.GetEnglishContext);
        PowerBIUserConfiguration.SetFilter("User Security ID", '%1', UserSecurityId);

        // update the last loaded report field (the record at this point should already exist bacause it was created OnOpenPage)
        if not PowerBIUserConfiguration.IsEmpty then begin
            PowerBIUserConfiguration."Selected Report ID" := LastOpenedReportID;
            PowerBIUserConfiguration.Modify();
            Commit();
        end;
    end;

    local procedure SelectReports()
    var
        PowerBIReportSelection: Page "Power BI Report Selection";
    begin
        // Opens the report selection page, then updates the onscreen report depending on the user's
        // subsequent selection and enabled/disabled settings.
        PowerBIReportSelection.SetContext(Context);
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
            // At this point, NAV will load the web page viewer since HasReports should be true. WebReportViewer::ControlAddInReady will then fire, calling Navigate()
        end;
    end;

    local procedure DeployDefaultReports()
    begin
        if not PowerBiServiceMgt.IsPowerBIDeploymentEnabled then
            exit;

        // Checks if there are any default reports the user needs to upload, select, or delete and automatically begins
        // those processes. The page will refresh when the timer control runs later.
        DeleteMarkedReports;
        FinishPartialUploads;
        if not CheckingLicenseInBackground and not IsGettingStartedVisible and not IsErrorMessageVisible and IsSaaSUser and
           PowerBiServiceMgt.UserNeedsToDeployReports(Context) and not PowerBiServiceMgt.IsUserDeployingReports and not OptInVisible
        then begin
            IsDeployingReports := true;
            PowerBiServiceMgt.UploadDefaultReportInBackground;
            StartDeploymentTimer;
        end;
    end;

    local procedure FinishPartialUploads()
    begin
        // Checks if there are any default reports whose uploads only partially completed, and begins a
        // background process for those reports. The page will refresh when the timer control runs later.
        if not CheckingLicenseInBackground and not IsGettingStartedVisible and not IsErrorMessageVisible and IsSaaSUser and
           PowerBiServiceMgt.UserNeedsToRetryUploads and not PowerBiServiceMgt.IsUserRetryingUploads and not OptInVisible
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
        if not CheckingLicenseInBackground and not IsGettingStartedVisible and not IsErrorMessageVisible and IsSaaSUser and
           PowerBiServiceMgt.UserNeedsToDeleteReports and not PowerBiServiceMgt.IsUserDeletingReports and not OptInVisible
        then begin
            IsDeployingReports := true;
            PowerBiServiceMgt.DeleteDefaultReportsInBackground;
            StartDeploymentTimer;
            // TODO: Make same changes on factbox page.
        end;
    end;

    local procedure StartDeploymentTimer()
    begin
        // Resets the timer for refreshing the page during OOB report deployment, if the add-in is
        // ready to go and the timer isn't already going.
        if IsTimerReady and not IsTimerActive and not IsLicenseTimerActive then begin
            CurrentTimerCount := 0;
            IsTimerActive := true;
            CurrPage.DeployTimer.Ping(TimerDelay);
        end;
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
        if HasPowerBIPermissions and not PowerBiServiceMgt.CheckForPowerBILicense then begin
            CheckingLicenseInBackground := true;
            StartLicenseTimer;
        end;
    end;

    local procedure LoadOptInImage()
    var
        MediaRepository: Record "Media Repository";
    begin
        if not MediaResources."Media Reference".HasValue() then begin
            if MediaRepository.Get(PowerBiOptInImageNameLbl, Format(ClientTypeManagement.GetCurrentClientType)) then
                if MediaResources.Get(MediaRepository."Media Resources Ref") then
                    exit;

            SendTraceTag('0000BKH', PowerBiServiceMgt.GetPowerBiTelemetryCategory(), Verbosity::Warning,
                StrSubstNo(NoOptInImageTxt, PowerBiOptInImageNameLbl), DataClassification::SystemMetadata);
        end;
    end;
}

