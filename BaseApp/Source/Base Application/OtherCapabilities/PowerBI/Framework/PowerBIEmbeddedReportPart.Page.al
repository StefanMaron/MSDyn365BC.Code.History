page 6325 "Power BI Embedded Report Part"
{
    Caption = 'Power BI Report';
    PageType = CardPart;
    SourceTable = "Power BI Report Configuration";
    Editable = false;

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
                        Session.LogMessage('0000GJP', PowerBiOptInTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

                        PowerBIUserConfiguration.CreateOrReadForCurrentUser(PageContext);
                        Commit();

                        PowerBIEmbedSetupWizard.SetContext(PageContext);
                        if PowerBIEmbedSetupWizard.RunModal() <> Action::Cancel then
                            ReloadPageState();
                    end;
                }
                field(OptInImageField; MediaResources."Media Reference")
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

                        CurrPage.Update();
                    end;
                }
            }
            group(ReportGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::ReportVisible;

                usercontrol(WebReportViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        AddInReady := true;
                        if not Rec.IsEmpty() then
                            SetReport();
                    end;

                    trigger DocumentReady()
                    begin
                        InitializeAddIn();
                    end;

                    trigger Callback(data: Text)
                    begin
                        HandleAddinCallback(data);
                    end;

                    trigger Refresh(callbackUrl: Text)
                    begin
                        if AddInReady and not Rec.IsEmpty() then
                            SetReport();
                    end;
                }
            }
            grid(MessagesGridGroup)
            {
                GridLayout = Columns;
                ShowCaption = false;

                group(MessagesInnerGroup)
                {
                    ShowCaption = false;

                    group(ErrorGroup)
                    {
                        ShowCaption = false;
                        Visible = PageState = PageState::ErrorVisible;

                        field(ErrorMessageText; ErrorMessageText)
                        {
                            ApplicationArea = All;
                            MultiLine = true;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the error message from Power BI.';
                        }
                    }
                    group(NoReportGroup)
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
                    group(DeployingReportsGroup)
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
                        label(NoReportsMessage)
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
                            var
                                PreviousPageState: Option;
                            begin
                                PreviousPageState := PageState;
                                ReloadPageState();

                                CurrPage.Update(false);

                                if (PageState = PageState::NoReportButDeploying) and (PreviousPageState = PageState::NoReportButDeploying) then
                                    Message(StillDeployingMsg);
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
                    PowerBiReportDialog.SetReportUrl(GetEmbedUrl(true, true));
                    PowerBiReportDialog.Caption(StrSubstNo(ReportCaptionTxt, Rec.ReportName, Rec."Workspace Name"));
                    PowerBiReportDialog.SetFilterValue(CurrentListSelection, CurrentReportFirstPage);
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
                    if Rec.Next(-1) = 0 then
                        Rec.FindLast();

                    if AddInReady then
                        CurrPage.WebReportViewer.Navigate(GetEmbedUrl(false, false));
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
                    if Rec.Next() = 0 then
                        Rec.FindFirst();

                    if AddInReady then
                        CurrPage.WebReportViewer.Navigate(GetEmbedUrl(false, false));
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
                    PowerBIManagement.SetTargetReport(Rec."Report ID", GetEmbedUrl(false, false));
                    PowerBIManagement.LookupMode(true);
                    PowerBIManagement.Run();

                    ReloadPageState();
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
                    ReloadPageState();
                end;
            }
            action("Upload Report")
            {
                ApplicationArea = All;
                Caption = 'Upload Report';
                Image = Add;
                ToolTip = 'Uploads a report from a PBIX file.';
                Visible = IsSaaSUser;
                Enabled = (PageState = PageState::ReportVisible) or (PageState = PageState::NoReport) or (PageState = PageState::NoReportButDeploying) or (PageState = PageState::ShouldDeploy);

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Upload Power BI Report");
                    ReloadPageState();
                end;
            }
            action("Reset All Reports")
            {
                ApplicationArea = All;
                Caption = 'Reset All Reports';
                Image = Reuse;
                ToolTip = 'Resets all Power BI setup in Business Central, for all users. Reports in your Power BI workspaces are not affected and need to be removed manually.';
                Visible = IsPBIAdmin;

                trigger OnAction()
                var
                    PowerBIReportUploads: Record "Power BI Report Uploads";
                    PowerBIReportConfiguration: Record "Power BI Report Configuration";
#if not CLEAN22
                    PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
#endif
                    PowerBIUserConfiguration: Record "Power BI User Configuration";
                    PowerBICustomerReports: Record "Power BI Customer Reports";
                    PowerBIUserStatus: Record "Power BI User Status";
                    ChosenOption: Integer;
                begin
                    ChosenOption := StrMenu(ResetReportsOptionsTxt, 1, ResetReportsQst);

                    Session.LogMessage('0000GJQ', StrSubstNo(ReportsResetTelemetryMsg, ChosenOption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

                    if ChosenOption in [1, 2] then begin // Delete reports only or delete all
                        PowerBIReportConfiguration.DeleteAll();
                        PowerBIUserStatus.DeleteAll();
#if not CLEAN22
                        PowerBIServiceStatusSetup.DeleteAll();
#endif
                        PowerBIUserConfiguration.DeleteAll();

                        if ChosenOption = 2 then begin // Delete all
                            PowerBICustomerReports.DeleteAll();
                            PowerBIReportUploads.DeleteAll();
                        end;

                        Commit();
                        ReloadPageState();
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        IsPBIAdmin := PowerBiServiceMgt.IsUserAdminForPowerBI(UserSecurityId());
        IsSaaSUser := EnvironmentInfo.IsSaaS();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        PreviousFilterGroup: Integer;
    begin
        Rec.SetRange("User Security ID", UserSecurityId());

        PreviousFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4); // Filter set with SubPageView
        if PageContext = '' then
            PageContext := CopyStr(Rec.GetFilter(Context), 1, MaxStrLen(PageContext))
        else
            Rec.SetRange(Context, PageContext);
        Rec.FilterGroup(PreviousFilterGroup);

        if PageContext = '' then
            PageContext := PowerBiServiceMgt.GetEnglishContext();

        ReloadPageState();

        if Rec.IsEmpty() then
            exit(true);

        exit(Rec.Find(Which));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        // Workaround: Even if the page is Editable = false, modifications can be issued to the record, and the record
        // can be non-existent because of custom logic in OnFindRecord.
        if IsNullGuid(Rec."User Security ID") and IsNullGuid(Rec."Report ID") then
            exit(false);
    end;

    var
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
        ReportFrameRatio: Text;
        PageContext: Text[30];
        AddInReady: Boolean;
        ErrorMessageText: Text;
        CurrentListSelection: Text;
        LatestReceivedFilterInfo: Text;
        CurrentReportFirstPage: Text;
        IsSaaSUser: Boolean;
        IsPBIAdmin: Boolean;
        // Telemetry labels
        InvalidEmbedUriErr: Label 'Invalid embed URI with length: %1', Locked = true;
        NoOptInImageTxt: Label 'There is no Power BI Opt-in image in the Database with ID: %1', Locked = true;
        PowerBiOptInTxt: Label 'User has opted in to enable Power BI services', Locked = true;
        PowerBIReportLoadTelemetryMsg: Label 'Loading Power BI report for user', Locked = true;
        ReportsResetTelemetryMsg: Label 'User has reset Power BI setup, option chosen: %1', Locked = true;
        UnsupportedFilterTypeTelemetryMsg: Label 'Cannot filter Power BI report: the filter type is not supported.', Locked = true;


    local procedure ReloadPageState()
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
        NullGuid: Guid;
    begin
        PowerBIUserConfiguration.SetRange("User Security ID", UserSecurityId());
        if PowerBIUserConfiguration.IsEmpty() then begin
            LoadOptInImage();
            PageState := PageState::GetStarted;
            exit;
        end;

        PowerBIUserConfiguration.CreateOrReadForCurrentUser(PageContext);

        if not Rec.Get(UserSecurityId(), PowerBIUserConfiguration."Selected Report ID", PageContext) then
            if Rec.FindFirst() then
                SaveReportIdInConfiguration(Rec."Report ID")
            else
                SaveReportIdInConfiguration(NullGuid);

        if Rec.IsEmpty() then begin
            if PowerBiServiceMgt.IsUserSynchronizingReports() then begin
                PageState := PageState::NoReportButDeploying;
                exit;
            end;

            if PowerBIReportSynchronizer.UserNeedsToSynchronize(PageContext) then begin
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
        if PageContext = '' then
            exit;

        DummyPowerBIUserConfiguration.CreateOrReadForCurrentUser(PageContext);
        PowerBIReportSynchronizer.SelectDefaultReports();
        PowerBiServiceMgt.SynchronizeReportsInBackground();
    end;

    local procedure GetEmbedUrl(EnableFilterPane: Boolean; EnableNavigationContentPane: Boolean): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
    begin
        SaveReportIdInConfiguration(Rec."Report ID");

        Session.LogMessage('0000GJR', PowerBIReportLoadTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

        if not Uri.IsValidUri(Rec.ReportEmbedUrl) then begin
            Session.LogMessage('0000GJS', StrSubstNo(InvalidEmbedUriErr, StrLen(Rec.ReportEmbedUrl)), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
            exit(Rec.ReportEmbedUrl);
        end;

        // Hides both filters and tabs for embedding in small spaces where navigation is unnecessary.
        UriBuilder.Init(Rec.ReportEmbedUrl);
        UriBuilder.AddQueryParameter('filterPaneEnabled', Format(EnableFilterPane, 0, 9));
        UriBuilder.AddQueryParameter('disableBroswerDeprecationDialog', 'true');
        UriBuilder.AddQueryParameter('navContentPaneEnabled', Format(EnableNavigationContentPane, 0, 9));

        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    local procedure SetReport()
    var
        JsonArray: DotNet Array;
        DotNetString: DotNet String;
    begin
        if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::Phone, ClientType::Windows]) then begin
            if ReportFrameRatio = '' then
                ReportFrameRatio := PowerBiServiceMgt.GetMainPageRatio();
            CurrPage.WebReportViewer.InitializeIFrame(ReportFrameRatio);
        end;

        // subscribe to events
        CurrPage.WebReportViewer.SubscribeToEvent('message', GetEmbedUrl(false, false));
        CurrPage.WebReportViewer.Navigate(GetEmbedUrl(false, false));
        JsonArray := JsonArray.CreateInstance(GetDotNetType(DotNetString), 1);
        JsonArray.SetValue('{"statusCode":202,"headers":{}}', 0);
        CurrPage.WebReportViewer.SetCallbacksFromSubscribedEventToIgnore('message', JsonArray);
    end;

    local procedure SaveReportIdInConfiguration(LastOpenedReportIDInputValue: Guid)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
    begin
        PowerBIUserConfiguration.CreateOrReadForCurrentUser(PageContext);
        if PowerBIUserConfiguration."Selected Report ID" <> LastOpenedReportIDInputValue then begin
            PowerBIUserConfiguration."Selected Report ID" := LastOpenedReportIDInputValue;
            PowerBIUserConfiguration.Modify();
        end;
    end;

    local procedure SelectReports()
    var
        TempPowerBISelectionElement: Record "Power BI Selection Element" temporary;
        PowerBIWSReportSelection: Page "Power BI WS Report Selection";
    begin
        PowerBIWSReportSelection.SetContext(PageContext);
        PowerBIWSReportSelection.LookupMode(true);
        PowerBIWSReportSelection.RunModal();

        if PowerBIWSReportSelection.IsPageClosedOkay() then begin
            PowerBIWSReportSelection.GetRecord(TempPowerBISelectionElement);
            SaveReportIdInConfiguration(TempPowerBISelectionElement.ID);
        end;

        ReloadPageState();
    end;

    local procedure HandleAddinCallback(CallbackMessage: Text)
    var
        MessageForWebPage: Text;
    begin
        PowerBiEmbedHelper.HandleAddInCallback(CallbackMessage, CurrentListSelection, CurrentReportFirstPage, LatestReceivedFilterInfo, MessageForWebPage);
        if MessageForWebPage <> '' then
            CurrPage.WebReportViewer.PostMessage(MessageForWebPage, PowerBiEmbedHelper.TargetOrigin(), true);
    end;

    local procedure ShowError(NewErrorMessageText: Text)
    begin
        PageState := PageState::ErrorVisible;
        ErrorMessageText := NewErrorMessageText;
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
            Session.LogMessage('0000GJT', StrSubstNo(NoOptInImageTxt, PowerBiOptInImageNameLbl), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
        end;
    end;

    #region ExternalInterface

    procedure InitPageRatio(ReportFrameRatioInput: Text)
    begin
        ReportFrameRatio := ReportFrameRatioInput;
    end;

    procedure SetPageContext(InputContext: Text)
    begin
        PageContext := CopyStr(InputContext, 1, MaxStrLen(PageContext));
    end;

    procedure SetCurrentListSelection(InputSelection: variant)
    begin
        case true of
            InputSelection.IsText,
            InputSelection.IsCode,
            InputSelection.IsChar,
            InputSelection.IsDate,
            InputSelection.IsTime,
            InputSelection.IsDateTime:
                CurrentListSelection := '"' + PowerBiServiceMgt.FormatSpecialChars(Format(InputSelection, 0, 9)) + '"';
            InputSelection.IsInteger,
            InputSelection.IsBoolean,
            InputSelection.IsDecimal,
            InputSelection.IsGuid:
                CurrentListSelection := Format(InputSelection, 0, 9);
            else begin
                Session.LogMessage('0000GJU', UnsupportedFilterTypeTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
                CurrentListSelection := '';
            end;
        end;

        // Selection changed: send the latest message to the Addin again with the updated selection, if we have the filter info already
        if LatestReceivedFilterInfo <> '' then
            HandleAddinCallback(LatestReceivedFilterInfo);
    end;

    [Scope('OnPrem')]
    procedure GetOptinImageName(): Text[250]
    begin
        exit(PowerBiOptInImageNameLbl);
    end;

    [NonDebuggable]
    local procedure InitializeAddIn()
    var
        LoadReportMessage: Text;
    begin
        if not Rec.IsEmpty() then
            if PowerBiEmbedHelper.TryGetLoadReportMessage(LoadReportMessage) then
                CurrPage.WebReportViewer.PostMessage(LoadReportMessage, PowerBiEmbedHelper.TargetOrigin(), false)
            else
                ShowError(GetLastErrorText());
    end;

    #endregion
}