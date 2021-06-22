table 742 "VAT Statement Report Line"
{
    Caption = 'VAT Statement Report Line';

    fields
    {
        field(1; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            Editable = false;
            TableRelation = "VAT Report Header"."No.";
        }
        field(2; "VAT Report Config. Code"; Option)
        {
            Caption = 'VAT Report Config. Code';
            Editable = true;
            OptionCaption = 'EC Sales List,VAT Report';
            OptionMembers = "EC Sales List","VAT Report";
            TableRelation = "VAT Reports Configuration"."VAT Report Type";
        }
        field(3; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Row No."; Code[10])
        {
            Caption = 'Row No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Box No."; Text[30])
        {
            Caption = 'Box No.';
        }
        field(7; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
            Editable = false;
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Report No.", "VAT Report Config. Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportHeader.Get("VAT Report Config. Code", "VAT Report No.");

        if (VATReportHeader.Status = VATReportHeader.Status::Released) and
           (not VATReportSetup."Modify Submitted Reports")
        then
            Error(MissingSetupErr, VATReportSetup.TableCaption);
    end;

    var
        VATReportHeader: Record "VAT Report Header";
        MissingSetupErr: Label 'This is not allowed because of the setup in the %1 window.', Comment = '%1 = Setup table';
}

