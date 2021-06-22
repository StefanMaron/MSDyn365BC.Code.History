table 5373 "CRM Full Synch. Review Line"
{
    Caption = 'CRM Full Synch. Review Line';

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
        }
        field(2; "Dependency Filter"; Text[250])
        {
            Caption = 'Dependency Filter';
        }
        field(3; "Session ID"; Integer)
        {
            Caption = 'Session ID';
        }
        field(4; "To Int. Table Job ID"; Guid)
        {
            Caption = 'To Int. Table Job ID';

            trigger OnValidate()
            begin
                "To Int. Table Job Status" := GetSynchJobStatus("To Int. Table Job ID");
            end;
        }
        field(5; "To Int. Table Job Status"; Option)
        {
            Caption = 'To Int. Table Job Status';
            OptionCaption = ' ,Success,In Process,Error';
            OptionMembers = " ",Success,"In Process",Error;
        }
        field(6; "From Int. Table Job ID"; Guid)
        {
            Caption = 'From Int. Table Job ID';

            trigger OnValidate()
            begin
                "From Int. Table Job Status" := GetSynchJobStatus("From Int. Table Job ID");
            end;
        }
        field(7; "From Int. Table Job Status"; Option)
        {
            Caption = 'From Int. Table Job Status';
            OptionCaption = ' ,Success,In Process,Error';
            OptionMembers = " ",Success,"In Process",Error;
        }
        field(8; Direction; Option)
        {
            Caption = 'Direction';
            Editable = false;
            OptionCaption = 'Bidirectional,To Integration Table,From Integration Table';
            OptionMembers = Bidirectional,"To Integration Table","From Integration Table";
        }
        field(9; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';

            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                if not IsNullGuid("Job Queue Entry ID") then
                    if JobQueueEntry.Get("Job Queue Entry ID") then
                        SetJobQueueEntryStatus(JobQueueEntry.Status)
                    else
                        SetJobQueueEntryStatus(JobQueueEntry.Status::Error)
            end;
        }
        field(10; "Job Queue Entry Status"; Option)
        {
            Caption = 'Job Queue Entry Status';
            OptionCaption = ' ,Ready,In Process,Error,On Hold,Finished';
            OptionMembers = " ",Ready,"In Process",Error,"On Hold",Finished;

            trigger OnValidate()
            begin
                if "Job Queue Entry Status" = "Job Queue Entry Status"::"In Process" then
                    "Session ID" := SessionId
                else
                    "Session ID" := 0;
            end;
        }
        field(13; "Initial Synch Recommendation"; Option)
        {
            OptionCaption = 'Full Synchronization,Couple Records,No Records Found,Dependency not satisfied';
            OptionMembers = "Full Synchronization","Couple Records","No Records Found","Dependency not satisfied";
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Generate(SkipEntitiesNotFullSyncReady: Boolean)
    begin
        GenerateCRMSynchReviewLines(SkipEntitiesNotFullSyncReady);
    end;

    procedure Generate()
    begin
        GenerateCRMSynchReviewLines(false);
    end;

    local procedure GenerateCRMSynchReviewLines(SkipNotFullSyncReady: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        "Field": Record "Field";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        OwnershipModel: Option;
        handled: Boolean;
    begin
        CRMSynchHelper.OnGetCDSOwnershipModel(OwnershipModel, handled);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if handled and (OwnershipModel = CDSConnectionSetup."Ownership Model"::Team) then
            IntegrationTableMapping.SetFilter(Name, '<>SALESPEOPLE');
        if IntegrationTableMapping.FindSet() then
            repeat
                InsertOrModifyCRMFullSynchReviewLines(IntegrationTableMapping, SkipNotFullSyncReady)
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure InsertOrModifyCRMFullSynchReviewLines(IntegrationTableMapping: Record "Integration Table Mapping"; SkipNotFullSyncReady: Boolean)
    begin
        if (not SkipNotFullSyncReady) or (GetInitialSynchRecommendation(IntegrationTableMapping) = "Initial Synch Recommendation"::"Full Synchronization") then begin
            Init;
            Name := IntegrationTableMapping.Name;
            if not Find('=') then begin
                Validate("Dependency Filter", IntegrationTableMapping."Dependency Filter");
                Validate("Initial Synch Recommendation", GetInitialSynchRecommendation(IntegrationTableMapping));
                Direction := IntegrationTableMapping.Direction;
                Insert(true);
            end else
                if "Job Queue Entry Status" = "Job Queue Entry Status"::" " then begin
                    Validate("Dependency Filter", IntegrationTableMapping."Dependency Filter");
                    Validate("Initial Synch Recommendation", GetInitialSynchRecommendation(IntegrationTableMapping));
                    Modify(true);
                end;
        end;
    end;

    procedure Start()
    var
        TempCRMFullSynchReviewLine: Record "CRM Full Synch. Review Line" temporary;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        JobQueueEntryID: Guid;
    begin
        if FindLinesThatCanBeStarted(TempCRMFullSynchReviewLine) then
            repeat
                JobQueueEntryID :=
                  CRMIntegrationManagement.EnqueueFullSyncJob(TempCRMFullSynchReviewLine.Name);
                Get(TempCRMFullSynchReviewLine.Name);
                Validate("Job Queue Entry ID", JobQueueEntryID);
                Modify(true);
                Commit();
            until TempCRMFullSynchReviewLine.Next = 0;
    end;


    local procedure GetInitialSynchRecommendation(IntegrationTableMapping: Record "Integration Table Mapping"): Option
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CDSRecRef: RecordRef;
        BCRecRef: RecordRef;
        DependencyInitialSynchRecommendation: Option "Full Synchronization","Couple Records","No Records Found","Dependency not satisfied";
    begin

        if IntegrationTableMapping."Dependency Filter" <> '' then
            if not IsDependencyFilterInitialSynchRecommendationFullSynchronization(IntegrationTableMapping."Dependency Filter") then
                exit("Initial Synch Recommendation"::"Dependency not satisfied");

        BCRecRef.Open(IntegrationTableMapping."Table ID");
        CDSRecRef.Open(IntegrationTableMapping."Integration Table ID");

        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");

        case IntegrationTableMapping.Name of
            'SALESPEOPLE':
                exit("Initial Synch Recommendation"::"Full Synchronization");
            'CURRENCY':
                begin
                    DependencyInitialSynchRecommendation := GetCurrencyInitialSynchRecommendation();
                    exit(DependencyInitialSynchRecommendation);
                end;
            'VENDOR':
                begin
                    CRMAccount.Reset();
                    CRMAccount.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
                    CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Vendor);
                    if BCRecRef.IsEmpty and CRMAccount.IsEmpty then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (not CRMAccount.IsEmpty()) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            'CUSTOMER':
                begin
                    CRMAccount.Reset();
                    CRMAccount.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
                    CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Customer);
                    if BCRecRef.IsEmpty and CRMAccount.IsEmpty then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (not CRMAccount.IsEmpty()) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            'CONTACT':
                begin
                    CRMContact.Reset();
                    CRMContact.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Contact"));
                    if BCRecRef.IsEmpty and CRMContact.IsEmpty then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (not CRMContact.IsEmpty()) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            else begin
                    if BCRecRef.IsEmpty and CDSRecRef.IsEmpty then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (not CDSRecRef.IsEmpty()) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
        end;

        exit("Initial Synch Recommendation"::"Full Synchronization");
    end;

    local procedure IsDependencyFilterInitialSynchRecommendationFullSynchronization(DependencyFilter: Text): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        DependencyInitialSynchRecommendation: Option "Full Synchronization","Couple Records","No Records Found","Dependency not satisfied";
        SingleDependencyFilter: Text;
    begin
        DependencyFilter := DependencyFilter + '|';
        while StrPos(DependencyFilter, '|') > 0 do begin
            SingleDependencyFilter := CopyStr(DependencyFilter, 1, StrPos(DependencyFilter, '|') - 1);
            if not (SingleDependencyFilter = 'SALESPEOPLE') then begin
                IntegrationTableMapping.Get(SingleDependencyFilter);
                DependencyInitialSynchRecommendation := GetInitialSynchRecommendation(IntegrationTableMapping);
                if DependencyInitialSynchRecommendation <> DependencyInitialSynchRecommendation::"Full Synchronization" then
                    exit(false);
            end;
            DependencyFilter := CopyStr(DependencyFilter, StrPos(DependencyFilter, '|') + 1);
        end;
        exit(true);
    end;

    local procedure GetCurrencyInitialSynchRecommendation(): Option
    var
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        CRMTransactionCurrency.Reset();
        CRMTransactionCurrency.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Transactioncurrency"));
        if CRMTransactionCurrency.Count() = 1 then
            if CRMTransactionCurrency.FindFirst() then
                if CRMTransactionCurrency.ExchangeRate = 1.00 then
                    exit("Initial Synch Recommendation"::"Full Synchronization");
        exit("Initial Synch Recommendation"::"Couple Records");
    end;

    local procedure UpdateAsSynchJobStarted(MapName: Code[20]; JobID: Guid; SynchDirection: Option)
    begin
        Get(MapName);
        Validate("Job Queue Entry ID");
        case SynchDirection of
            Direction::"From Integration Table":
                Validate("From Int. Table Job ID", JobID);
            Direction::"To Integration Table":
                Validate("To Int. Table Job ID", JobID);
        end;
        Modify(true);
        Commit();
    end;

    local procedure UpdateAsSynchJobFinished(MapName: Code[20]; SynchDirection: Option)
    begin
        Get(MapName);
        Validate("Job Queue Entry ID");
        case SynchDirection of
            Direction::"From Integration Table":
                Validate("From Int. Table Job ID");
            Direction::"To Integration Table":
                Validate("To Int. Table Job ID");
        end;
        Modify(true);
        Commit();
    end;

    local procedure GetSynchJobStatus(JobID: Guid): Integer
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if IsNullGuid(JobID) then
            exit("To Int. Table Job Status"::" ");

        IntegrationSynchJob.Get(JobID);
        if IntegrationSynchJob."Finish Date/Time" = 0DT then
            exit("To Int. Table Job Status"::"In Process");

        if IntegrationSynchJob.AreAllRecordsFailed then
            exit("To Int. Table Job Status"::Error);

        exit("To Int. Table Job Status"::Success);
    end;

    local procedure FindLinesThatCanBeStarted(var TempCRMFullSynchReviewLine: Record "CRM Full Synch. Review Line" temporary): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        TempCRMFullSynchReviewLine.Reset();
        TempCRMFullSynchReviewLine.DeleteAll();

        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        if CRMFullSynchReviewLine.FindSet then
            repeat
                if AreAllParentalJobsFinished(CRMFullSynchReviewLine."Dependency Filter") then begin
                    TempCRMFullSynchReviewLine := CRMFullSynchReviewLine;
                    TempCRMFullSynchReviewLine.Insert();
                end;
            until CRMFullSynchReviewLine.Next = 0;
        exit(TempCRMFullSynchReviewLine.FindSet);
    end;

    local procedure AreAllParentalJobsFinished(DependencyFilter: Text[250]): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        if DependencyFilter <> '' then begin
            CRMFullSynchReviewLine.SetFilter(Name, DependencyFilter);
            CRMFullSynchReviewLine.SetFilter(
              "Job Queue Entry Status", '<>%1', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
            exit(CRMFullSynchReviewLine.IsEmpty);
        end;
        exit(true);
    end;

    procedure FullSynchFinished(IntegrationTableMapping: Record "Integration Table Mapping"; SynchDirection: Option)
    begin
        if IntegrationTableMapping.IsFullSynch then
            UpdateAsSynchJobFinished(IntegrationTableMapping."Parent Name", SynchDirection);
    end;

    procedure FullSynchStarted(IntegrationTableMapping: Record "Integration Table Mapping"; JobID: Guid; SynchDirection: Option)
    begin
        if IntegrationTableMapping.IsFullSynch then
            UpdateAsSynchJobStarted(IntegrationTableMapping."Parent Name", JobID, SynchDirection);
    end;

    procedure OnBeforeModifyJobQueueEntry(JobQueueEntry: Record "Job Queue Entry")
    var
        NameToGet: Code[20];
    begin
        NameToGet := GetIntTableMappingNameJobQueueEntry(JobQueueEntry);
        if NameToGet = '' then
            exit;
        if Get(NameToGet) then begin
            SetJobQueueEntryStatus(JobQueueEntry.Status);
            Modify;

            if IsJobQueueEntryProcessed(JobQueueEntry) then
                Start;
        end;
    end;

    local procedure GetIntTableMappingNameJobQueueEntry(JobQueueEntry: Record "Job Queue Entry"): Code[20]
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecID: RecordID;
        RecRef: RecordRef;
    begin
        if Format(JobQueueEntry."Record ID to Process") = '' then
            exit;
        RecID := JobQueueEntry."Record ID to Process";
        if RecID.TableNo = DATABASE::"Integration Table Mapping" then begin
            RecRef := RecID.GetRecord;
            RecRef.SetTable(IntegrationTableMapping);
            if not IntegrationTableMapping.Find() then
                exit('');
            if IntegrationTableMapping.IsFullSynch then
                exit(IntegrationTableMapping."Parent Name");
        end;
    end;

    local procedure IsJobQueueEntryProcessed(JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        xJobQueueEntry: Record "Job Queue Entry";
    begin
        xJobQueueEntry := JobQueueEntry;
        xJobQueueEntry.Find;
        exit(
          (xJobQueueEntry.Status = xJobQueueEntry.Status::"In Process") and
          (xJobQueueEntry.Status <> JobQueueEntry.Status));
    end;

    procedure IsActiveSession(): Boolean
    begin
        exit(IsSessionActive("Session ID"));
    end;

    procedure IsThereActiveSessionInProgress(): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.SetFilter("Session ID", '<>0');
        CRMFullSynchReviewLine.SetRange("Job Queue Entry Status", "Job Queue Entry Status"::"In Process");
        if CRMFullSynchReviewLine.FindSet then
            repeat
                if CRMFullSynchReviewLine.IsActiveSession then
                    exit(true);
            until CRMFullSynchReviewLine.Next = 0;
        exit(false);
    end;

    procedure IsThereBlankStatusLine(): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.SetRange("Job Queue Entry Status", 0);
        exit(not CRMFullSynchReviewLine.IsEmpty);
    end;

    local procedure SetJobQueueEntryStatus(Status: Option)
    begin
        // shift the options to have an undefined state ' ' as 0.
        Validate("Job Queue Entry Status", Status + 1);
    end;

    procedure ShowJobQueueLogEntry()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, "Job Queue Entry ID");
        PAGE.RunModal(PAGE::"Job Queue Log Entries", JobQueueLogEntry);
    end;

    procedure ShowSynchJobLog(ID: Guid)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.SetRange(ID, ID);
        PAGE.RunModal(PAGE::"Integration Synch. Job List", IntegrationSynchJob);
    end;

    procedure GetStatusStyleExpression(StatusText: Text): Text
    begin
        case StatusText of
            'Error':
                exit('Unfavorable');
            'Finished', 'Success':
                exit('Favorable');
            'In Process':
                exit('Ambiguous');
            else
                exit('Subordinate');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetInitialSynchRecommendationStyleExpression(IntialSynchRecomeendation: Text): Text
    begin
        case IntialSynchRecomeendation of
            'Couple Records', 'No Records Found', 'Dependency not satisfied':
                exit('Unfavorable');
            'Full Synchronization':
                exit('Favorable');
            else
                exit('Subordinate');
        end;
    end;
}

