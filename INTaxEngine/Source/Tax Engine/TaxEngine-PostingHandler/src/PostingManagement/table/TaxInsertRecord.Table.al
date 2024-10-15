table 20334 "Tax Insert Record"
{
    Caption = 'Tax Insert Record';
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
        field(2; ID; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'ID';
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));

            trigger OnValidate();
            begin
                if "Table ID" = 0 then
                    Exit;

                if "Record Variable" = 0 then
                    Exit;

                ScriptVariable.GET("Case ID", "Record Variable");
                if ScriptVariable."Table ID" <> "Table ID" then
                    "Record Variable" := 0;
            end;
        }
        field(4; "Run Trigger"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Run Trigger';
        }
        field(10; "Record Variable"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Record Variable';
            TableRelation = "Script Variable".ID WHERE("Script ID" = Field("Case ID"), Datatype = CONST(Record));
            trigger OnValidate()
            var
                BlankTableNameErr: Label 'You must select table';
            begin
                if "Record Variable" = 0 then
                    Exit;

                if "Table ID" = 0 then
                    Error(BlankTableNameErr);

                ScriptVariable.GET("Case ID", "Record Variable");
                if ScriptVariable."Table ID" <> "Table ID" then
                    Error(RecordVariableErr, AppObjectHelper.GetObjectName(ObjectType::Table, "Table ID"));
            end;
        }
        field(12; "Script ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Script ID';
        }
        field(13; "Sub Ledger Group By"; Option)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Sub Ledger Group By';
            OptionMembers = "Component","Line / Component";
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
        InsertRecordField: Record "Tax Insert Record Field";
        ScriptVariable: Record "Script Variable";
        AppObjectHelper: Codeunit "App Object Helper";
        RecordVariableErr: Label 'Variable should be of Type ''%1''.', Comment = '%1 - Table Name';

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

        InsertRecordField.Reset();
        InsertRecordField.SetRange("Case ID", "Case ID");
        InsertRecordField.SetRange("Script ID", "Script ID");
        InsertRecordField.SetRange("Insert Record ID", ID);
        InsertRecordField.DeleteAll(true);
    end;
}