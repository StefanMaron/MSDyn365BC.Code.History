codeunit 5150 "Integration Management"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Invoice Line" = rm,
                  TableData "Marketing Setup" = r,
                  TableData "Integration Table Mapping" = r,
                  TableData "Integration Record" = rm;
    SingleInstance = true;
    ObsoleteReason = 'Integration Management will be removed. Refactor the code to use systemID and other system fields such as systemLastModifiedDateTime.';
    ObsoleteState = Pending;
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        IntegrationIsActivated: Boolean;
        PageServiceNameTok: Label 'Integration %1';
        IntegrationServicesEnabledMsg: Label 'Integration services have been enabled.\The %1 service should be restarted.', Comment = '%1 - product name';
        IntegrationServicesDisabledMsg: Label 'Integration services have been disabled.\The %1 service should be restarted.', Comment = '%1 - product name';
        HideMessages: Boolean;
        IntegrationManagementDisabledLbl: Label 'DisableIntegrationManagement';

    procedure GetDatabaseTableTriggerSetup(TableID: Integer; var Insert: Boolean; var Modify: Boolean; var Delete: Boolean; var Rename: Boolean)
    var
        Enabled: Boolean;
    begin
        if CompanyName = '' then
            exit;

        if not GetIntegrationActivated then
            exit;

        OnEnabledDatabaseTriggersSetup(TableID, Enabled);
        if not Enabled then
            Enabled := IsIntegrationRecord(TableID) or IsIntegrationRecordChild(TableID);

        if Enabled then begin
            Insert := true;
            Modify := true;
            Delete := true;
            Rename := true;
        end;
    end;

    procedure OnDatabaseInsert(RecRef: RecordRef)
    var
        TimeStamp: DateTime;
    begin
        if not GetIntegrationActivated then
            exit;

        TimeStamp := CurrentDateTime;
        UpdateParentIntegrationRecord(RecRef, TimeStamp);
        InsertUpdateIntegrationRecord(RecRef, TimeStamp);
    end;

    procedure OnDatabaseModify(RecRef: RecordRef)
    var
        TimeStamp: DateTime;
        SourceRecRef: RecordRef;
    begin
        if not GetIntegrationActivated then
            exit;

        // Verify record exists - Calling if modify then; on non existing records would fail
        if IsNullGuid(RecRef.Field(RecRef.SystemIdNo()).Value) then
            if not SourceRecRef.Get(RecRef.RecordId()) then
                exit;

        TimeStamp := CurrentDateTime;
        UpdateParentIntegrationRecord(RecRef, TimeStamp);
        InsertUpdateIntegrationRecord(RecRef, TimeStamp);
    end;

    procedure OnDatabaseDelete(RecRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        IntegrationRecord: Record "Integration Record";
        IntegrationRecordArchive: Record "Integration Record Archive";
        SkipDeletion: Boolean;
        TimeStamp: DateTime;
    begin
        if not GetIntegrationActivated then
            exit;

        TimeStamp := CurrentDateTime;
        UpdateParentIntegrationRecord(RecRef, TimeStamp);
        if IsIntegrationRecord(RecRef.Number) then
            if IntegrationRecord.FindBySystemId(RecRef.RecordId, RecRef.Field(RecRef.SystemIdNo).Value) then begin
                // Handle exceptions where "Deleted On" should not be set.
                if RecRef.Number = DATABASE::"Sales Header" then begin
                    RecRef.SetTable(SalesHeader);
                    SkipDeletion := SalesHeader.Invoice;
                end;

                // Archive
                IntegrationRecordArchive.TransferFields(IntegrationRecord);
                if IntegrationRecordArchive.Insert() then;

                if not SkipDeletion then begin
                    OnDeleteIntegrationRecord(RecRef);
                    IntegrationRecord."Deleted On" := TimeStamp;
                end;

                Clear(IntegrationRecord."Record ID");
                IntegrationRecord."Modified On" := TimeStamp;
                IntegrationRecord.Modify();
            end;
    end;

    procedure OnDatabaseRename(RecRef: RecordRef; XRecRef: RecordRef)
    var
        IntegrationRecord: Record "Integration Record";
        TimeStamp: DateTime;
    begin
        if not GetIntegrationActivated then
            exit;

        TimeStamp := CurrentDateTime;
        UpdateParentIntegrationRecord(RecRef, TimeStamp);
        if IsIntegrationRecord(RecRef.Number) then
            if IntegrationRecord.FindByRecordId(XRecRef.RecordId) then begin
                IntegrationRecord."Record ID" := RecRef.RecordId;
                IntegrationRecord.Modify();
            end;

        InsertUpdateIntegrationRecord(RecRef, TimeStamp);
    end;

    local procedure UpdateParentIntegrationRecord(RecRef: RecordRef; TimeStamp: DateTime)
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
#if not CLEAN19
        SalesPrice: Record "Sales Price";
        CustomerPriceGroup: Record "Customer Price Group";
#endif
        ContactProfileAnswer: Record "Contact Profile Answer";
        ContactAltAddress: Record "Contact Alt. Address";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        Contact: Record Contact;
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ParentRecRef: RecordRef;
    begin
        // Handle cases where entities change should update the parent record
        // Function must not fail even if the parent record cannot be found
        case RecRef.Number of
            DATABASE::"Sales Line":
                begin
                    RecRef.SetTable(SalesLine);
                    if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then begin
                        ParentRecRef.GetTable(SalesHeader);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
            DATABASE::"Sales Invoice Line":
                begin
                    RecRef.SetTable(SalesInvoiceLine);
                    if SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.") then begin
                        ParentRecRef.GetTable(SalesInvoiceHeader);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
            DATABASE::"Sales Cr.Memo Line":
                begin
                    RecRef.SetTable(SalesCrMemoLine);
                    if SalesCrMemoHeader.Get(SalesCrMemoLine."Document No.") then begin
                        ParentRecRef.GetTable(SalesCrMemoHeader);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
#if not CLEAN19
            DATABASE::"Sales Price":
                begin
                    RecRef.SetTable(SalesPrice);
                    if SalesPrice."Sales Type" <> SalesPrice."Sales Type"::"Customer Price Group" then
                        exit;

                    if CustomerPriceGroup.Get(SalesPrice."Sales Code") then begin
                        ParentRecRef.GetTable(CustomerPriceGroup);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
#endif
            DATABASE::"Ship-to Address":
                begin
                    RecRef.SetTable(ShipToAddress);
                    if Customer.Get(ShipToAddress."Customer No.") then begin
                        ParentRecRef.GetTable(Customer);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
            DATABASE::"Currency Exchange Rate":
                begin
                    RecRef.SetTable(CurrencyExchangeRate);
                    if Currency.Get(CurrencyExchangeRate."Currency Code") then begin
                        ParentRecRef.GetTable(Currency);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
            DATABASE::"Contact Alt. Address":
                begin
                    RecRef.SetTable(ContactAltAddress);
                    if Contact.Get(ContactAltAddress."Contact No.") then begin
                        ParentRecRef.GetTable(Contact);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
            DATABASE::"Contact Profile Answer":
                begin
                    RecRef.SetTable(ContactProfileAnswer);
                    if Contact.Get(ContactProfileAnswer."Contact No.") then begin
                        ParentRecRef.GetTable(Contact);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
            DATABASE::"Rlshp. Mgt. Comment Line":
                begin
                    RecRef.SetTable(RlshpMgtCommentLine);
                    if RlshpMgtCommentLine."Table Name" = RlshpMgtCommentLine."Table Name"::Contact then
                        if Contact.Get(RlshpMgtCommentLine."No.") then begin
                            ParentRecRef.GetTable(Contact);
                            InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                        end;
                end;
            DATABASE::"Vendor Bank Account":
                begin
                    RecRef.SetTable(VendorBankAccount);
                    if Vendor.Get(VendorBankAccount."Vendor No.") then begin
                        ParentRecRef.GetTable(Vendor);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
            DATABASE::"Purchase Line":
                begin
                    RecRef.SetTable(PurchaseLine);
                    if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then begin
                        ParentRecRef.GetTable(PurchaseHeader);
                        InsertUpdateIntegrationRecord(ParentRecRef, TimeStamp);
                    end;
                end;
        end;
        OnAfterUpdateParentIntegrationRecord(RecRef, TimeStamp);
    end;

    procedure SetupIntegrationTables()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TableId: Integer;
    begin
        CreateIntegrationPageList(TempNameValueBuffer);
        TempNameValueBuffer.FindFirst();
        repeat
            Evaluate(TableId, TempNameValueBuffer.Value);
            InitializeIntegrationRecords(TableId);
        until TempNameValueBuffer.Next() = 0;
    end;

    procedure CreateIntegrationPageList(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        NextId: Integer;
    begin
        with TempNameValueBuffer do begin
            DeleteAll();
            NextId := 1;

            AddToIntegrationPageList(PAGE::"Resource List", DATABASE::Resource, TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Payment Terms", DATABASE::"Payment Terms", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Shipment Methods", DATABASE::"Shipment Method", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Shipping Agents", DATABASE::"Shipping Agent", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::Currencies, DATABASE::Currency, TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Salespersons/Purchasers", DATABASE::"Salesperson/Purchaser", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Customer Card", DATABASE::Customer, TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Vendor Card", DATABASE::Vendor, TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Company Information", DATABASE::"Company Information", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Item Card", DATABASE::Item, TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"G/L Account Card", DATABASE::"G/L Account", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Sales Order", DATABASE::"Sales Header", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Sales Invoice", DATABASE::"Sales Header", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Sales Credit Memo", DATABASE::"Sales Header", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"General Journal Batches", DATABASE::"Gen. Journal Batch", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(
              PAGE::"VAT Business Posting Groups", DATABASE::"VAT Business Posting Group", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"VAT Product Posting Groups", DATABASE::"VAT Product Posting Group", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"VAT Clauses", DATABASE::"VAT Clause", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Tax Groups", DATABASE::"Tax Group", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Tax Area List", DATABASE::"Tax Area", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Posted Sales Invoice", DATABASE::"Sales Invoice Header", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Posted Sales Credit Memos", DATABASE::"Sales Cr.Memo Header", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Units of Measure", DATABASE::"Unit of Measure", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Ship-to Address", DATABASE::"Ship-to Address", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Contact Card", DATABASE::Contact, TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Countries/Regions", DATABASE::"Country/Region", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Shipment Methods", DATABASE::"Shipment Method", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Opportunity List", DATABASE::Opportunity, TempNameValueBuffer, NextId);
#if not CLEAN18
            AddToIntegrationPageList(PAGE::"Units of Measure Entity", DATABASE::"Unit of Measure", TempNameValueBuffer, NextId);
#endif
            AddToIntegrationPageList(PAGE::Dimensions, DATABASE::Dimension, TempNameValueBuffer, NextId);
#if not CLEAN18
            AddToIntegrationPageList(PAGE::"Item Categories Entity", DATABASE::"Item Category", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Currencies Entity", DATABASE::Currency, TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Country/Regions Entity", DATABASE::"Country/Region", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Payment Methods Entity", DATABASE::"Payment Method", TempNameValueBuffer, NextId);
            AddToIntegrationPageList(PAGE::"Employee Entity", DATABASE::Employee, TempNameValueBuffer, NextId);
#endif
            AddToIntegrationPageList(PAGE::"Unlinked Attachments", DATABASE::"Unlinked Attachment", TempNameValueBuffer, NextId);
#if not CLEAN18            
            AddToIntegrationPageList(PAGE::"Time Registration Entity", DATABASE::"Time Sheet Detail", TempNameValueBuffer, NextId);
#endif
        end;
        OnAfterAddToIntegrationPageList(TempNameValueBuffer, NextId);
    end;

    procedure IsIntegrationServicesEnabled(): Boolean
    var
        WebService: Record "Web Service";
    begin
        exit(WebService.Get(WebService."Object Type"::Codeunit, 'Integration Service'));
    end;

    procedure IsIntegrationActivated(): Boolean
    begin
        exit(GetIntegrationActivated);
    end;

    procedure EnableIntegrationServices()
    begin
        if IsIntegrationServicesEnabled then
            exit;

        SetupIntegrationService;
        SetupIntegrationServices;
        if not HideMessages then
            Message(IntegrationServicesEnabledMsg, PRODUCTNAME.Full);
    end;

    procedure DisableIntegrationServices()
    begin
        if not IsIntegrationServicesEnabled then
            exit;

        DeleteIntegrationService;
        DeleteIntegrationServices;

        Message(IntegrationServicesDisabledMsg, PRODUCTNAME.Full);
    end;

    procedure SetConnectorIsEnabledForSession(IsEnabled: Boolean)
    begin
        IntegrationIsActivated := IsEnabled;
    end;

    procedure IsIntegrationRecord(TableID: Integer): Boolean
    var
        isIntegrationRecord: Boolean;
    begin
        OnIsIntegrationRecord(TableID, isIntegrationRecord);

        if isIntegrationRecord then
            exit(true);

        exit(TableID in
          [DATABASE::Resource,
           DATABASE::"Shipping Agent",
           DATABASE::"Salesperson/Purchaser",
           DATABASE::Customer,
           DATABASE::Vendor,
           DATABASE::Dimension,
           DATABASE::"Dimension Value",
           DATABASE::"Company Information",
           DATABASE::Item,
           DATABASE::"G/L Account",
           DATABASE::"Sales Header",
           DATABASE::"Sales Invoice Header",
           DATABASE::"Gen. Journal Batch",
           DATABASE::"Sales Cr.Memo Header",
           DATABASE::"VAT Business Posting Group",
           DATABASE::"VAT Product Posting Group",
           DATABASE::"VAT Clause",
           DATABASE::"Tax Group",
           DATABASE::"Tax Area",
           DATABASE::"Unit of Measure",
           DATABASE::"Ship-to Address",
           DATABASE::Contact,
           DATABASE::"Country/Region",
           DATABASE::"Customer Price Group",
#if not CLEAN19
           DATABASE::"Sales Price",
#endif
           DATABASE::"Price List Header",
           DATABASE::"Price List Line",
           DATABASE::"Payment Terms",
           DATABASE::"Shipment Method",
           DATABASE::Opportunity,
           DATABASE::"Item Category",
           DATABASE::"Country/Region",
           DATABASE::"Payment Method",
           DATABASE::Currency,
           DATABASE::Employee,
           DATABASE::"Incoming Document Attachment",
           DATABASE::"Unlinked Attachment",
           DATABASE::"Purchase Header",
           DATABASE::"Purch. Inv. Header",
           DATABASE::"G/L Entry",
           DATABASE::Job,
           DATABASE::"Time Sheet Detail"]);
    end;

    [IntegrationEvent(false, false)]
    procedure OnIsIntegrationRecord(TableID: Integer; var isIntegrationRecord: Boolean)
    begin
    end;

    procedure IsIntegrationRecordChild(TableID: Integer) ReturnValue: Boolean
    var
        isIntegrationRecordChild: Boolean;
    begin
        OnIsIntegrationRecordChild(TableID, isIntegrationRecordChild, ReturnValue);
        if isIntegrationRecordChild then
            exit(ReturnValue);

        exit(TableID in
          [DATABASE::"Sales Line",
           DATABASE::"Currency Exchange Rate",
           DATABASE::"Sales Invoice Line",
           DATABASE::"Sales Cr.Memo Line",
           DATABASE::"Contact Alt. Address",
           DATABASE::"Contact Profile Answer",
           DATABASE::"Dimension Value",
           DATABASE::"Rlshp. Mgt. Comment Line",
           DATABASE::"Vendor Bank Account"]);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Feature Key", 'OnAfterModifyEvent', '', false, false)]
    local procedure GenerateIntegrationRecordsNotification(RunTrigger: Boolean; var Rec: Record "Feature Key"; var xRec: Record "Feature Key")
    var
        IntegrationManagementSetup: Codeunit "Integration Management Setup";
    begin
        if Rec.IsTemporary() then
            exit;

        if (Rec.ID = GetIntegrationManagementDisabledFeatureKey()) and (Rec.Enabled = Rec.Enabled::None) then
            if Confirm(IntegrationManagementSetup.GetConfigureIntegrationManagementUpdateQst()) then
                Page.Run(Page::"Integration Management Setup");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsIntegrationRecordChild(TableID: Integer; var isIntegrationRecordChild: Boolean; var ReturnValue: Boolean)
    begin
    end;

    procedure ResetIntegrationActivated()
    begin
        IntegrationIsActivated := false;
    end;

    [Obsolete('This function will be removed once the Feature Key is removed. We will not generate integration records in the future, they will be replaced by SystemId and SystemLastModified fields.', '17.0')]
    procedure GetIntegrationIsEnabledOnTheSystem(): Boolean
    var
        FeatureKey: Record "Feature Key";
        IntegrationEnabled: Boolean;
        IsEnabled: Boolean;
    begin
        OnGetIntegrationEnabledOnSystem(IsEnabled);
        if IsEnabled then
            exit(true);

        if not FeatureKey.Get(GetIntegrationManagementDisabledFeatureKey()) then
            exit(false);

        exit(not (FeatureKey.Enabled = FeatureKey.Enabled::"All Users"));
    end;

    [Obsolete('This function will be removed once the Feature Key is removed. We will not generate integration records in the future, they will be replaced by SystemId and SystemLastModified fields.', '17.0')]
    procedure GetIntegrationManagementDisabledFeatureKey(): Text[50]
    var
        FeatureKey: Record "Feature Key";
    begin
        exit(CopyStr(IntegrationManagementDisabledLbl, 1, MaxStrLen(FeatureKey.ID)));
    end;

    local procedure GetIntegrationActivated(): Boolean
    var
        IsSyncEnabled: Boolean;
        IsSyncDisabled: Boolean;
    begin
        OnGetIntegrationDisabled(IsSyncDisabled);
        if IsSyncDisabled then
            exit(false);

        if not GetIntegrationIsEnabledOnTheSystem() then
            exit(false);

        if not IntegrationIsActivated then begin
            OnGetIntegrationActivated(IsSyncEnabled);
            if IsSyncEnabled then
                IntegrationIsActivated := true
            else
                IntegrationIsActivated := IsCRMConnectionEnabled;
        end;

        exit(IntegrationIsActivated);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIntegrationActivated(var IsSyncEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIntegrationDisabled(var IsSyncDisabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnabledDatabaseTriggersSetup(TableID: Integer; var Enabled: Boolean)
    begin
    end;

    local procedure IsCRMConnectionEnabled(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.Get then
            exit(false);

        exit(CRMConnectionSetup."Is Enabled");
    end;

    local procedure SetupIntegrationService()
    var
        WebService: Record "Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateWebService(
          WebService."Object Type"::Codeunit, CODEUNIT::"Integration Service", 'Integration Service', true);
    end;

    local procedure DeleteIntegrationService()
    var
        WebService: Record "Web Service";
    begin
        if WebService.Get(WebService."Object Type"::Codeunit, 'Integration Service') then
            WebService.Delete();
    end;

    local procedure SetupIntegrationServices()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        WebService: Record "Web Service";
        Objects: Record AllObj;
        WebServiceManagement: Codeunit "Web Service Management";
        PageId: Integer;
    begin
        CreateIntegrationPageList(TempNameValueBuffer);
        TempNameValueBuffer.FindFirst();

        repeat
            Evaluate(PageId, TempNameValueBuffer.Name);

            Objects.SetRange("Object Type", Objects."Object Type"::Page);
            Objects.SetRange("Object ID", PageId);
            if Objects.FindFirst() then
                WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Objects."Object ID",
                  StrSubstNo(PageServiceNameTok, Objects."Object Name"), true);
        until TempNameValueBuffer.Next() = 0;
    end;

    local procedure DeleteIntegrationServices()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        WebService: Record "Web Service";
        Objects: Record AllObj;
        PageId: Integer;
    begin
        CreateIntegrationPageList(TempNameValueBuffer);
        TempNameValueBuffer.FindFirst();

        WebService.SetRange("Object Type", WebService."Object Type"::Page);
        repeat
            Evaluate(PageId, TempNameValueBuffer.Name);
            WebService.SetRange("Object ID", PageId);

            Objects.SetRange("Object Type", WebService."Object Type"::Page);
            Objects.SetRange("Object ID", PageId);
            if Objects.FindFirst() then begin
                WebService.SetRange("Service Name", StrSubstNo(PageServiceNameTok, Objects."Object Name"));
                if WebService.FindFirst() then
                    WebService.Delete();
            end;
        until TempNameValueBuffer.Next() = 0;
    end;

    [Scope('Cloud')]
    procedure InitializeIntegrationRecords(TableID: Integer)
    var
        RecRef: RecordRef;
    begin
        with RecRef do begin
            Open(TableID, false);
            if FindSet(false) then
                repeat
                    InsertUpdateIntegrationRecord(RecRef, CurrentDateTime);
                until Next() = 0;
            Close;
        end;
    end;

    procedure InsertUpdateIntegrationRecord(RecRef: RecordRef; IntegrationLastModified: DateTime) IntegrationID: Guid
    var
        IntegrationRecord: Record "Integration Record";
        SourceRecordRef: RecordRef;
        ConstBlankRecordId: RecordId;
        Handled: Boolean;
    begin
        if IsIntegrationRecord(RecRef.Number) then
            with IntegrationRecord do begin
                if FindBySystemId(RecRef.RecordId, RecRef.Field(RecRef.SystemIdNo).Value) then begin
                    "Modified On" := IntegrationLastModified;
                    UpdateReferencedIdField("Integration ID", RecRef, Handled);
                    OnUpdateRelatedRecordIdFields(RecRef);
                    Modify;
                end else begin
                    Reset;
                    Init;
                    "Integration ID" := RecRef.Field(RecRef.SystemIdNo).Value;
                    "Record ID" := RecRef.RecordId;
                    "Table ID" := RecRef.Number;
                    "Modified On" := IntegrationLastModified;

                    // This is needed if Modify is called without fetching the record (by assigning primary key)
                    if IsNullGuid("Integration ID") then
                        if "Record Id" <> ConstBlankRecordId then
                            if SourceRecordRef.Get("Record Id") then
                                "Integration ID" := SourceRecordRef.Field(SourceRecordRef.SystemIdNo).Value;

                    Insert(true);

                    UpdateReferencedIdField("Integration ID", RecRef, Handled);
                    OnUpdateRelatedRecordIdFields(RecRef);
                end;

                IntegrationID := "Integration ID";
                ReactivateJobForTable(RecRef.Number);
            end;
    end;

    local procedure ReactivateJobForTable(TableNo: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        MomentForJobToBeReady: DateTime;
        EarliestStartDateTime: DateTime;
    begin
        if DataUpgradeMgt.IsUpgradeInProgress then
            exit;
        JobQueueEntry.FilterInactiveOnHoldEntries;
        JobQueueEntry.SetRange("Recurring Job", true);
        if JobQueueEntry.IsEmpty() then
            exit;
        if not UserCanRescheduleJob() then
            exit;
        if JobQueueEntry.FindSet(true) then
            repeat
                // Restart only those jobs whose time to re-execute has nearly arrived.
                // This postpones locking of the Job Queue Entries when restarting.
                // The rescheduled task might start while the current transaction is not committed yet.
                // Therefore the task will restart with a delay to lower a risk of use of "old" data.
                MomentForJobToBeReady := JobQueueDispatcher.CalcNextReadyStateMoment(JobQueueEntry);
                EarliestStartDateTime := CurrentDateTime() + 5000; // five seconds delay
                if EarliestStartDateTime > MomentForJobToBeReady then
                    if DoesJobActOnTable(JobQueueEntry, TableNo) then begin
                        JobQueueEntry.RefreshLocked();
                        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                        JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
                        JobQueueEntry.Modify();
                        if TaskScheduler.SetTaskReady(JobQueueEntry."System Task ID", EarliestStartDateTime) then;
                    end;
            until JobQueueEntry.Next() = 0;
    end;

    local procedure DoesJobActOnTable(JobQueueEntry: Record "Job Queue Entry"; TableNo: Integer): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
    begin
        if RecRef.Get(JobQueueEntry."Record ID to Process") and
           (RecRef.Number = DATABASE::"Integration Table Mapping")
        then begin
            RecRef.SetTable(IntegrationTableMapping);
            exit(IntegrationTableMapping."Table ID" = TableNo);
        end;
    end;

    local procedure UserCanRescheduleJob(): Boolean
    Var
        JobQueueEntry: Record "Job Queue Entry";
        DummyErrorMessageRegister: Record "Error Message Register";
        DummyErrorMessage: Record "Error Message";
    begin
        If not JobQueueEntry.ReadPermission then
            exit(false);
        if not JobQueueEntry.WritePermission then
            exit(false);
        if not DummyErrorMessageRegister.WritePermission then
            exit(false);
        if not DummyErrorMessage.WritePermission then
            exit(false);
        if not TaskScheduler.CanCreateTask() then
            exit(false);

        exit(true);
    end;

    local procedure AddToIntegrationPageList(PageId: Integer; TableId: Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var NextId: Integer)
    begin
        with TempNameValueBuffer do begin
            Init;
            ID := NextId;
            NextId := NextId + 1;
            Name := Format(PageId);
            Value := Format(TableId);
            Insert;
        end;
    end;

    procedure SetHideMessages(HideMessagesNew: Boolean)
    begin
        HideMessages := HideMessagesNew;
    end;

    procedure GetIdWithoutBrackets(Id: Guid): Text
    begin
        exit(CopyStr(Format(Id), 2, StrLen(Format(Id)) - 2));
    end;

    [Obsolete('Integration Records will be replaced by SystemID and SystemModifiedAt ', '17.0')]
    local procedure UpdateReferencedIdField(var Id: Guid; var RecRef: RecordRef; var Handled: Boolean)
    var
        DummyGLAccount: Record "G/L Account";
        DummyTaxGroup: Record "Tax Group";
        DummyVATProductPostingGroup: Record "VAT Product Posting Group";
        DummyGenJournalBatch: Record "Gen. Journal Batch";
        DummyCustomer: Record Customer;
        DummyVendor: Record Vendor;
        DummyCompanyInfo: Record "Company Information";
        DummyItem: Record Item;
        DummySalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        DummyPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        DummyEmployee: Record Employee;
        DummyCurrency: Record Currency;
        DummyPaymentMethod: Record "Payment Method";
        DummyDimension: Record Dimension;
        DummyDimensionValue: Record "Dimension Value";
        DummyPaymentTerms: Record "Payment Terms";
        DummyShipmentMethod: Record "Shipment Method";
        DummyItemCategory: Record "Item Category";
        DummyCountryRegion: Record "Country/Region";
        DummyUnitOfMeasure: Record "Unit of Measure";
        DummyPurchaseHeader: Record "Purchase Header";
        DummyUnlinkedAttachment: Record "Unlinked Attachment";
        DummyTaxArea: Record "Tax Area";
        DummySalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        DummyIncomingDocumentAttachment: Record "Incoming Document Attachment";
        DummyTimeSheetDetail: Record "Time Sheet Detail";
        DummyJob: Record Job;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GraphMgtSalesHeader: Codeunit "Graph Mgt - Sales Header";
    begin
        case RecRef.Number of
            DATABASE::"G/L Account":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"G/L Account", DummyGLAccount.FieldNo(Id));
            DATABASE::"Tax Group":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, RecRef.Number, DummyTaxGroup.FieldNo(Id));
            DATABASE::"VAT Product Posting Group":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, RecRef.Number, DummyVATProductPostingGroup.FieldNo(Id));
            DATABASE::"Gen. Journal Batch":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Gen. Journal Batch", DummyGenJournalBatch.FieldNo(Id));
            DATABASE::Customer:
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::Customer, DummyCustomer.FieldNo(Id));
            DATABASE::Vendor:
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::Vendor, DummyVendor.FieldNo(Id));
            DATABASE::"Company Information":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Company Information", DummyCompanyInfo.FieldNo(Id));
            DATABASE::Item:
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::Item, DummyItem.FieldNo(Id));
            DATABASE::"Sales Header":
                GraphMgtSalesHeader.UpdateReferencedIdFieldOnSalesHeader(RecRef, Id, Handled);
            DATABASE::"Sales Invoice Header":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, RecRef.Number, DummySalesInvoiceEntityAggregate.FieldNo(Id));
            DATABASE::Employee:
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::Employee, DummyEmployee.FieldNo(Id));
            DATABASE::Currency:
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::Currency, DummyCurrency.FieldNo(Id));
            DATABASE::"Payment Method":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::"Payment Method", DummyPaymentMethod.FieldNo(Id));
            DATABASE::Dimension:
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::Dimension, DummyDimension.FieldNo(Id));
            DATABASE::"Dimension Value":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Dimension Value", DummyDimensionValue.FieldNo(Id));
            DATABASE::"Payment Terms":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Payment Terms", DummyPaymentTerms.FieldNo(Id));
            DATABASE::"Shipment Method":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Shipment Method", DummyShipmentMethod.FieldNo(Id));
            DATABASE::"Item Category":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::"Item Category", DummyItemCategory.FieldNo(Id));
            DATABASE::"Country/Region":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::"Country/Region", DummyCountryRegion.FieldNo(Id));
            DATABASE::"Unit of Measure":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Unit of Measure", DummyUnitOfMeasure.FieldNo(Id));
            DATABASE::"Purchase Header":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::"Purchase Header", DummyPurchaseHeader.FieldNo(Id));
            DATABASE::"Unlinked Attachment":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Unlinked Attachment", DummyUnlinkedAttachment.FieldNo(Id));
            DATABASE::"VAT Business Posting Group", DATABASE::"Tax Area", DATABASE::"VAT Clause":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, RecRef.Number, DummyTaxArea.FieldNo(Id));
            DATABASE::"Sales Cr.Memo Header":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Sales Cr.Memo Header", DummySalesCrMemoEntityBuffer.FieldNo(Id));
            DATABASE::"Purch. Inv. Header":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, RecRef.Number, DummyPurchInvEntityAggregate.FieldNo(Id));
            DATABASE::"Incoming Document Attachment":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(
                  RecRef, Id, Handled, DATABASE::"Incoming Document Attachment", DummyIncomingDocumentAttachment.FieldNo(Id));
            DATABASE::"Time Sheet Detail":
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::"Time Sheet Detail", DummyTimeSheetDetail.FieldNo(Id));
            DATABASE::"Sales Invoice Line", DATABASE::"Purch. Inv. Line", DATABASE::"Vendor Bank Account":
                Handled := true;
            DATABASE::Job:
                GraphMgtGeneralTools.HandleUpdateReferencedIdFieldOnItem(RecRef, Id, Handled,
                  DATABASE::Job, DummyJob.FieldNo(Id));
            else
                OnUpdateReferencedIdField(RecRef, Id, Handled);
        end;
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('This function will be removed once the Feature Key is removed. We will not generate integration records in the future, they will be replaced by SystemId and SystemLastModified fields.', '17.0')]
    local procedure OnGetIntegrationEnabledOnSystem(var IsEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteIntegrationRecord(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateReferencedIdField(var RecRef: RecordRef; NewId: Guid; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRelatedRecordIdFields(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateParentIntegrationRecord(RecRef: RecordRef; TimeStamp: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddToIntegrationPageList(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var NextId: Integer)
    begin
    end;
}

