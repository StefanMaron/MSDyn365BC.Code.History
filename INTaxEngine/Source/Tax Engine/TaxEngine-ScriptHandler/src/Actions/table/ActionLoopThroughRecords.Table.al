table 20175 "Action Loop Through Records"
{
    Caption = 'Action Loop Through Records';
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
            trigger OnValidate();
            var
                ScriptVariable: Record "Script Variable";
            begin
                if "Table ID" = 0 then
                    Exit;

                if "Record Variable" = 0 then
                    Exit;

                ScriptVariable.GET("Script ID", "Record Variable");
                if ScriptVariable."Table ID" <> "Table ID" then
                    "Record Variable" := 0;
            end;
        }
        field(5; "Table Filter ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Table Filter ID';
            TableRelation = "Lookup Table Filter".ID where(
                "Case ID" = field("Case ID"),
                "Script ID" = field("Script ID"));
        }
        field(6; Order; Option)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Order';
            OptionMembers = "Ascending","Descending";
        }
        field(7; "Table Sorting ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Table Sorting ID';
            TableRelation = "Lookup Table Sorting".ID where(
                "Case ID" = field("Case ID"),
                "Script ID" = field("Script ID"));
        }
        field(8; Distinct; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Distinct';
            trigger OnValidate();
            begin
                if Distinct then
                    "Count Variable" := 0;
            end;
        }
        field(9; "Index Variable"; Integer)
        {
            TableRelation = "Script Variable".ID where("Script ID" = field("Script ID"));
            DataClassification = SystemMetadata;
            Caption = 'Index Variable';
        }
        field(10; "Count Variable"; Integer)
        {
            TableRelation = "Script Variable".ID where("Script ID" = field("Script ID"));
            DataClassification = SystemMetadata;
            Caption = 'Count Variable';
        }
        field(11; "Record Variable"; Integer)
        {
            TableRelation = "Script Variable".ID where("Script ID" = field("Script ID"), Datatype = CONST(Record));
            DataClassification = SystemMetadata;
            Caption = 'Record Variable';
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
        ActionContainer: Record "Action Container";
        ActionLoopThroughRecField: Record "Action Loop Through Rec. Field";
        LookupEntityMgmt: Codeunit "Lookup Entity Mgmt.";
        AppObjectHelper: Codeunit "App Object Helper";
        EmptyGuid: Guid;
        RecordVariableErr: Label 'Variable should be of %1 type.', Comment = '%1 = Symbol Data Type';

    procedure DeleteFields();
    begin
        ActionLoopThroughRecField.Reset();
        ActionLoopThroughRecField.SetRange("Case ID", "Case ID");
        ActionLoopThroughRecField.SetRange("Script ID", "Script ID");
        ActionLoopThroughRecField.SetRange("Loop ID", ID);
        ActionLoopThroughRecField.DeleteAll(true);
    end;

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
            LookupEntityMgmt.DeleteTableFilters("Case ID", "Script ID", "Table Filter ID");

        if not IsNullGuid("Table Sorting ID") then
            LookupEntityMgmt.DeleteTableSorting("Case ID", "Script ID", "Table Sorting ID");

        DeleteFields();

        ActionContainer.Reset();
        ActionContainer.SetRange("Case ID", "Case ID");
        ActionContainer.SetRange("Script ID", "Script ID");
        ActionContainer.SetRange("Container Type", "Container Action Type"::LOOPTHROUGHRECORDS);
        ActionContainer.SetRange("Container Action ID", ID);
        ActionContainer.DeleteAll(true);
    end;
}