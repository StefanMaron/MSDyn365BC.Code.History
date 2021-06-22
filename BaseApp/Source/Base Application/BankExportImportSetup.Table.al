table 1200 "Bank Export/Import Setup"
{
    Caption = 'Bank Export/Import Setup';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Bank Export/Import Setup";
    LookupPageID = "Bank Export/Import Setup";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Export,Import,Export-Positive Pay';
            OptionMembers = Export,Import,"Export-Positive Pay";

            trigger OnValidate()
            begin
                if Direction = Direction::"Export-Positive Pay" then
                    "Processing Codeunit ID" := CODEUNIT::"Exp. Launcher Pos. Pay"
                else
                    if "Processing Codeunit ID" = CODEUNIT::"Exp. Launcher Pos. Pay" then
                        "Processing Codeunit ID" := 0;
            end;
        }
        field(4; "Processing Codeunit ID"; Integer)
        {
            Caption = 'Processing Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Codeunit));
        }
        field(5; "Processing Codeunit Name"; Text[80])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Codeunit),
                                                                           "Object ID" = FIELD("Processing Codeunit ID")));
            Caption = 'Processing Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Processing XMLport ID"; Integer)
        {
            Caption = 'Processing XMLport ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(XMLport));
        }
        field(7; "Processing XMLport Name"; Text[80])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(XMLport),
                                                                           "Object ID" = FIELD("Processing XMLport ID")));
            Caption = 'Processing XMLport Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Data Exch. Def. Code"; Code[20])
        {
            Caption = 'Data Exch. Def. Code';
            TableRelation = IF (Direction = CONST(Import)) "Data Exch. Def".Code WHERE(Type = CONST("Bank Statement Import"))
            ELSE
            IF (Direction = CONST(Export)) "Data Exch. Def".Code WHERE(Type = CONST("Payment Export"))
            ELSE
            IF (Direction = CONST("Export-Positive Pay")) "Data Exch. Def".Code WHERE(Type = CONST("Positive Pay Export"));
        }
        field(9; "Data Exch. Def. Name"; Text[100])
        {
            CalcFormula = Lookup ("Data Exch. Def".Name WHERE(Code = FIELD("Data Exch. Def. Code")));
            Caption = 'Data Exch. Def. Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Preserve Non-Latin Characters"; Boolean)
        {
            Caption = 'Preserve Non-Latin Characters';
            InitValue = true;
        }
        field(11; "Check Export Codeunit"; Integer)
        {
            Caption = 'Check Export Codeunit';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Codeunit));
        }
        field(12; "Check Export Codeunit Name"; Text[30])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Codeunit),
                                                                           "Object ID" = FIELD("Check Export Codeunit")));
            Caption = 'Check Export Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

