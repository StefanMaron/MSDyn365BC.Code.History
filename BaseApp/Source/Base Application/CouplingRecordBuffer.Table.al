table 5332 "Coupling Record Buffer"
{
    Caption = 'Coupling Record Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "NAV Name"; Text[250])
        {
            Caption = 'NAV Name';
            DataClassification = SystemMetadata;
        }
        field(2; "CRM Name"; Text[250])
        {
            Caption = 'CRM Name';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                LookUpCRMName;
            end;

            trigger OnValidate()
            var
                CRMIntegrationRecord: Record "CRM Integration Record";
            begin
                if FindCRMRecordByName("CRM Name") then begin
                    if "Saved CRM ID" <> "CRM ID" then
                        CRMIntegrationRecord.AssertRecordIDCanBeCoupled("NAV Record ID", "CRM ID");
                    CalcCRMName;
                end else
                    Error(NoSuchCRMRecordErr, "CRM Name", CRMProductName.SHORT);
            end;
        }
        field(3; "NAV Table ID"; Integer)
        {
            Caption = 'NAV Table ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                IntegrationTableMapping: Record "Integration Table Mapping";
            begin
                IntegrationTableMapping.SetRange("Table ID", "NAV Table ID");
                IntegrationTableMapping.SetRange("Delete After Synchronization", false);
                if IntegrationTableMapping.FindFirst then
                    "CRM Table Name" := IntegrationTableMapping.Name
                else
                    "CRM Table Name" := '';
            end;
        }
        field(4; "CRM Table ID"; Integer)
        {
            Caption = 'CRM Table ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Sync Action"; Option)
        {
            Caption = 'Sync Action';
            DataClassification = SystemMetadata;
            OptionCaption = 'Do Not Synchronize,To Integration Table,From Integration Table';
            OptionMembers = "Do Not Synchronize","To Integration Table","From Integration Table";
        }
        field(8; "NAV Record ID"; RecordID)
        {
            Caption = 'NAV Record ID';
            DataClassification = SystemMetadata;
        }
        field(9; "CRM ID"; Guid)
        {
            Caption = 'CRM ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                CalcCRMName;
            end;
        }
        field(10; "Create New"; Boolean)
        {
            Caption = 'Create New';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                NullGUID: Guid;
            begin
                if "Create New" then begin
                    "Saved Sync Action" := "Sync Action";
                    "Saved CRM ID" := "CRM ID";
                    Validate("Sync Action", "Sync Action"::"To Integration Table");
                    Clear(NullGUID);
                    Validate("CRM ID", NullGUID);
                end else begin
                    Validate("Sync Action", "Saved Sync Action");
                    Validate("CRM ID", "Saved CRM ID");
                end;
            end;
        }
        field(11; "Saved Sync Action"; Option)
        {
            Caption = 'Saved Sync Action';
            DataClassification = SystemMetadata;
            OptionCaption = 'Do Not Synchronize,To Integration Table,From Integration Table';
            OptionMembers = "Do Not Synchronize","To Integration Table","From Integration Table";
        }
        field(12; "Saved CRM ID"; Guid)
        {
            Caption = 'Saved CRM ID';
            DataClassification = SystemMetadata;
        }
        field(13; "CRM Table Name"; Code[20])
        {
            Caption = 'CRM Table Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "NAV Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        InitialSynchDisabledErr: Label 'No initial synchronization direction was specified because initial synchronization was disabled.';
        NoSuchCRMRecordErr: Label 'A record with the name %1 does not exist in %2.', Comment = '%1 = The record name entered by the user, %2 = CRM product name';
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMProductName: Codeunit "CRM Product Name";

    procedure Initialize(NAVRecordID: RecordID)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordRef: RecordRef;
    begin
        RecordRef := NAVRecordID.GetRecord;
        RecordRef.Find;

        Init;
        Validate("NAV Table ID", NAVRecordID.TableNo);
        "NAV Record ID" := NAVRecordID;
        "NAV Name" := NameValue(RecordRef);
        "CRM Table ID" := CRMSetupDefaults.GetCRMTableNo("NAV Table ID");
        if CRMSetupDefaults.GetDefaultDirection("NAV Table ID") = IntegrationTableMapping.Direction::FromIntegrationTable then
            Validate("Sync Action", "Sync Action"::"From Integration Table")
        else
            Validate("Sync Action", "Sync Action"::"To Integration Table");
        if FindCRMId then
            if CalcCRMName then begin
                Validate("Sync Action", "Sync Action"::"Do Not Synchronize");
                "Saved CRM ID" := "CRM ID";
            end;
    end;

    local procedure FindCRMId(): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(CRMIntegrationRecord.FindIDFromRecordID("NAV Record ID", "CRM ID"))
    end;

    local procedure FindCRMRecordByName(var CRMName: Text[250]): Boolean
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        Found: Boolean;
    begin
        RecordRef.Open("CRM Table ID");
        FieldRef := RecordRef.Field(CRMSetupDefaults.GetNameFieldNo("CRM Table ID"));
        FieldRef.SetRange(CRMName);
        if RecordRef.FindFirst then
            Found := true
        else begin
            RecordRef.CurrentKeyIndex(2); // "Name" key should be the second key in a CRM table
            FieldRef := RecordRef.Field(CRMSetupDefaults.GetNameFieldNo("CRM Table ID"));
            FieldRef.SetFilter("CRM Name" + '*');
            if RecordRef.FindFirst then
                Found := true;
        end;
        if Found then begin
            CRMName := NameValue(RecordRef);
            "CRM ID" := PrimaryKeyValue(RecordRef);
        end;
        RecordRef.Close;
        exit(Found);
    end;

    procedure LookUpCRMName()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if LookupCRMTables.Lookup("CRM Table ID", "NAV Table ID", "Saved CRM ID", "CRM ID") then begin
            if "Saved CRM ID" <> "CRM ID" then
                CRMIntegrationRecord.AssertRecordIDCanBeCoupled("NAV Record ID", "CRM ID");
            CalcCRMName;
        end;
    end;

    local procedure CalcCRMName() Found: Boolean
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open("CRM Table ID");
        Found := FindCRMRecRefByPK(RecordRef, "CRM ID");
        if Found then
            "CRM Name" := NameValue(RecordRef)
        else
            "CRM Name" := '';
        RecordRef.Close;
    end;

    procedure GetInitialSynchronizationDirection(): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if "Sync Action" = "Sync Action"::"Do Not Synchronize" then
            Error(InitialSynchDisabledErr);

        if "Sync Action" = "Sync Action"::"To Integration Table" then
            exit(IntegrationTableMapping.Direction::ToIntegrationTable);

        exit(IntegrationTableMapping.Direction::FromIntegrationTable);
    end;

    procedure GetPerformInitialSynchronization(): Boolean
    begin
        exit("Sync Action" <> "Sync Action"::"Do Not Synchronize");
    end;

    local procedure NameValue(RecordRef: RecordRef): Text[250]
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(CRMSetupDefaults.GetNameFieldNo(RecordRef.Number));
        exit(CopyStr(Format(FieldRef.Value), 1, MaxStrLen("CRM Name")));
    end;

    local procedure PrimaryKeyValue(RecordRef: RecordRef): Guid
    var
        FieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        FieldRef := PrimaryKeyRef.FieldIndex(1);
        exit(FieldRef.Value);
    end;

    local procedure FindCRMRecRefByPK(var RecordRef: RecordRef; CRMId: Guid): Boolean
    var
        FieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        FieldRef := PrimaryKeyRef.FieldIndex(1);
        FieldRef.SetRange(CRMId);
        exit(RecordRef.FindFirst);
    end;
}

