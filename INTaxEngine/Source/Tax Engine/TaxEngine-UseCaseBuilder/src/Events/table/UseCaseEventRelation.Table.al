table 20292 "Use Case Event Relation"
{
    LookupPageID = "Use Case Event Hierarchies";
    DrillDownPageID = "Use Case Event Hierarchies";
    Caption = 'Use Case Event Relation';
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = false;
    fields
    {
        field(1; "Event Name"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Event Name';
        }
        field(2; "Case ID"; Guid)
        {
            TableRelation = "Tax Use Case".ID;
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Case ID';
        }
        field(3; "Use Case Name"; Text[2000])
        {
            Caption = 'Use Case Name';
            FieldClass = FlowField;
            CalcFormula = Lookup("Tax Use Case".Description WHERE(ID = Field("Case ID")));
            Editable = false;
        }
        field(4; Sequence; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Sequence';
        }
        field(5; "Table Relation ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Table Relation ID';
        }
        field(6; Enabled; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Enabled';
        }
        field(7; Description; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Description';
        }
        field(8; "Tax Type"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Tax Type';
        }
    }
    keys
    {
        key(K0; "Event Name", "Case ID")
        {
            Clustered = True;
        }
        key(UI; Sequence)
        {

        }
    }

    trigger OnDelete()
    var
        UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
    begin
        if not IsNullGuid("Table Relation ID") then
            UseCaseEntityMgmt.DeleteTableLinking("Case ID", "Table Relation ID");
    end;

    Var
        EmptyGuid: Guid;
}