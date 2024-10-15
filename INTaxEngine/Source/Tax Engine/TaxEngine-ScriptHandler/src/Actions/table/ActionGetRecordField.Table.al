table 20170 "Action Get Record Field"
{
    Caption = 'Action Get Record Field';
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = false;
    fields
    {
        field(1; "Script ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Script ID';
        }
        field(2; "Get Record ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Get Record ID';
            TableRelation = "Action Get Record".ID where("Script ID" = field("Script ID"), ID = field("Get Record ID"));
        }
        field(3; "Field ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(4; "Variable ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Variable ID';
            TableRelation = "Script Variable".ID where("Script ID" = field("Script ID"), ID = field("Variable ID"));
        }
        field(7; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObj."Object ID" where("Object Type" = CONST(Table));
        }
        field(8; "Calculate Sum"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Calculate Sum';
        }
        field(9; "Case ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Case ID';
        }
    }

    keys
    {
        key(K0; "Case ID", "Script ID", "Get Record ID", "Field ID")
        {
            Clustered = True;
        }
    }

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

    trigger OnDelete()
    var
        ScriptSymbolStore: Codeunit "Script Symbol Store";
    begin
        ScriptSymbolStore.OnBeforeValidateIfUpdateIsAllowed("Case ID");
    end;
}