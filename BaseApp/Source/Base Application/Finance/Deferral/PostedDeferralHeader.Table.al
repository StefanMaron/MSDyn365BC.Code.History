namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;

table 1704 "Posted Deferral Header"
{
    Caption = 'Posted Deferral Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
        }
        field(2; "Gen. Jnl. Document No."; Code[20])
        {
            Caption = 'Gen. Jnl. Document No.';
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account" where(Blocked = const(false));
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
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(16; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            NotBlank = true;
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        field(17; CustVendorNo; Code[20])
        {
            Caption = 'CustVendorNo';
        }
        field(18; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(19; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Deferral Doc. Type", "Account No.", "Posting Date", "Gen. Jnl. Document No.", "Document Type", "Document No.", "Line No.")
        {
        }
        key(Key3; "Deferral Doc. Type", CustVendorNo, "Posting Date", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteLines("Deferral Doc. Type", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.");
    end;

    procedure DeleteHeader(DeferralDocType: Integer; GenJnlDocNo: Code[20]; AccountNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    begin
        if LineNo <> 0 then
            if Get(DeferralDocType, GenJnlDocNo, AccountNo, DocumentType, DocumentNo, LineNo) then begin
                Delete();
                DeleteLines(Enum::"Deferral Document Type".FromInteger(DeferralDocType), GenJnlDocNo, AccountNo, DocumentType, DocumentNo, LineNo);
            end;
    end;

    local procedure DeleteLines(DeferralDocType: Enum "Deferral Document Type"; GenJnlDocNo: Code[20]; AccountNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        PostedDeferralLine: Record "Posted Deferral Line";
    begin
        PostedDeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        PostedDeferralLine.SetRange("Gen. Jnl. Document No.", GenJnlDocNo);
        PostedDeferralLine.SetRange("Account No.", AccountNo);
        PostedDeferralLine.SetRange("Document Type", DocumentType);
        PostedDeferralLine.SetRange("Document No.", DocumentNo);
        PostedDeferralLine.SetRange("Line No.", LineNo);
        OnDeleteLinesOnAfterSetFilters(PostedDeferralLine);
        PostedDeferralLine.DeleteAll();
    end;

    procedure DeleteForDoc(DeferralDocType: Integer; GenJnlDocNo: Code[20]; AccountNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20])
    begin
        SetRange("Deferral Doc. Type", DeferralDocType);
        SetRange("Gen. Jnl. Document No.", GenJnlDocNo);
        if AccountNo <> '' then
            SetRange("Account No.", AccountNo);
        if DocumentNo <> '' then begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
        end;
        DeleteAll(true);
    end;

    procedure InitFromDeferralHeader(DeferralHeader: Record "Deferral Header"; GenJnlDocNo: Code[20]; AccountNo: Code[20]; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; DeferralAccount: Code[20]; CustVendNo: Code[20]; PostingDate: Date)
    begin
        Init();
        TransferFields(DeferralHeader);
        "Gen. Jnl. Document No." := GenJnlDocNo;
        "Account No." := AccountNo;
        "Document Type" := NewDocumentType;
        "Document No." := NewDocumentNo;
        "Line No." := NewLineNo;
        "Deferral Account" := DeferralAccount;
        CustVendorNo := CustVendNo;
        "Posting Date" := PostingDate;
        OnBeforePostedDeferralHeaderInsert(Rec, DeferralHeader);
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDeferralHeaderInsert(var PostedDeferralHeader: Record "Posted Deferral Header"; DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLinesOnAfterSetFilters(var PostedDeferralLine: Record "Posted Deferral Line")
    begin
    end;
}

