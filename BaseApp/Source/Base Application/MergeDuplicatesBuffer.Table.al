table 64 "Merge Duplicates Buffer"
{
    Caption = 'Merge Duplicates Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                CalcTableName;
            end;
        }
        field(2; Duplicate; Code[20])
        {
            Caption = 'Duplicate';
            DataClassification = SystemMetadata;
            TableRelation = IF ("Table ID" = CONST(18)) Customer
            ELSE
            IF ("Table ID" = CONST(23)) Vendor
            ELSE
            IF ("Table ID" = CONST(5050)) Contact;

            trigger OnValidate()
            begin
                TestField(Duplicate);
                if Current = Duplicate then
                    FieldError(Duplicate);
                CollectData;
            end;
        }
        field(3; Current; Code[20])
        {
            Caption = 'Current';
            DataClassification = SystemMetadata;
            TableRelation = IF ("Table ID" = CONST(18)) Customer;
        }
        field(4; "Table Name"; Text[30])
        {
            Caption = 'Table Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5; Conflicts; Integer)
        {
            Caption = 'Conflicts';
            DataClassification = SystemMetadata;
        }
        field(6; "Duplicate Record ID"; RecordID)
        {
            Caption = 'Duplicate Record ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                CollectData;
            end;
        }
        field(7; "Current Record ID"; RecordID)
        {
            Caption = 'Current Record ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                RecID: RecordID;
            begin
                RecID := "Current Record ID";
                Validate("Table ID", RecID.TableNo);
            end;
        }
        field(8; "Conflict Field ID"; Integer)
        {
            Caption = 'Conflict Field ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RenameErr: Label '%1 has not been renamed to %3.', Comment = '%1 - Customer/Vendor, %2 - old No., %3 - new No.';
        RecNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 - table name; %2 - primary key value';
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        ConflictsErr: Label 'Resolve (%1) conflicts before merge.', Comment = '%1 - number of conflicts';
        ConfirmMergeTxt: Label 'Are you sure you want to merge the two records? This step cannot be undone.';
        ConfirmRenameTxt: Label 'Are you sure you want to rename record %1?', Comment = '%1 - values of the primary key fields';
        ConfirmRemoveTxt: Label 'Are you sure you want to remove record %1?', Comment = '%1 - values of the primary key fields';
        CurrRecordErr: Label 'The current record is not set.';
        ModifyPKeyFieldErr: Label 'You must modify one of the primary key fields.';
        RestorePKeyFieldErr: Label 'You must restore the modified primary key field.';

    local procedure CalcTableName()
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open("Table ID");
        "Table Name" := CopyStr(RecordRef.Caption, 1, MaxStrLen("Table Name"));
        RecordRef.Close;
    end;

    local procedure ClearData()
    begin
        TempMergeDuplicatesLineBuffer.Reset();
        TempMergeDuplicatesLineBuffer.DeleteAll();
        TempMergeDuplicatesConflict.Reset();
        TempMergeDuplicatesConflict.DeleteAll();
        Conflicts := 0;
    end;

    local procedure CollectData()
    begin
        ClearData;
        CollectFieldData;
        if not IsConflict then
            CollectRelatedTables;
    end;

    local procedure CollectFieldData()
    var
        TempPKInt: Record "Integer" temporary;
        RecordRef: array[2] of RecordRef;
        Index: Integer;
        FoundDuplicateRecord: Boolean;
    begin
        FindRecords(RecordRef, FoundDuplicateRecord);
        TempMergeDuplicatesLineBuffer.GetPrimaryKeyFields(RecordRef[1], TempPKInt);
        for Index := 1 to RecordRef[1].FieldCount do
            TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, "Conflict Field ID", Index, FoundDuplicateRecord, TempPKInt);
        RecordRef[1].Close;
        if FoundDuplicateRecord then
            RecordRef[2].Close;
    end;

    local procedure CollectRelatedTables()
    var
        TempTableRelationsMetadata: Record "Table Relations Metadata" temporary;
    begin
        if FindRelatedFields(TempTableRelationsMetadata) then
            repeat
                TempMergeDuplicatesLineBuffer.AddTableData(
                  Rec, TempTableRelationsMetadata."Table ID", TempTableRelationsMetadata."Field No.");
            until TempTableRelationsMetadata.Next = 0;
    end;

    local procedure FindConflicts(): Boolean
    var
        xConflicts: Integer;
    begin
        TempMergeDuplicatesLineBuffer.Reset();
        TempMergeDuplicatesLineBuffer.SetRange("In Primary Key", TempMergeDuplicatesLineBuffer."In Primary Key"::Yes);
        TempMergeDuplicatesLineBuffer.SetFilter("Duplicate Count", '>0');
        if TempMergeDuplicatesLineBuffer.FindSet then
            repeat
                xConflicts := TempMergeDuplicatesLineBuffer.Conflicts;
                if TempMergeDuplicatesLineBuffer.FindConflicts(Duplicate, Current, TempMergeDuplicatesConflict) <> xConflicts then
                    TempMergeDuplicatesLineBuffer.Modify();
            until TempMergeDuplicatesLineBuffer.Next = 0;
        Conflicts := TempMergeDuplicatesConflict.Count();
        Modify;
        TempMergeDuplicatesLineBuffer.Reset();
        exit(Conflicts > 0);
    end;

    local procedure FindRecord(PKey: Code[20]; var RecordRef: RecordRef): Boolean
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        RecordRef.Open("Table ID");
        KeyRef := RecordRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetRange(PKey);
        exit(RecordRef.FindFirst);
    end;

    local procedure FindRecords(var RecordRef: array[2] of RecordRef; var FoundDuplicateRecord: Boolean)
    begin
        if (Current = '') and (Format("Current Record ID") = '') then
            Error(CurrRecordErr);
        if Current <> '' then begin
            if not FindRecord(Current, RecordRef[1]) then
                Error(RecNotExistErr, "Table Name", Current);
            FoundDuplicateRecord := FindRecord(Duplicate, RecordRef[2]);
        end else begin
            RecordRef[1].Open("Table ID");
            if not RecordRef[1].Get("Current Record ID") then
                Error(RecNotExistErr, '', "Current Record ID");
            RecordRef[2].Open("Table ID");
            FoundDuplicateRecord := RecordRef[2].Get("Duplicate Record ID");
        end;
    end;

    local procedure FindRelatedFields(var TempTableRelationsMetadata: Record "Table Relations Metadata" temporary): Boolean
    var
        "Field": Record "Field";
        TableRelationsMetadata: Record "Table Relations Metadata";
        TableMetadata: Record "Table Metadata";
    begin
        TempTableRelationsMetadata.Reset();
        TempTableRelationsMetadata.DeleteAll();
        TableRelationsMetadata.SetRange("Related Table ID", "Table ID");
        TableRelationsMetadata.SetRange("Related Field No.", GetKeyFieldNo("Table ID"));
        if TableRelationsMetadata.FindSet then
            repeat
                if TableMetadata.Get(TableRelationsMetadata."Table ID") and
                   (TableMetadata.ObsoleteState <> TableMetadata.ObsoleteState::Removed)
                then begin
                    Field.Get(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.");
                    if (Field.Class = Field.Class::Normal) and (Field.ObsoleteState <> Field.ObsoleteState::Removed) then
                        if (TempTableRelationsMetadata."Table ID" <> TableRelationsMetadata."Table ID") or
                        (TempTableRelationsMetadata."Field No." <> TableRelationsMetadata."Field No.")
                        then begin
                            TempTableRelationsMetadata := TableRelationsMetadata;
                            TempTableRelationsMetadata.Insert();
                        end;
                end;
            until TableRelationsMetadata.Next = 0;
        IncludeDefaultDimTable(TempTableRelationsMetadata);
        OnAfterFindRelatedFields(TempTableRelationsMetadata);
        exit(TempTableRelationsMetadata.FindSet);
    end;

    [Scope('OnPrem')]
    procedure GetConflictsMsg(): Text
    begin
        if Conflicts = 0 then
            exit('');
        exit(StrSubstNo(ConflictsErr, Conflicts));
    end;

    local procedure GetKeyFieldNo(TableNo: Integer) FieldNo: Integer
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
        FieldNo := FieldRef.Number;
        RecRef.Close;
    end;

    local procedure GetKeyValues(RecordRef: RecordRef; var KeyValue: array[16] of Variant) Index: Integer
    var
        KeyRef: KeyRef;
        FieldRef: FieldRef;
    begin
        KeyRef := RecordRef.KeyIndex(1);
        for Index := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(Index);
            KeyValue[Index] := FieldRef.Value;
        end;
    end;

    procedure GetLines(var TempMergeDuplicatesLineBuf: Record "Merge Duplicates Line Buffer" temporary; var TempMergeDuplicatesConflictBuf: Record "Merge Duplicates Conflict" temporary)
    begin
        TempMergeDuplicatesLineBuf.Copy(TempMergeDuplicatesLineBuffer, true);
        TempMergeDuplicatesConflictBuf.Copy(TempMergeDuplicatesConflict, true);
    end;

    local procedure IncludeDefaultDimTable(var TempTableRelationsMetadata: Record "Table Relations Metadata" temporary)
    var
        DefaultDimension: Record "Default Dimension";
        TempAllObjWithCaption: Record AllObjWithCaption temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.DefaultDimObjectNoList(TempAllObjWithCaption);
        if TempAllObjWithCaption.Get(TempAllObjWithCaption."Object Type"::Table, "Table ID") then begin
            TempTableRelationsMetadata.Init();
            TempTableRelationsMetadata."Table ID" := DATABASE::"Default Dimension";
            TempTableRelationsMetadata."Field No." := DefaultDimension.FieldNo("No.");
            TempTableRelationsMetadata.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertFromConflict(MergeDuplicatesConflict: Record "Merge Duplicates Conflict")
    begin
        Init;
        "Conflict Field ID" := MergeDuplicatesConflict."Field ID";
        Validate("Current Record ID", MergeDuplicatesConflict.Current);
        Validate("Duplicate Record ID", MergeDuplicatesConflict.Duplicate);
        Insert;
    end;

    [Scope('OnPrem')]
    procedure IsConflict(): Boolean
    begin
        exit("Conflict Field ID" <> 0);
    end;

    [Scope('OnPrem')]
    procedure FindModifiedKeyFields(): Boolean
    begin
        if IsConflict then
            exit(TempMergeDuplicatesLineBuffer.HasModifiedField);
    end;

    procedure Show(TableID: Integer; CurrentKey: Code[20])
    var
        MergeDuplicate: Page "Merge Duplicate";
    begin
        Validate("Table ID", TableID);
        Current := CurrentKey;
        MergeDuplicate.Set(Rec);
        MergeDuplicate.Run;
    end;

    procedure ShowConflicts()
    var
        MergeDuplicateConflicts: Page "Merge Duplicate Conflicts";
    begin
        MergeDuplicateConflicts.Set(TempMergeDuplicatesConflict);
        MergeDuplicateConflicts.RunModal;
        FindConflicts;
    end;

    [Scope('OnPrem')]
    procedure Merge(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if FindConflicts then
            exit(false);
        if not ConfirmManagement.GetResponseOrDefault(ConfirmMergeTxt, true) then
            exit(false);
        case "Table ID" of
            DATABASE::Contact:
                MergeContacts;
            DATABASE::Customer:
                MergeCustomers;
            DATABASE::Vendor:
                MergeVendors;
        end;
        exit(true);
    end;

    local procedure MergeContacts()
    var
        Contact: array[2] of Record Contact;
    begin
        Contact[2].Get(Current);
        Contact[1].Get(Duplicate);
        MergeRecords(Contact[1].RecordId, Contact[2].RecordId, 0);
    end;

    local procedure MergeCustomers()
    var
        Customer: array[2] of Record Customer;
    begin
        Customer[1].Get(Duplicate);
        Customer[2].Get(Current);
        MergeRecords(Customer[1].RecordId, Customer[2].RecordId, Customer[1].FieldNo(Id));
    end;

    local procedure MergeVendors()
    var
        Vendor: array[2] of Record Vendor;
    begin
        Vendor[2].Get(Current);
        Vendor[1].Get(Duplicate);
        MergeRecords(Vendor[1].RecordId, Vendor[2].RecordId, Vendor[1].FieldNo(Id));
    end;

    local procedure MergeRecords(DuplicateRecID: RecordID; CurrentRecID: RecordID; IdFieldId: Integer)
    var
        IntegrationRecord: array[2] of Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        RecordRef: array[2] of RecordRef;
        KeyValue: array[16] of Variant;
        KeyFieldCount: Integer;
    begin
        RecordRef[2].Get(CurrentRecID);
        RecordRef[1].Get(DuplicateRecID);
        if IntegrationManagement.IsIntegrationActivated then begin
            IntegrationRecord[2].FindByRecordId(RecordRef[2].RecordId);
            if IntegrationRecord[1].FindByRecordId(RecordRef[1].RecordId) then
                IntegrationRecord[1].Delete();
        end;

        OverrideSelectedFields(RecordRef[2], RecordRef[1], false);

        RecordRef[2].Delete();
        RestoreIntegrationRecordDeletion(IntegrationRecord[2]."Integration ID", RecordRef[2].RecordId, IntegrationRecord[2]);
        KeyFieldCount := GetKeyValues(RecordRef[2], KeyValue);
        if not RenameRecord(RecordRef[1], KeyFieldCount, KeyValue) then
            Error(RenameErr, RecordRef[1].RecordId, RecordRef[2].RecordId);
        if IntegrationManagement.IsIntegrationActivated then begin
            UpdateIDs(
              RecordRef[1].Number, IdFieldId, IntegrationRecord[1]."Integration ID", IntegrationRecord[2]."Integration ID");
            IntegrationRecord[1]."Deleted On" := CurrentDateTime;
            IntegrationRecord[1].Insert(true);
        end;
    end;

    local procedure OverrideSelectedFields(FromRecRef: RecordRef; var ToRecRef: RecordRef; PickedFieldsOnly: Boolean): Boolean
    var
        FieldRef: array[2] of FieldRef;
    begin
        TempMergeDuplicatesLineBuffer.Reset();
        TempMergeDuplicatesLineBuffer.SetRange(Type, TempMergeDuplicatesLineBuffer.Type::Field);
        if PickedFieldsOnly then
            TempMergeDuplicatesLineBuffer.SetRange(Override, true)
        else begin
            TempMergeDuplicatesLineBuffer.SetRange("In Primary Key", TempMergeDuplicatesLineBuffer."In Primary Key"::No);
            TempMergeDuplicatesLineBuffer.SetRange(Override, false);
        end;
        if TempMergeDuplicatesLineBuffer.FindSet then begin
            repeat
                FieldRef[1] := FromRecRef.Field(TempMergeDuplicatesLineBuffer.ID);
                FieldRef[2] := ToRecRef.Field(TempMergeDuplicatesLineBuffer.ID);
                FieldRef[2].Value(FieldRef[1].Value);
            until TempMergeDuplicatesLineBuffer.Next = 0;
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure RemoveConflictingRecord() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        RecordRef: array[2] of RecordRef;
    begin
        if FindModifiedKeyFields then
            Error(RestorePKeyFieldErr);

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmRemoveTxt, "Duplicate Record ID"), true) then
            exit(false);

        RecordRef[1].Get("Current Record ID");
        RecordRef[2].Get("Duplicate Record ID");
        if OverrideSelectedFields(RecordRef[2], RecordRef[1], true) then
            RecordRef[1].Modify();
        RecordRef[1].Close;
        Result := RecordRef[2].Delete(true);
        RecordRef[2].Close;
    end;

    [Scope('OnPrem')]
    procedure RenameConflictingRecord(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        RecordRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        KeyValue: Variant;
        VariantKeyValue: array[16] of Variant;
        Index: Integer;
    begin
        if not FindModifiedKeyFields then
            Error(ModifyPKeyFieldErr);

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmRenameTxt, "Duplicate Record ID"), true) then
            exit(false);

        RecordRef.Get("Duplicate Record ID");
        KeyRef := RecordRef.KeyIndex(1);
        for Index := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(Index);
            KeyValue := FieldRef.Value;
            if FieldRef.Type in [FieldType::Text, FieldType::Code] then begin
                TempMergeDuplicatesLineBuffer.Get(TempMergeDuplicatesLineBuffer.Type::Field, "Table ID", FieldRef.Number);
                if Format(FieldRef.Value) <> TempMergeDuplicatesLineBuffer."Duplicate Value" then
                    KeyValue := TempMergeDuplicatesLineBuffer."Duplicate Value";
            end;
            VariantKeyValue[Index] := KeyValue;
        end;

        if RenameRecord(RecordRef, Index, VariantKeyValue) then
            exit(true);
    end;

    local procedure RenameRecord(var RecordRef: RecordRef; Index: Integer; KeyValue: array[16] of Variant): Boolean
    begin
        case Index of
            1:
                exit(RecordRef.Rename(KeyValue[1]));
            2:
                exit(RecordRef.Rename(KeyValue[1], KeyValue[2]));
            3:
                exit(RecordRef.Rename(KeyValue[1], KeyValue[2], KeyValue[3]));
            4:
                exit(RecordRef.Rename(KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4]));
            5:
                exit(RecordRef.Rename(KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5]));
            6:
                exit(RecordRef.Rename(KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6]));
            7:
                exit(RecordRef.Rename(KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7]));
            8:
                exit(RecordRef.Rename(KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8]));
            9:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9]));
            10:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9],
                    KeyValue[10]));
            11:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9],
                    KeyValue[10], KeyValue[11]));
            12:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9],
                    KeyValue[10], KeyValue[11], KeyValue[12]));
            13:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9],
                    KeyValue[10], KeyValue[11], KeyValue[12], KeyValue[13]));
            14:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9],
                    KeyValue[10], KeyValue[11], KeyValue[12], KeyValue[13], KeyValue[14]));
            15:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9],
                    KeyValue[10], KeyValue[11], KeyValue[12], KeyValue[13], KeyValue[14], KeyValue[15]));
            16:
                exit(
                  RecordRef.Rename(
                    KeyValue[1], KeyValue[2], KeyValue[3], KeyValue[4], KeyValue[5], KeyValue[6], KeyValue[7], KeyValue[8], KeyValue[9],
                    KeyValue[10], KeyValue[11], KeyValue[12], KeyValue[13], KeyValue[14], KeyValue[15], KeyValue[16]));
        end;
    end;

    local procedure RestoreIntegrationRecordDeletion(IntegrationID: Guid; RecID: RecordID; var IntegrationRecord: Record "Integration Record")
    var
        IntegrationManagement: Codeunit "Integration Management";
    begin
        if not IntegrationManagement.IsIntegrationActivated then
            exit;

        IntegrationRecord.FindByIntegrationId(IntegrationID);
        IntegrationRecord."Record ID" := RecID;
        Clear(IntegrationRecord."Deleted On");
        IntegrationRecord.Modify(true);
    end;

    local procedure UpdateIDs(TableNo: Integer; IdFieldNo: Integer; OldID: Guid; NewID: Guid)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        IntegrationManagement: Codeunit "Integration Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if IdFieldNo = 0 then
            exit;

        if not IntegrationManagement.IsIntegrationActivated then
            exit;

        TableRelationsMetadata.SetRange("Related Table ID", TableNo);
        TableRelationsMetadata.SetRange("Related Field No.", IdFieldNo);
        if TableRelationsMetadata.FindSet then
            repeat
                RecRef.Open(TableRelationsMetadata."Table ID");
                FieldRef := RecRef.Field(TableRelationsMetadata."Field No.");
                FieldRef.SetRange(OldID);
                if RecRef.FindSet then
                    repeat
                        FieldRef.Value(NewID);
                        RecRef.Modify();
                    until RecRef.Next = 0;
                RecRef.Close;
            until TableRelationsMetadata.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRelatedFields(var TempTableRelationsMetadata: Record "Table Relations Metadata" temporary)
    begin
    end;
}

