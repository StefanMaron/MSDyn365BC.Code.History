table 11000007 "Import Protocol"
{
    Caption = 'Import Protocol';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Import Type"; Option)
        {
            Caption = 'Import Type';
            InitValue = "Report";
            OptionCaption = 'TableData,Table,Form,Report,,Codeunit,XMLport,MenuSuite,Page';
            OptionMembers = TableData,"Table",Form,"Report",,"Codeunit","XMLport",MenuSuite,"Page";
            ValuesAllowed = Report, Codeunit, XMLport;
        }
        field(3; "Import ID"; Integer)
        {
            Caption = 'Import ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FIELD("Import Type"));

            trigger OnValidate()
            begin
                CalcFields("Import Name");
            end;
        }
        field(4; "Import Name"; Text[249])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = FIELD("Import Type"),
                                                                           "Object ID" = FIELD("Import ID")));
            Caption = 'Import Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Default File Name"; Text[80])
        {
            Caption = 'Default File Name';
        }
        field(6; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(7; Current; Boolean)
        {
            Caption = 'Current';
            Editable = false;

            trigger OnValidate()
            begin
                if (not Current) and xRec.Current then begin
                    "Last Used By" := UserId;
                    "Last Used On" := Today;
                end;
            end;
        }
        field(8; "Last Used By"; Code[50])
        {
            Caption = 'Last Used By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Last Used On"; Date)
        {
            Caption = 'Last Used On';
            Editable = false;
        }
        field(10; "Automatic Reconciliation"; Boolean)
        {
            Caption = 'Automatic Reconciliation';
            InitValue = true;
        }
        field(11; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Current)
        {
        }
    }

    fieldgroups
    {
    }
}

