table 17243 "Tax Reg. Norm Dim. Filter"
{
    Caption = 'Tax Reg. Norm Dim. Filter';
    LookupPageID = "Tax Reg. Norm Dim. Filters";

    fields
    {
        field(1; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(2; "Norm Group Code"; Code[10])
        {
            Caption = 'Norm Group Code';
            NotBlank = true;
            TableRelation = "Tax Register Norm Group".Code;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnLookup()
            begin
                Dimension.Reset;
                Dimension.FilterGroup(2);
                FilterGroup(2);
                CopyFilter("Dimension Code", Dimension.Code);
                Dimension.FilterGroup(0);
                FilterGroup(0);
                if ACTION::LookupOK = PAGE.RunModal(0, Dimension) then
                    "Dimension Code" := Dimension.Code;
            end;
        }
        field(5; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Dimension Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(9; "Dimension Name"; Text[50])
        {
            CalcFormula = Lookup ("Dimension Value".Name WHERE("Dimension Code" = FIELD("Dimension Code"),
                                                               Code = FIELD("Dimension Value Filter")));
            Caption = 'Dimension Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Norm Jurisdiction Code", "Norm Group Code", "Line No.", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ValidateChangeDeclaration(true);
    end;

    trigger OnInsert()
    begin
        ValidateChangeDeclaration(true);
    end;

    trigger OnModify()
    begin
        ValidateChangeDeclaration("Dimension Value Filter" <> xRec."Dimension Value Filter");
    end;

    trigger OnRename()
    begin
        Error(Text1001, TableCaption);
    end;

    var
        Dimension: Record Dimension;
        Text1001: Label 'You can''t rename an %1.';

    [Scope('OnPrem')]
    procedure ValidateChangeDeclaration(Incident: Boolean)
    var
        TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction";
    begin
        if not Incident then
            exit;

        TaxRegNormJurisdiction.Get("Norm Jurisdiction Code");
    end;
}

