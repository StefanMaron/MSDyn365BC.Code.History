table 20287 "Tax Table Relation"
{
    Caption = 'Tax Table Relation';
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = false;
    fields
    {
        field(1; "Case ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Case ID';
            TableRelation = "Tax Use Case".ID;
        }
        field(2; ID; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'ID';
        }
        field(5; "Source ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Source ID';
        }
        field(7; "Table Filter ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Table Filter ID';
        }
    }

    keys
    {
        key(K0; "Case ID", ID)
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

    trigger OnDelete();
    var
        ScriptSymbolStore: Codeunit "Script Symbol Store";
    begin
        ScriptSymbolStore.OnBeforeValidateIfUpdateIsAllowed("Case ID");
        if not IsNullGuid("Table Filter ID") then
            LookupEntityMgmt.DeleteTableFilters("Case ID", EmptyGuid, "Table Filter ID");
    end;

    trigger OnModify()
    var
        ScriptSymbolStore: Codeunit "Script Symbol Store";
    begin
        ScriptSymbolStore.OnBeforeValidateIfUpdateIsAllowed("Case ID");
    end;

    var
        LookupEntityMgmt: Codeunit "Lookup Entity Mgmt.";
        EmptyGuid: Guid;
}