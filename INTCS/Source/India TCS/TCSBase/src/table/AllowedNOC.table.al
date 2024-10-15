table 18807 "Allowed NOC"
{
    Caption = 'Allowed NOC';
    DataClassification = EndUserIdentifiableInformation;
    DrillDownPageId = "Allowed NOC";
    LookupPageId = "Allowed NOC";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Customer No."; code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Customer;
        }
        field(2; "TCS Nature of Collection"; code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TCS Nature Of Collection";
        }
        field(3; "Default NOC"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                CheckDefault();
            end;
        }
        field(4; "Threshold Overlook"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
        }

        field(5; "Surcharge Overlook"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; Description; Text[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("TCS Nature Of Collection".Description where(Code = field("TCS Nature of Collection")));
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Customer No.", "TCS Nature of Collection")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "TCS Nature of Collection", Description)
        {

        }
    }
    local procedure CheckDefault()
    var
        AllowedNoc: Record "Allowed Noc";
        DefaultErr: Label 'Default Noc is already selected for Noc Type %1.', Comment = '%1=Noc Type.';
    begin
        if rec."Default Noc" then begin
            AllowedNoc.reset();
            AllowedNoc.SetRange("Customer No.", "Customer No.");
            AllowedNoc.SetRange("Default Noc", true);
            if not AllowedNoc.IsEmpty() then
                Error(DefaultErr, AllowedNoc."TCS Nature of Collection");
        end;
    end;
}