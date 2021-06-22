page 1310 "O365 Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Activities Cue";

    layout
    {
        area(content)
        {
            cuegroup("Intelligent Cloud")
            {
                Caption = 'Intelligent Cloud';
                Visible = ShowIntelligentCloud;

                actions
                {
                    action("Learn More")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Learn More';
                        Image = TileInfo;
                        RunPageMode = View;
                        ToolTip = ' Learn more about the Intelligent Cloud and how it can help your business.';

                        trigger OnAction()
                        var
                            IntelligentCloudManagement: Codeunit "Intelligent Cloud Management";
                        begin
                            HyperLink(IntelligentCloudManagement.GetIntelligentCloudLearnMoreUrl);
                        end;
                    }
                    action("Intelligent Cloud Insights")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Intelligent Cloud Insights';
                        Image = TileCloud;
                        RunPageMode = View;
                        ToolTip = 'View your Intelligent Cloud insights.';

                        trigger OnAction()
                        var
                            IntelligentCloudManagement: Codeunit "Intelligent Cloud Management";
                        begin
                            HyperLink(IntelligentCloudManagement.GetIntelligentCloudInsightsUrl);
                        end;
                    }
                }
            }
            cuegroup(Control54)
            {
                CueGroupLayout = Wide;
                ShowCaption = false;
                field("Sales This Month"; "Sales This Month")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies the sum of sales in the current month excluding taxes.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownSalesThisMonth;
                    end;
                }
                field("Overdue Sales Invoice Amount"; "Overdue Sales Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of overdue payments from customers.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownCalcOverdueSalesInvoiceAmount;
                    end;
                }
                field("Overdue Purch. Invoice Amount"; "Overdue Purch. Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of your overdue payments to vendors.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownOverduePurchaseInvoiceAmount;
                    end;
                }
            }
            cuegroup(Welcome)
            {
                Caption = 'Welcome';
                Visible = TileGettingStartedVisible;

                actions
                {
                    action(GettingStartedTile)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Return to Getting Started';
                        Image = TileVideo;
                        ToolTip = 'Learn how to get started with Dynamics 365.';

                        trigger OnAction()
                        begin
                            O365GettingStartedMgt.LaunchWizard(true, false);
                        end;
                    }
                }
            }
            cuegroup("Ongoing Sales")
            {
                Caption = 'Ongoing Sales';
                field("Ongoing Sales Quotes"; "Ongoing Sales Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Quotes';
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies sales quotes that have not yet been converted to invoices or orders.';
                }
                field("Ongoing Sales Orders"; "Ongoing Sales Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies sales orders that are not yet posted or only partially posted.';
                }
                field("Ongoing Sales Invoices"; "Ongoing Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoices';
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies sales invoices that are not yet posted or only partially posted.';
                }
            }
            cuegroup("Document Exchange Service")
            {
                Caption = 'Document Exchange Service';
                Visible = ShowDocumentsPendingDocExchService;
                field("Sales Inv. - Pending Doc.Exch."; "Sales Inv. - Pending Doc.Exch.")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Posted Sales Invoices";
                    ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
                    Visible = ShowDocumentsPendingDocExchService;
                }
                field("Sales CrM. - Pending Doc.Exch."; "Sales CrM. - Pending Doc.Exch.")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Posted Sales Credit Memos";
                    ToolTip = 'Specifies sales credit memos that await sending to the customer through the document exchange service.';
                    Visible = ShowDocumentsPendingDocExchService;
                }
            }
            cuegroup("Ongoing Purchases")
            {
                Caption = 'Ongoing Purchases';
                field("Purchase Orders"; "Purchase Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies purchases orders that are not posted or only partially posted.';
                }
                field("Ongoing Purchase Invoices"; "Ongoing Purchase Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies purchases invoices that are not posted or only partially posted.';
                }
                field("Purch. Invoices Due Next Week"; "Purch. Invoices Due Next Week")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of payments to vendors that are due next week.';
                }
            }
            cuegroup(Approvals)
            {
                Caption = 'Approvals';
                field("Requests to Approve"; "Requests to Approve")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Requests to Approve";
                    ToolTip = 'Specifies the number of approval requests that require your approval.';
                }
            }
            cuegroup(Intercompany)
            {
                Caption = 'Intercompany';
                Visible = ShowIntercompanyActivities;
                field("IC Inbox Transactions"; "IC Inbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Pending Inbox Transactions';
                    DrillDownPageID = "IC Inbox Transactions";
                    Visible = "IC Inbox Transactions" <> 0;
                }
                field("IC Outbox Transactions"; "IC Outbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Pending Outbox Transactions';
                    DrillDownPageID = "IC Outbox Transactions";
                    Visible = "IC Outbox Transactions" <> 0;
                }
            }
            cuegroup(Payments)
            {
                Caption = 'Payments';
                field("Non-Applied Payments"; "Non-Applied Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unprocessed Payments';
                    Image = Cash;
                    ToolTip = 'Specifies imported bank transactions for payments that are not yet reconciled in the Payment Reconciliation Journal window.';

                    trigger OnDrillDown()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Pmt. Rec. Journals Launcher");
                    end;
                }
                field("Average Collection Days"; "Average Collection Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how long customers took to pay invoices in the last three months. This is the average number of days from when invoices are issued to when customers pay the invoices.';
                }
                field("Outstanding Vendor Invoices"; "Outstanding Vendor Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of invoices from your vendors that have not been paid yet.';
                }
            }
            cuegroup(Camera)
            {
                Caption = 'Camera';
                Visible = HasCamera;

                actions
                {
                    action(CreateIncomingDocumentFromCamera)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Incoming Doc. from Camera';
                        Image = TileCamera;
                        ToolTip = 'Create an incoming document by taking a photo of the document with your device camera. The photo will be attached to the new document.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                            InStr: InStream;
                        begin
                            if not HasCamera then
                                exit;

                            Camera.SetQuality(100); // 100%
                            Camera.RunModal();
                            if Camera.HasPicture() then begin
                                Camera.GetPicture(InStr);
                                IncomingDocument.CreateIncomingDocument(InStr, 'Incoming Document');
                            end;
                            Clear(Camera);
                            CurrPage.Update;
                        end;
                    }
                }
            }
            cuegroup("Incoming Documents")
            {
                Caption = 'Incoming Documents';
                field("My Incoming Documents"; "My Incoming Documents")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies incoming documents that are assigned to you.';
                }
                field("Awaiting Verfication"; "Inc. Doc. Awaiting Verfication")
                {
                    ApplicationArea = Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies incoming documents in OCR processing that require you to log on to the OCR service website to manually verify the OCR values before the documents can be received.';
                    Visible = ShowAwaitingIncomingDoc;

                    trigger OnDrillDown()
                    var
                        OCRServiceSetup: Record "OCR Service Setup";
                    begin
                        if OCRServiceSetup.Get then
                            if OCRServiceSetup.Enabled then
                                HyperLink(OCRServiceSetup."Sign-in URL");
                    end;
                }
            }
            cuegroup("Data Integration")
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationCues;
                field("CDS Integration Errors"; "CDS Integration Errors")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Integration Errors';
                    DrillDownPageID = "Integration Synch. Error List";
                    ToolTip = 'Specifies the number of errors related to data integration.';
                    Visible = ShowIntegrationErrorsCue;
                }
                field("Coupled Data Synch Errors"; "Coupled Data Synch Errors")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Coupled Data Synchronization Errors';
                    DrillDownPageID = "CRM Skipped Records";
                    ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Sales.';
                    Visible = ShowD365SIntegrationCues;
                }
            }
            cuegroup("My User Tasks")
            {
                Caption = 'My User Tasks';
                field("UserTaskManagement.GetMyPendingUserTasksCount"; UserTaskManagement.GetMyPendingUserTasksCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending User Tasks';
                    Image = Checklist;
                    ToolTip = 'Specifies the number of pending tasks that are assigned to you or to a group that you are a member of.';

                    trigger OnDrillDown()
                    var
                        UserTaskList: Page "User Task List";
                    begin
                        UserTaskList.SetPageToShowMyPendingUserTasks;
                        UserTaskList.Run;
                    end;
                }
            }
            cuegroup("Product Videos")
            {
                Caption = 'Product Videos';
                Visible = ShowProductVideosActivities;

                actions
                {
                    action(Action43)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Product Videos';
                        Image = TileVideo;
                        RunObject = Page "Product Videos";
                        ToolTip = 'Open a list of videos that showcase some of the product capabilities.';
                    }
                }
            }
            cuegroup("Get started")
            {
                Caption = 'Get started';
                Visible = ReplayGettingStartedVisible;

                actions
                {
                    action(ShowStartInMyCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Try with my own data';
                        Image = TileSettings;
                        ToolTip = 'Set up My Company with the settings you choose. We''ll show you how, it''s easy.';
                        Visible = false;

                        trigger OnAction()
                        begin
                            if UserTours.IsAvailable and O365GettingStartedMgt.AreUserToursEnabled then
                                UserTours.StartUserTour(O365GettingStartedMgt.GetChangeCompanyTourID);
                        end;
                    }
                    action(ReplayGettingStarted)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replay Getting Started';
                        Image = TileVideo;
                        ToolTip = 'Show the Getting Started guide again.';

                        trigger OnAction()
                        var
                            O365GettingStarted: Record "O365 Getting Started";
                        begin
                            if O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType()) then begin
                                O365GettingStarted."Tour in Progress" := false;
                                O365GettingStarted."Current Page" := 1;
                                O365GettingStarted.Modify();
                                Commit();
                            end;

                            O365GettingStartedMgt.LaunchWizard(true, false);
                        end;
                    }
                }
            }
            usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            {
                ApplicationArea = Basic, Suite;
                trigger ResponseReceived(Status: Integer; Response: Text)
                var
                    SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
                begin
                    SatisfactionSurveyMgt.TryShowSurvey(Status, Response);
                end;

                trigger ControlAddInReady();
                begin
                    IsAddInReady := true;
                    CheckIfSurveyEnabled();
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Data';
                Image = Refresh;
                ToolTip = 'Refreshes the data needed to make complex calculations.';

                trigger OnAction()
                begin
                    "Last Date/Time Modified" := 0DT;
                    Modify;

                    CODEUNIT.Run(CODEUNIT::"Activities Mgt.");
                    CurrPage.Update(false);
                end;
            }
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        if UserTours.IsAvailable and O365GettingStartedMgt.AreUserToursEnabled then
            O365GettingStartedMgt.UpdateGettingStartedVisible(TileGettingStartedVisible, ReplayGettingStartedVisible);
        RoleCenterNotificationMgt.HideEvaluationNotificationAfterStartingTrial;
    end;

    trigger OnAfterGetRecord()
    begin
        SetActivityGroupVisibility;
    end;

    trigger OnInit()
    begin
        if UserTours.IsAvailable and O365GettingStartedMgt.AreUserToursEnabled then
            O365GettingStartedMgt.UpdateGettingStartedVisible(TileGettingStartedVisible, ReplayGettingStartedVisible);
    end;

    trigger OnOpenPage()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        NewRecord: Boolean;
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
            Commit();
            NewRecord := true;
        end;

        SetFilter("User ID Filter", UserId);

        HasCamera := Camera.IsAvailable();

        PrepareOnLoadDialog;

        ShowAwaitingIncomingDoc := OCRServiceMgt.OcrServiceIsEnable;
        ShowIntercompanyActivities := false;
        ShowDocumentsPendingDocExchService := false;
        ShowProductVideosActivities := ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Phone;
        ShowIntelligentCloud := not EnvironmentInfo.IsSaaS();
        IntegrationSynchJobErrors.SetDataIntegrationUIElementsVisible(ShowDataIntegrationCues);
        ShowD365SIntegrationCues := CRMConnectionSetup.IsEnabled() or CDSIntegrationMgt.IsIntegrationEnabled();
        ShowIntegrationErrorsCue := ShowDataIntegrationCues and (not ShowD365SIntegrationCues);
        RoleCenterNotificationMgt.ShowNotifications;
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent;

        CalculateCueFieldValues;
    end;

    var
        ActivitiesMgt: Codeunit "Activities Mgt.";
        CuesAndKpis: Codeunit "Cues And KPIs";
        O365GettingStartedMgt: Codeunit "O365 Getting Started Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        EnvironmentInfo: Codeunit "Environment Information";
        UserTaskManagement: Codeunit "User Task Management";
        Camera: Page Camera;
        [RunOnClient]
        [WithEvents]
        UserTours: DotNet UserTours;
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        [InDataSet]
        HasCamera: Boolean;
        ShowDocumentsPendingDocExchService: Boolean;
        ShowAwaitingIncomingDoc: Boolean;
        ShowIntercompanyActivities: Boolean;
        ShowProductVideosActivities: Boolean;
        ShowIntelligentCloud: Boolean;
        TileGettingStartedVisible: Boolean;
        ReplayGettingStartedVisible: Boolean;
        HideSatisfactionSurvey: Boolean;
        WhatIsNewTourVisible: Boolean;
        ShowD365SIntegrationCues: Boolean;
        ShowDataIntegrationCues: Boolean;
        ShowIntegrationErrorsCue: Boolean;
        HideWizardForDevices: Boolean;
        IsAddInReady: Boolean;
        IsPageReady: Boolean;
        TaskIdCalculateCue: Integer;
        PBTTelemetryCategoryLbl: Label 'PBT', Locked = true;
        PBTTelemetryMsgTxt: Label 'PBT errored with code %1 and text %2. The call stack is as follows %3.', Locked = true;

    procedure CalculateCueFieldValues()
    var
        params: Dictionary of [Text, Text];
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"O365 Activities Dictionary");
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        SendTraceTag('00009V0', PBTTelemetryCategoryLbl, Verbosity::Warning, StrSubstNo(PBTTelemetryMsgTxt, ErrorCode, ErrorText, ErrorCallStack));

        if (TaskId <> TaskIdCalculateCue) then
            exit;

        if ActivitiesMgt.IsCueDataStale then
            if not TASKSCHEDULER.CanCreateTask then
                CODEUNIT.Run(CODEUNIT::"Activities Mgt.")
            else
                TASKSCHEDULER.CreateTask(CODEUNIT::"Activities Mgt.", 0, true, CompanyName, CurrentDateTime);

        IsHandled := TRUE;
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        O365ActivitiesDictionary: Codeunit "O365 Activities Dictionary";
    begin
        if (TaskId = TaskIdCalculateCue) THEN BEGIN
            LockTable(true);
            Get();
            O365ActivitiesDictionary.FillActivitiesCue(Results, Rec);
            "Last Date/Time Modified" := CurrentDateTime;
            Modify(true);
        END
    end;

    local procedure SetActivityGroupVisibility()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        CompanyInformation: Record "Company Information";
    begin
        if DocExchServiceSetup.Get then
            ShowDocumentsPendingDocExchService := DocExchServiceSetup.Enabled;

        if CompanyInformation.Get then
            ShowIntercompanyActivities :=
              (CompanyInformation."IC Partner Code" <> '') and (("IC Inbox Transactions" <> 0) or ("IC Outbox Transactions" <> 0));
    end;

    local procedure StartWhatIsNewTour(hasTourCompleted: Boolean): Boolean
    var
        O365UserTours: Record "User Tours";
        TourID: Integer;
    begin
        TourID := O365GettingStartedMgt.GetWhatIsNewTourID;

        if O365UserTours.AlreadyCompleted(TourID) then
            exit(false);

        if not hasTourCompleted then begin
            UserTours.StartUserTour(TourID);
            WhatIsNewTourVisible := true;
            exit(true);
        end;

        if WhatIsNewTourVisible then begin
            O365UserTours.MarkAsCompleted(TourID);
            WhatIsNewTourVisible := false;
        end;
        exit(false);
    end;

    local procedure PrepareOnLoadDialog()
    begin
        HideWizardForDevices := PrepareUserTours;
        PreparePageNotifier;
    end;

    local procedure PreparePageNotifier()
    begin
        if not PageNotifier.IsAvailable then
            exit;
        PageNotifier := PageNotifier.Create;
        PageNotifier.NotifyPageReady;
    end;

    local procedure PrepareUserTours(): Boolean
    begin
        if (not UserTours.IsAvailable) or (not O365GettingStartedMgt.AreUserToursEnabled) then
            exit(false);
        UserTours := UserTours.Create;
        UserTours.NotifyShowTourWizard;
        if O365GettingStartedMgt.IsGettingStartedSupported then
            if O365GettingStartedMgt.WizardHasToBeLaunched(false) then
                HideSatisfactionSurvey := true;
        exit(true);
    end;

    trigger UserTours::ShowTourWizard(hasTourCompleted: Boolean)
    begin
        if O365GettingStartedMgt.IsGettingStartedSupported then
            if O365GettingStartedMgt.LaunchWizard(false, hasTourCompleted) then begin
                HideSatisfactionSurvey := true;
                exit;
            end;

        if StartWhatIsNewTour(hasTourCompleted) then
            HideSatisfactionSurvey := true;
    end;

    trigger UserTours::IsTourInProgressResultReady(isInProgress: Boolean)
    begin
    end;

    trigger PageNotifier::PageReady()
    begin
        IsPageReady := true;
        if not HideWizardForDevices then
            if O365GettingStartedMgt.WizardShouldBeOpenedForDevices then begin
                HideSatisfactionSurvey := true;
                Commit();
                PAGE.RunModal(PAGE::"O365 Getting Started Device");
            end;
        CheckIfSurveyEnabled();
    end;

    local procedure CheckIfSurveyEnabled()
    var
        SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
        CheckUrl: Text;
    begin
        if not IsAddInReady then
            exit;
        if not IsPageReady then
            exit;
        if HideSatisfactionSurvey then
            exit;
        if not SatisfactionSurveyMgt.DeactivateSurvey() then
            exit;
        if not SatisfactionSurveyMgt.TryGetCheckUrl(CheckUrl) then
            exit;
        CurrPage.SATAsyncLoader.SendRequest(CheckUrl, SatisfactionSurveyMgt.GetRequestTimeoutAsync());
    end;
}

