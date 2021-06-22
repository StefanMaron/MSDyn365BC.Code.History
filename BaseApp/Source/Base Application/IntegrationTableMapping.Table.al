table 5335 "Integration Table Mapping"
{
    Caption = 'Integration Table Mapping';
    DrillDownPageID = "Integration Table Mapping List";
    LookupPageID = "Integration Table Mapping List";

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = "Table Metadata".ID;
        }
        field(3; "Integration Table ID"; Integer)
        {
            Caption = 'Integration Table ID';
            TableRelation = "Table Metadata".ID;
        }
        field(4; "Synch. Codeunit ID"; Integer)
        {
            Caption = 'Synch. Codeunit ID';
            TableRelation = "Table Metadata".ID;
        }
        field(5; "Integration Table UID Fld. No."; Integer)
        {
            Caption = 'Integration Table UID Fld. No.';
            Description = 'Integration Table Unique Identifier Field No.';

            trigger OnValidate()
            var
                "Field": Record "Field";
                TypeHelper: Codeunit "Type Helper";
            begin
                Field.Get("Integration Table ID", "Integration Table UID Fld. No.");
                TypeHelper.TestFieldIsNotObsolete(Field);
                "Int. Table UID Field Type" := Field.Type;
            end;
        }
        field(6; "Int. Tbl. Modified On Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. Modified On Fld. No.';
            Description = 'Integration Table Modified On Field No.';
        }
        field(7; "Int. Table UID Field Type"; Integer)
        {
            Caption = 'Int. Table UID Field Type';
            Editable = false;
        }
        field(8; "Table Config Template Code"; Code[10])
        {
            Caption = 'Table Config Template Code';
            TableRelation = "Config. Template Header".Code WHERE("Table ID" = FIELD("Table ID"));
        }
        field(9; "Int. Tbl. Config Template Code"; Code[10])
        {
            Caption = 'Int. Tbl. Config Template Code';
            TableRelation = "Config. Template Header".Code WHERE("Table ID" = FIELD("Integration Table ID"));
        }
        field(10; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(11; "Int. Tbl. Caption Prefix"; Text[30])
        {
            Caption = 'Int. Tbl. Caption Prefix';
        }
        field(12; "Synch. Int. Tbl. Mod. On Fltr."; DateTime)
        {
            Caption = 'Synch. Int. Tbl. Mod. On Fltr.';
            Description = 'Scheduled synch. Integration Table Modified On Filter';
        }
        field(13; "Synch. Modified On Filter"; DateTime)
        {
            Caption = 'Synch. Modified On Filter';
            Description = 'Scheduled synch. Modified On Filter';
        }
        field(14; "Table Filter"; BLOB)
        {
            Caption = 'Table Filter';
        }
        field(15; "Integration Table Filter"; BLOB)
        {
            Caption = 'Integration Table Filter';
        }
        field(16; "Synch. Only Coupled Records"; Boolean)
        {
            Caption = 'Synch. Only Coupled Records';
            InitValue = true;
        }
        field(17; "Parent Name"; Code[20])
        {
            Caption = 'Parent Name';
        }
        field(18; "Graph Delta Token"; Text[250])
        {
            Caption = 'Graph Delta Token';
        }
        field(19; "Int. Tbl. Delta Token Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. Delta Token Fld. No.';
        }
        field(20; "Int. Tbl. ChangeKey Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. ChangeKey Fld. No.';
        }
        field(21; "Int. Tbl. State Fld. No."; Integer)
        {
            Caption = 'Int. Tbl. State Fld. No.';
        }
        field(22; "Delete After Synchronization"; Boolean)
        {
            Caption = 'Delete After Synchronization';
        }
        field(23; "BC Rec Page Id"; Integer)
        {
            Caption = 'The Id of the BC Record Page';
        }
        field(24; "CDS Rec Page Id"; Integer)
        {
            Caption = 'The Id of the Dataverse Record Page';
        }
        field(25; "Deletion-Conflict Resolution"; Enum "Integration Deletion Conflict Resolution")
        {
            Caption = 'Resolve Deletion Conflicts';
        }
        field(26; "Update-Conflict Resolution"; Enum "Integration Update Conflict Resolution")
        {
            Caption = 'Resolve Update Conflicts';
        }
        field(27; "Uncouple Codeunit ID"; Integer)
        {
            Caption = 'Uncouple Codeunit ID';
            TableRelation = "Table Metadata".ID;
        }
        field(30; "Dependency Filter"; Text[250])
        {
            Caption = 'Dependency Filter';
        }
        field(100; "Full Sync is Running"; Boolean)
        {
            Caption = 'Full Sync is Running';
            Description = 'This is set to TRUE when FullSync starts, and to FALSE when FullSync completes.';

            trigger OnValidate()
            begin
                if xRec.Get(Name) then;
                if (not xRec."Full Sync is Running") and "Full Sync is Running" then begin
                    "Last Full Sync Start DateTime" := CurrentDateTime;
                    "Full Sync Session ID" := SessionId;
                end;
                if not "Full Sync is Running" then
                    "Full Sync Session ID" := 0;
            end;
        }
        field(101; "Full Sync Session ID"; Integer)
        {
            Caption = 'Full Sync Session ID';
            Description = 'The ID of the session running the FullSync must be 0 if FullSync is not running.';
        }
        field(102; "Last Full Sync Start DateTime"; DateTime)
        {
            Caption = 'Last Full Sync Start DateTime';
            Description = 'The starting date and time of the last time FullSync was run. This is used to re-run in case FullSync failed to reset these fields.';
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

    trigger OnDelete()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Name);
        IntegrationFieldMapping.DeleteAll();

        CRMOptionMapping.SetRange("Table ID", "Table ID");
        CRMOptionMapping.SetRange("Integration Table ID", "Integration Table ID");
        CRMOptionMapping.SetRange("Integration Field ID", "Integration Table UID Fld. No.");
        CRMOptionMapping.DeleteAll();
    end;

    trigger OnInsert()
    var
        IntegrationManagement: Codeunit "Integration Management";
    begin
        if not ("Table ID" in [Database::Contact, Database::Customer, Database::Item, Database::Vendor,
                                Database::Resource, Database::Opportunity, Database::Currency, Database::"Customer Price Group",
                                Database::"Sales Invoice Header", Database::"Sales Invoice Line", Database::"Sales Price",
                                Database::"Unit of Measure", Database::"Payment Terms", Database::"Shipment Method", Database::"Shipping Agent", DATABASE::"Salesperson/Purchaser"]) then
            if IntegrationManagement.IsIntegrationActivated() then
                IntegrationManagement.InitializeIntegrationRecords("Table ID");
    end;

    var
        JobLogEntryNo: Integer;
        ConfirmIncludeEntitiesWithNoCompanyQst: Label 'Do you want the Integration Table Filter to include %1 entities with no value in %2 attribute?', Comment = '%1 - Dataverse service name; %2 - attribute name of a Dataverse entity';
        UserChoseNotToIncludeEntitiesWithEmptyCompanyNameTxt: Label 'User chose not to include %1 entities with empty company id in the Integration Table Filter of the %2 mapping.', Locked = true;
        TelemetryCategoryTok: Label 'AL Dataverse Integration', Locked = true;
        CompanyIdFieldNameTxt: Label 'CompanyId', Locked = true;

    procedure FindFilteredRec(RecordRef: RecordRef; var OutOfMapFilter: Boolean) Found: Boolean
    var
        OutlookSynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
        TempRecRef: RecordRef;
    begin
        TempRecRef.Open(RecordRef.Number, true);
        OutlookSynchNAVMgt.CopyRecordReference(RecordRef, TempRecRef, false);
        if "Table ID" = RecordRef.Number then
            SetRecordRefFilter(TempRecRef)
        else
            SetIntRecordRefFilter(TempRecRef);
        Found := TempRecRef.Find;
        OutOfMapFilter := not Found;
        TempRecRef.Close;
    end;

    [Scope('Cloud')]
    procedure FindMapping(TableNo: Integer; IntegrationTableNo: Integer): Boolean
    begin
        SetRange("Table ID", TableNo);
        SetRange("Integration Table ID", IntegrationTableNo);
        SetRange("Delete After Synchronization", false);
        exit(FindFirst());
    end;

#if not CLEAN18
    [Obsolete('Use another implementation of FindMapping', '18.0')]
    procedure FindMapping(TableNo: Integer; PrimaryKey: Variant): Boolean
    begin
        if PrimaryKey.IsRecordId then
            exit(FindMappingForTable(TableNo));
        if PrimaryKey.IsGuid then
            exit(FindMappingForIntegrationTable(TableNo));
    end;

    [Obsolete('Use FindMapping', '18.0')]
    local procedure FindMappingForIntegrationTable(TableId: Integer): Boolean
    begin
        SetRange("Integration Table ID", TableId);
        SetRange("Delete After Synchronization", false);
        exit(FindFirst());
    end;
#endif

    procedure FindMappingForTable(TableId: Integer): Boolean
    begin
        SetRange("Table ID", TableId);
        SetRange("Delete After Synchronization", false);
        exit(FindFirst());
    end;

    procedure IsFullSynch(): Boolean
    begin
        exit("Full Sync is Running" and "Delete After Synchronization");
    end;

    procedure GetName() Result: Code[20]
    begin
        if "Delete After Synchronization" then
            Result := "Parent Name";
        if Result = '' then
            Result := Name;
    end;

    procedure GetDirection(): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get(GetName);
        exit(IntegrationTableMapping.Direction);
    end;

    procedure GetJobLogEntryNo(): Integer
    begin
        exit(JobLogEntryNo)
    end;

    procedure GetTempDescription(): Text
    var
        Separator: Text;
    begin
        case Direction of
            Direction::Bidirectional:
                Separator := '<->';
            Direction::ToIntegrationTable:
                Separator := '->';
            Direction::FromIntegrationTable:
                Separator := '<-';
        end;
        exit(
          StrSubstNo(
            '%1 %2 %3', GetTableCaption("Table ID"), Separator, GetTableCaption("Integration Table ID")));
    end;

    procedure GetExtendedIntegrationTableCaption(): Text
    var
        TableCaption: Text;
    begin
        TableCaption := GetTableExternalName("Integration Table ID");
        if TableCaption <> '' then
            if "Int. Tbl. Caption Prefix" <> '' then
                exit(StrSubstNo('%1 %2', "Int. Tbl. Caption Prefix", TableCaption));
        exit(TableCaption);
    end;

    local procedure GetTableCaption(ID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(ID) then
            exit(TableMetadata.Caption);
        exit('');
    end;

    local procedure GetTableExternalName(ID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(ID) then
            exit(TableMetadata.ExternalName);
        exit('');
    end;

    procedure SetTableFilter("Filter": Text)
    var
        OutStream: OutStream;
    begin
        "Table Filter".CreateOutStream(OutStream);
        OutStream.Write(Filter);
    end;

    procedure GetTableFilter() Value: Text
    var
        InStream: InStream;
    begin
        CalcFields("Table Filter");
        "Table Filter".CreateInStream(InStream);
        InStream.Read(Value);
    end;

    procedure SetIntegrationTableFilter(IntTableFilter: Text)
    var
        OutStream: OutStream;
    begin
        "Integration Table Filter".CreateOutStream(OutStream);
        OutStream.Write(IntTableFilter);
    end;

    [Scope('OnPrem')]
    procedure SuggestToIncludeEntitiesWithNullCompany(var IntTableFilter: Text);
    var
        Field: Record "Field";
        CRMProductName: Codeunit "CRM Product Name";
        CompanyIdFieldNo: Integer;
        CompanyIdFilterStartPos: Integer;
        CompanyIdFilter: Text;
        ModifiedCompanyIdFilter: Text;
        OrNullGuid: Text;
    begin
        OrNullGuid := '|{00000000-0000-0000-0000-000000000000}';
        Field.SetRange(TableNo, "Integration Table ID");
        Field.SetRange(Type, Field.Type::GUID);
        Field.SetRange(FieldName, CompanyIdFieldNameTxt);
        if not Field.FindFirst() then
            exit;
        CompanyIdFieldNo := Field."No.";

        CompanyIdFilterStartPos := IntTableFilter.IndexOf('Field' + Format(CompanyIdFieldNo) + '=1');
        if CompanyIdFilterStartPos <= 0 then
            exit;

        CompanyIdFilter := CopyStr(IntTableFilter, CompanyIdFilterStartPos);
        CompanyIdFilter := CopyStr(CompanyIdFilter, 1, CompanyIdFilter.IndexOf(')'));

        if (CompanyIdFilter = '') or (CompanyIdFilter.IndexOf(OrNullGuid) > 0) then
            exit;

        if not Confirm(StrSubstNo(ConfirmIncludeEntitiesWithNoCompanyQst, CRMProductName.CDSServiceName(), Field."Field Caption")) then begin
            Session.LogMessage('0000EG4', StrSubstNo(UserChoseNotToIncludeEntitiesWithEmptyCompanyNameTxt, CRMProductName.CDSServiceName(), Name), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit;
        end;

        ModifiedCompanyIdFilter := CompanyIdFilter.Replace(')', OrNullGuid + ')');
        IntTableFilter := IntTableFilter.Replace(CompanyIdFilter, ModifiedCompanyIdFilter);
    end;

    procedure GetIntegrationTableFilter() Value: Text
    var
        InStream: InStream;
    begin
        CalcFields("Integration Table Filter");
        "Integration Table Filter".CreateInStream(InStream);
        InStream.Read(Value);
    end;

    procedure SetIntTableModifiedOn(ModifiedOn: DateTime)
    begin
        if (ModifiedOn <> 0DT) and (ModifiedOn > "Synch. Int. Tbl. Mod. On Fltr.") then begin
            "Synch. Int. Tbl. Mod. On Fltr." := ModifiedOn;
            Modify(true);
        end;
    end;

    procedure SetTableModifiedOn(ModifiedOn: DateTime)
    begin
        if (ModifiedOn <> 0DT) and (ModifiedOn > "Synch. Modified On Filter") then begin
            "Synch. Modified On Filter" := ModifiedOn;
            Modify(true);
        end;
    end;

    procedure SetJobLogEntryNo(NewJobLogEntryNo: Integer)
    begin
        JobLogEntryNo := NewJobLogEntryNo;
    end;

    procedure ShowLog(JobIDFilter: Text)
    begin
        ShowLog('', JobIDFilter, '');
    end;

    internal procedure ShowSynchronizationLog(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        TempIntegrationSynchJob: Record "Integration Synch. Job" temporary;
        NameFilter: Text;
    begin
        NameFilter := GetNameFilter(IntegrationTableMapping);
        TempIntegrationSynchJob.SetRange(Type, TempIntegrationSynchJob.Type::Synchronization);
        ShowLog(NameFilter, '', TempIntegrationSynchJob.GetFilter(Type));
    end;

    internal procedure ShowUncouplingLog(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        TempIntegrationSynchJob: Record "Integration Synch. Job" temporary;
        NameFilter: Text;
    begin
        NameFilter := GetNameFilter(IntegrationTableMapping);
        TempIntegrationSynchJob.SetRange(Type, TempIntegrationSynchJob.Type::Uncoupling);
        ShowLog(NameFilter, '', TempIntegrationSynchJob.GetFilter(Type));
    end;

    local procedure ShowLog(NameFilter: Text; JobIDFilter: Text; JobTypeFilter: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if (NameFilter = '') and (Name = '') then
            exit;

        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.Ascending := false;
        IntegrationSynchJob.FilterGroup(2);
        if NameFilter <> '' then
            IntegrationSynchJob.SetFilter("Integration Table Mapping Name", NameFilter)
        else
            IntegrationSynchJob.SetRange("Integration Table Mapping Name", Name);
        IntegrationSynchJob.FilterGroup(0);
        if JobIDFilter <> '' then
            IntegrationSynchJob.SetFilter(ID, JobIDFilter);
        if JobTypeFilter <> '' then
            IntegrationSynchJob.SetFilter(Type, JobTypeFilter);
        if IntegrationSynchJob.FindFirst then;
        Page.Run(Page::"Integration Synch. Job List", IntegrationSynchJob);
    end;

    local procedure GetNameFilter(var IntegrationTableMapping: Record "Integration Table Mapping"): Text
    var
        NameFilter: Text;
    begin
        if IntegrationTableMapping.FindSet() then
            repeat
                if Name <> '' then begin
                    if NameFilter <> '' then
                        NameFilter += '|';
                    NameFilter += IntegrationTableMapping.Name;
                end;
            until IntegrationTableMapping.Next() = 0;
        exit(NameFilter);
    end;

    procedure SynchronizeNow(ResetLastSynchModifiedOnDateTime: Boolean)
    begin
        SynchronizeNow(ResetLastSynchModifiedOnDateTime, false);
    end;

    [Scope('OnPrem')]
    procedure SynchronizeNow(ResetLastSynchModifiedOnDateTime: Boolean; ResetSynchonizationTimestampOnRecords: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
        if ResetLastSynchModifiedOnDateTime then begin
            Clear("Synch. Modified On Filter");
            Clear("Synch. Int. Tbl. Mod. On Fltr.");
            Modify;
        end;
        if ResetSynchonizationTimestampOnRecords then begin
            CRMIntegrationManagement.RepairBrokenCouplings(true);
            CRMIntegrationRecord.SetRange("Table ID", "Table ID");
            case Direction of
                Direction::ToIntegrationTable:
                    CRMIntegrationRecord.ModifyAll("Last Synch. Modified On", 0DT);
                Direction::FromIntegrationTable:
                    CRMIntegrationRecord.ModifyAll("Last Synch. CRM Modified On", 0DT);
            end
        end;
        Commit();
        CRMSetupDefaults.CreateJobQueueEntry(Rec);
    end;

    procedure GetRecordRef(ID: Variant; var IntegrationRecordRef: RecordRef): Boolean
    var
        IDFieldRef: FieldRef;
        RecordID: RecordID;
        TextKey: Text;
    begin
        IntegrationRecordRef.Close;
        if ID.IsGuid then begin
            IntegrationRecordRef.Open("Integration Table ID");
            IDFieldRef := IntegrationRecordRef.Field("Integration Table UID Fld. No.");
            IDFieldRef.SetFilter(ID);
            exit(IntegrationRecordRef.FindFirst);
        end;

        if ID.IsRecordId then begin
            RecordID := ID;
            if RecordID.TableNo = "Table ID" then
                exit(IntegrationRecordRef.Get(ID));
        end;

        if ID.IsText then begin
            IntegrationRecordRef.Open("Integration Table ID");
            IDFieldRef := IntegrationRecordRef.Field("Integration Table UID Fld. No.");
            TextKey := ID;
            IDFieldRef.SetFilter('%1', TextKey);
            exit(IntegrationRecordRef.FindFirst);
        end;
    end;

    procedure SetIntRecordRefFilter(var IntRecordRef: RecordRef)
    var
        ModifiedOnFieldRef: FieldRef;
        TableFilter: Text;
    begin
        TableFilter := GetIntegrationTableFilter;
        if TableFilter <> '' then
            IntRecordRef.SetView(TableFilter);

        if "Synch. Modified On Filter" <> 0DT then begin
            ModifiedOnFieldRef := IntRecordRef.Field("Int. Tbl. Modified On Fld. No.");
            ModifiedOnFieldRef.SetFilter('>%1', "Synch. Modified On Filter" - 999);
        end;
    end;

    procedure SetRecordRefFilter(var RecordRef: RecordRef)
    var
        TableFilter: Text;
    begin
        TableFilter := GetTableFilter;
        if TableFilter <> '' then
            RecordRef.SetView(TableFilter);
    end;

    procedure CopyModifiedOnFilters(FromIntegrationTableMapping: Record "Integration Table Mapping")
    begin
        "Synch. Modified On Filter" := FromIntegrationTableMapping."Synch. Modified On Filter";
        "Synch. Int. Tbl. Mod. On Fltr." := FromIntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.";
        Modify;
    end;

    [Obsolete('Use another implementation of CreateRecord', '17.0')]
    procedure CreateRecord(MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean; DirectionArg: Option; Prefix: Text[30])
    begin
        CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo, IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode, SynchOnlyCoupledRecords, DirectionArg, Prefix, Codeunit::"CRM Integration Table Synch.", Codeunit::"CDS Int. Table Uncouple");
    end;

    [Scope('OnPrem')]
    procedure CreateRecord(MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean; DirectionArg: Option; Prefix: Text[30]; SynchCodeunitId: Integer; UncoupleCodeunitId: Integer)
    begin
        if Get(MappingName) then
            Delete(true);
        Init;
        Name := MappingName;
        "Table ID" := TableNo;
        "Integration Table ID" := IntegrationTableNo;
        "Synch. Codeunit ID" := SynchCodeunitId;
        "Uncouple Codeunit ID" := UncoupleCodeunitId;
        Validate("Integration Table UID Fld. No.", IntegrationTableUIDFieldNo);
        "Int. Tbl. Modified On Fld. No." := IntegrationTableModifiedFieldNo;
        "Table Config Template Code" := TableConfigTemplateCode;
        "Int. Tbl. Config Template Code" := IntegrationTableConfigTemplateCode;
        Direction := DirectionArg;
        "Int. Tbl. Caption Prefix" := Prefix;
        "Synch. Only Coupled Records" := SynchOnlyCoupledRecords;
        Insert(true);
    end;

    procedure SetFullSyncStartAndCommit()
    begin
        Validate("Full Sync is Running", true);
        Modify;
        Commit();
        Get(Name);
    end;

    procedure SetFullSyncEndAndCommit()
    begin
        Validate("Full Sync is Running", false);
        Modify;
        Commit();
        Get(Name);
    end;

    procedure IsFullSyncAllowed(): Boolean
    begin
        Get(Name);
        if not "Full Sync is Running" then
            exit(true);

        if not IsSessionActive("Full Sync Session ID") then begin
            SetFullSyncEndAndCommit();
            exit(true);
        end;
        if Abs(CurrentDateTime - "Last Full Sync Start DateTime") >= OneDayInMiliseconds then
            exit(true);
        exit(false)
    end;

    local procedure OneDayInMiliseconds(): Integer
    begin
        exit(24 * 60 * 60 * 1000)
    end;
}

