﻿page 1310 "O365 Activities"
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
            cuegroup(Control54)
            {
                CueGroupLayout = Wide;
                ShowCaption = false;
                field("Sales This Month"; Rec."Sales This Month")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies the sum of sales in the current month excluding taxes.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownSalesThisMonth();
                    end;
                }
                field("Overdue Sales Invoice Amount"; Rec."Overdue Sales Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of overdue payments from customers.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownCalcOverdueSalesInvoiceAmount();
                    end;
                }
                field("Overdue Purch. Invoice Amount"; Rec."Overdue Purch. Invoice Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of your overdue payments to vendors.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownOverduePurchaseInvoiceAmount();
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
                field("Ongoing Sales Quotes"; Rec."Ongoing Sales Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Quotes';
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies sales quotes that have not yet been converted to invoices or orders.';
                }
                field("Ongoing Sales Orders"; Rec."Ongoing Sales Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies sales orders that are not yet posted or only partially posted.';
                }
                field("S. Ord. - Reserved From Stock"; Rec."S. Ord. - Reserved From Stock")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Completely Reserved from Stock';
                    ToolTip = 'Specifies the number of sales orders that are completely reserved from stock.';

                    trigger OnDrillDown()
                    begin
                        ActivitiesMgt.DrillDownNoOfReservedFromStockSalesOrders();
                    end;
                }
                field("Ongoing Sales Invoices"; Rec."Ongoing Sales Invoices")
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
                field("Sales Inv. - Pending Doc.Exch."; Rec."Sales Inv. - Pending Doc.Exch.")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Posted Sales Invoices";
                    ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
                    Visible = ShowDocumentsPendingDocExchService;
                }
                field("Sales CrM. - Pending Doc.Exch."; Rec."Sales CrM. - Pending Doc.Exch.")
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
                field("Purchase Orders"; Rec."Purchase Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies purchases orders that are not posted or only partially posted.';
                }
                field("Ongoing Purchase Invoices"; Rec."Ongoing Purchase Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies purchases invoices that are not posted or only partially posted.';
                }
                field("Purch. Invoices Due Next Week"; Rec."Purch. Invoices Due Next Week")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of payments to vendors that are due next week.';
                }
            }
            cuegroup(Intercompany)
            {
                Caption = 'Intercompany';
                Visible = ShowIntercompanyActivities;
                field("IC Inbox Transactions"; Rec."IC Inbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Pending Inbox Transactions';
                    DrillDownPageID = "IC Inbox Transactions";
                    Visible = Rec."IC Inbox Transactions" <> 0;
                }
                field("IC Outbox Transactions"; Rec."IC Outbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Pending Outbox Transactions';
                    DrillDownPageID = "IC Outbox Transactions";
                    Visible = Rec."IC Outbox Transactions" <> 0;
                }
            }
            cuegroup(Payments)
            {
                Caption = 'Payments';
                field("Non-Applied Payments"; Rec."Non-Applied Payments")
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
                field("Average Collection Days"; Rec."Average Collection Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how long customers took to pay invoices in the last three months. This is the average number of days from when invoices are issued to when customers pay the invoices.';
                }
                field("Outstanding Vendor Invoices"; Rec."Outstanding Vendor Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of invoices from your vendors that have not been paid yet.';
                }
            }
            cuegroup(Camera)
            {
                Caption = 'Scan documents';
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
                            PictureName: Text;
                        begin
                            if not Camera.GetPicture(InStr, PictureName) then
                                exit;

                            IncomingDocument.CreateIncomingDocument(InStr, PictureName);
                            CurrPage.Update();
                        end;
                    }
                }
            }
            cuegroup("Incoming Documents")
            {
                Caption = 'Incoming Documents';
                field("My Incoming Documents"; Rec."My Incoming Documents")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies incoming documents that are assigned to you.';
                }
                field("Awaiting Verfication"; Rec."Inc. Doc. Awaiting Verfication")
                {
                    ApplicationArea = Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies incoming documents in OCR processing that require you to log on to the OCR service website to manually verify the OCR values before the documents can be received.';
                    Visible = ShowAwaitingIncomingDoc;

                    trigger OnDrillDown()
                    var
                        OCRServiceSetup: Record "OCR Service Setup";
                    begin
                        if OCRServiceSetup.Get() then
                            if OCRServiceSetup.Enabled then
                                HyperLink(OCRServiceSetup."Sign-in URL");
                    end;
                }
            }
            cuegroup("Data Integration")
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationCues;
                field("CDS Integration Errors"; Rec."CDS Integration Errors")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Integration Errors';
                    DrillDownPageID = "Integration Synch. Error List";
                    ToolTip = 'Specifies the number of errors related to data integration.';
                    Visible = ShowIntegrationErrorsCue;
                    StyleExpr = IntegrationErrorsCue;
                }
                field("Coupled Data Synch Errors"; Rec."Coupled Data Synch Errors")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Coupled Data Synchronization Errors';
                    DrillDownPageID = "CRM Skipped Records";
                    ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Sales.';
                    Visible = ShowD365SIntegrationCues;
                    StyleExpr = CoupledErrorsCue;
                }
            }
            cuegroup(MissingSIIEntries)
            {
                Caption = 'Missing SII Entries';
                field("Missing SII Entries"; Rec."Missing SII Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Missing SII Entries';
                    DrillDownPageID = "Recreate Missing SII Entries";
                    ToolTip = 'Specifies that some posted documents were not transferred to SII.';

                    trigger OnDrillDown()
                    var
                        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
                    begin
                        SIIRecreateMissingEntries.ShowRecreateMissingEntriesPage();
                    end;
                }
                field("Days Since Last SII Check"; Rec."Days Since Last SII Check")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Recreate Missing SII Entries";
                    Image = Calendar;
                    ToolTip = 'Specifies the number of days since the last check for missing SII entries.';
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
                            if UserTours.IsAvailable() and O365GettingStartedMgt.AreUserToursEnabled() then
                                UserTours.StartUserTour(O365GettingStartedMgt.GetChangeCompanyTourID());
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
                    Rec."Last Date/Time Modified" := 0DT;
                    Rec.Modify();

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
    begin
        if UserTours.IsAvailable() and O365GettingStartedMgt.AreUserToursEnabled() then
            O365GettingStartedMgt.UpdateGettingStartedVisible(TileGettingStartedVisible, ReplayGettingStartedVisible);
    end;

    trigger OnAfterGetRecord()
    begin
        SetActivityGroupVisibility();
    end;

    trigger OnInit()
    begin
        if UserTours.IsAvailable() and O365GettingStartedMgt.AreUserToursEnabled() then
            O365GettingStartedMgt.UpdateGettingStartedVisible(TileGettingStartedVisible, ReplayGettingStartedVisible);
    end;

    trigger OnOpenPage()
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        CRMIntegrationRecord: Record "CRM Integration Record";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
            Commit();
        end;

        Rec.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', WorkDate()), CalcDate('<1W>', WorkDate()));

        HasCamera := Camera.IsAvailable();

        PrepareOnLoadDialog();

        ShowAwaitingIncomingDoc := OCRServiceMgt.OcrServiceIsEnable();
        ShowIntercompanyActivities := false;
        ShowDocumentsPendingDocExchService := false;
        IntegrationSynchJobErrors.SetDataIntegrationUIElementsVisible(ShowDataIntegrationCues);
        ShowD365SIntegrationCues := CRMIntegrationManagement.IsIntegrationEnabled() or CDSIntegrationMgt.IsIntegrationEnabled();
        ShowIntegrationErrorsCue := ShowDataIntegrationCues and (not ShowD365SIntegrationCues);

        if IntegrationSynchJobErrors.IsEmpty() then
            IntegrationErrorsCue := 'Favorable'
        else
            IntegrationErrorsCue := 'Unfavorable';
        CRMIntegrationRecord.SetRange(Skipped, true);
        if CRMIntegrationRecord.IsEmpty() then
            CoupledErrorsCue := 'Favorable'
        else
            CoupledErrorsCue := 'Unfavorable';

        RoleCenterNotificationMgt.ShowNotifications();
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent();

        CalculateCueFieldValues();
    end;

    var
        ActivitiesMgt: Codeunit "Activities Mgt.";
        CuesAndKpis: Codeunit "Cues And KPIs";
        O365GettingStartedMgt: Codeunit "O365 Getting Started Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        Camera: Codeunit Camera;
        [RunOnClient]
        [WithEvents]
        UserTours: DotNet UserTours;
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        HasCamera: Boolean;
        ShowDocumentsPendingDocExchService: Boolean;
        ShowAwaitingIncomingDoc: Boolean;
        ShowIntercompanyActivities: Boolean;
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
        IntegrationErrorsCue: Text;
        CoupledErrorsCue: Text;

    procedure CalculateCueFieldValues()
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"O365 Activities Dictionary");
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        Session.LogMessage('00009V0', StrSubstNo(PBTTelemetryMsgTxt, ErrorCode, ErrorText, ErrorCallStack), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', PBTTelemetryCategoryLbl);

        if (TaskId <> TaskIdCalculateCue) then
            exit;

        if ActivitiesMgt.IsCueDataStale() then
            if not TASKSCHEDULER.CanCreateTask() then
                CODEUNIT.Run(CODEUNIT::"Activities Mgt.")
            else
                TASKSCHEDULER.CreateTask(CODEUNIT::"Activities Mgt.", 0, true, CompanyName, CurrentDateTime);

        IsHandled := true;
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        O365ActivitiesDictionary: Codeunit "O365 Activities Dictionary";
    begin
        if (TaskId = TaskIdCalculateCue) then begin
            Rec.LockTable(true);
            Rec.Get();
            O365ActivitiesDictionary.FillActivitiesCue(Results, Rec);
            Rec."Last Date/Time Modified" := CurrentDateTime;
            Rec.Modify(true);
        end
    end;

    local procedure SetActivityGroupVisibility()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ICSetup: Record "IC Setup";
    begin
        if DocExchServiceSetup.Get() then
            ShowDocumentsPendingDocExchService := DocExchServiceSetup.Enabled;

        if ICSetup.Get() then
            ShowIntercompanyActivities :=
              (ICSetup."IC Partner Code" <> '') and ((Rec."IC Inbox Transactions" <> 0) or (Rec."IC Outbox Transactions" <> 0));
    end;

    local procedure StartWhatIsNewTour(hasTourCompleted: Boolean): Boolean
    var
        O365UserTours: Record "User Tours";
        TourID: Integer;
    begin
        TourID := O365GettingStartedMgt.GetWhatIsNewTourID();

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
        HideWizardForDevices := PrepareUserTours();
        PreparePageNotifier();
    end;

    local procedure PreparePageNotifier()
    begin
        if not PageNotifier.IsAvailable() then
            exit;
        PageNotifier := PageNotifier.Create();
        PageNotifier.NotifyPageReady();
    end;

    local procedure PrepareUserTours(): Boolean
    begin
        if (not UserTours.IsAvailable()) or (not O365GettingStartedMgt.AreUserToursEnabled()) then
            exit(false);
        UserTours := UserTours.Create();
        UserTours.NotifyShowTourWizard();
        if O365GettingStartedMgt.IsGettingStartedSupported() then
            if O365GettingStartedMgt.WizardHasToBeLaunched(false) then
                HideSatisfactionSurvey := true;
        exit(true);
    end;

    trigger UserTours::ShowTourWizard(hasTourCompleted: Boolean)
    begin
        if O365GettingStartedMgt.IsGettingStartedSupported() then
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

