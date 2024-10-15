namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Currency;

table 5127 "Deferral Header Archive"
{
    Caption = 'Deferral Header Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
        }
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            NotBlank = true;
            TableRelation = "Deferral Template"."Deferral Code";
            ValidateTableRelation = false;
        }
        field(8; "Amount to Defer"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Defer';
        }
        field(9; "Amount to Defer (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount to Defer (LCY)';
        }
        field(10; "Calc. Method"; Enum "Deferral Calculation Method")
        {
            Caption = 'Calc. Method';
        }
        field(11; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(12; "No. of Periods"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Periods';
            NotBlank = true;
        }
        field(13; "Schedule Description"; Text[100])
        {
            Caption = 'Schedule Description';
        }
        field(14; "Initial Amount to Defer"; Decimal)
        {
            Caption = 'Initial Amount to Defer';
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteLines("Deferral Doc. Type", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.");
    end;

    procedure DeleteHeader(DeferralDocType: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOcurrence: Integer; VersionNo: Integer; LineNo: Integer)
    begin
        if Get(DeferralDocType, DocumentType, DocumentNo, LineNo) then begin
            Delete();
            DeleteLines(Enum::"Deferral Document Type".FromInteger(DeferralDocType), DocumentType, DocumentNo, DocNoOcurrence, VersionNo, LineNo);
        end;
    end;

    local procedure DeleteLines(DeferralDocType: Enum "Deferral Document Type"; DocumentType: Integer; DocumentNo: Code[20]; DocNoOcurrence: Integer; VersionNo: Integer; LineNo: Integer)
    var
        DeferralLineArchive: Record "Deferral Line Archive";
    begin
        DeferralLineArchive.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLineArchive.SetRange("Document Type", DocumentType);
        DeferralLineArchive.SetRange("Document No.", DocumentNo);
        DeferralLineArchive.SetRange("Doc. No. Occurrence", DocNoOcurrence);
        DeferralLineArchive.SetRange("Version No.", VersionNo);
        DeferralLineArchive.SetRange("Line No.", LineNo);
        if DeferralLineArchive.FindFirst() then
            DeferralLineArchive.DeleteAll();
    end;
}

