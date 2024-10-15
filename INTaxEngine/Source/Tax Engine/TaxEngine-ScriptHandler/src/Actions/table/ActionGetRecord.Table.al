table 20169 "Action Get Record"
{
    Caption = 'Action Get Record';
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = false;
    fields
    {
        field(1; "Case ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Case ID';
        }
        field(2; "Script ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Script ID';
        }
        field(3; ID; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'ID';
        }
        field(4; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObj."Object ID" where("Object Type" = CONST(Table));
        }
        field(5; "Table Filter ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Table Filter ID';
            TableRelation = "Lookup Table Filter".ID where(
                "Case ID" = field("Case ID"),
                "Script ID" = field("Script ID"),
                ID = field("Table Filter ID"));
        }
        field(6; Method; Option)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Method';
            OptionMembers = First,Last;
        }
        field(7; "Ignore If Record Not Found"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Ignore If Record Not Found';
        }
        field(8; "Record Variable"; Integer)
        {
            TableRelation = "Script Variable".ID where("Script ID" = field("Script ID"), Datatype = CONST(RECORD));
            Caption = 'Record Variable';
            DataClassification = SystemMetadata;
            trigger OnValidate();
            var
                ScriptVariable: Record "Script Variable";
                BlankTableIDErr: Label 'You must select table';
            begin
                if "Record Variable" = 0 then
                    Exit;

                if "Table ID" = 0 then
                    Error(BlankTableIDErr);

                ScriptVariable.GET("Case ID", "Script ID", "Record Variable");
                if ScriptVariable."Table ID" <> "Table ID" then
                    Error(RecordVariableErr, AppObjectHelper.GetObjectName(ObjectType::Table, "Table ID"));
            end;
        }
    }

    keys
    {
        key(K0; "Case ID", "Script ID", ID)
        {
            Clustered = True;
        }
    }

    var
        ActionGetRecordField: Record "Action Get Record Field";
        LookupEntityMgmt: Codeunit "Lookup Entity Mgmt.";
        AppObjectHelper: Codeunit "App Object Helper";
        EmptyGuid: Guid;
        RecordVariableErr: Label 'Invalid Record Variable. %1', Comment = '%1 - Table name with record.';

    trigger OnInsert()
    var
        ScriptSymbolStore: Codeunit "Script Symbol Store";
    begin
        ScriptSymbolStore.OnBeforeValidateIfUpdateIsAllowed("Case ID");
    end;

    trigger OnModify()
    var
        ScriptSymbolStore: Codeunit "Script Symbol Store";
    begin
        ScriptSymbolStore.OnBeforeValidateIfUpdateIsAllowed("Case ID");
    end;

    trigger OnDelete();
    var
        ScriptSymbolStore: Codeunit "Script Symbol Store";
    begin
        ScriptSymbolStore.OnBeforeValidateIfUpdateIsAllowed("Case ID");
        if not IsNullGuid("Table Filter ID") then
            LookupEntityMgmt.DeleteTableFilters(EmptyGuid, "Script ID", "Table Filter ID");

        ActionGetRecordField.Reset();
        ActionGetRecordField.SetRange("Case ID", "Case ID");
        ActionGetRecordField.SetRange("Script ID", "Script ID");
        ActionGetRecordField.SetRange("Get Record ID", ID);
        ActionGetRecordField.DeleteAll(true);
    end;
}