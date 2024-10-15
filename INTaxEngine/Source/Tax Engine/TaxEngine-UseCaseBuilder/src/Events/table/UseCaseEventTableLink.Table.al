table 20293 "Use Case Event Table Link"
{
    Caption = 'Use Case Event Table Link';
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
        field(2; "ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'ID';
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
        }
        field(4; "Field ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field ID';
        }
        field(5; "Lookup Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Lookup Table ID';
        }
        field(6; "Lookup Field ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Lookup Field ID';
        }
    }
    keys
    {
        key(PK; "Case ID", ID)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        ID := CreateGuid();
    end;

    trigger OnDelete()
    var
        UseCaseFieldLink: Record "Use Case Field Link";
    begin
        UseCaseFieldLink.SetRange("Case ID", "Case ID");
        UseCaseFieldLink.SetRange("Table Filter ID", ID);
        if not UseCaseFieldLink.IsEmpty() then
            UseCaseFieldLink.DeleteAll(true);
    end;
}