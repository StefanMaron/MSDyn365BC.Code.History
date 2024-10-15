table 11603 "BAS Business Unit"
{
    Caption = 'BAS Business Unit';

    fields
    {
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            NotBlank = true;
            TableRelation = Company.Name;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(4; "BAS Version"; Integer)
        {
            Caption = 'BAS Version';

            trigger OnLookup()
            begin
                if "Company Name" <> CompanyName then
                    BASCalcSheet.ChangeCompany("Company Name");
                BASCalcSheet.SetRange(A1, "Document No.");
                if PAGE.RunModal(PAGE::"BAS Calc. Schedule List", BASCalcSheet, BASCalcSheet."BAS Version") = ACTION::LookupOK then
                    Validate("BAS Version", BASCalcSheet."BAS Version");
            end;

            trigger OnValidate()
            begin
                if "Company Name" <> CompanyName then
                    BASCalcSheet.ChangeCompany("Company Name");
                BASCalcSheet.Get("Document No.", "BAS Version");
            end;
        }
        field(5; "Document No."; Code[11])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            begin
                if "Company Name" <> CompanyName then
                    BASCalcSheet.ChangeCompany("Company Name");
                if PAGE.RunModal(PAGE::"BAS Calc. Schedule List", BASCalcSheet, BASCalcSheet.A1) = ACTION::LookupOK then
                    Validate("Document No.", BASCalcSheet.A1);
                "BAS Version" := BASCalcSheet."BAS Version";
            end;

            trigger OnValidate()
            begin
                if "Document No." <> '' then begin
                    if "Company Name" <> CompanyName then
                        BASCalcSheet.ChangeCompany("Company Name");
                    BASCalcSheet.SetRange(A1, "Document No.");
                    BASCalcSheet.FindFirst;
                end else
                    "BAS Version" := 0;
            end;
        }
    }

    keys
    {
        key(Key1; "Company Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        GLSetup.Get;
        GLSetup.TestField("BAS Group Company", true);
    end;

    trigger OnModify()
    begin
        GLSetup.Get;
        GLSetup.TestField("BAS Group Company", true);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        BASCalcSheet: Record "BAS Calculation Sheet";
}

