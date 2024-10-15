namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.GeneralLedger.Account;

table 1705 "Posted Deferral Line"
{
    Caption = 'Posted Deferral Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            TableRelation = "Posted Deferral Header"."Deferral Doc. Type";
        }
        field(2; "Gen. Jnl. Document No."; Code[20])
        {
            Caption = 'Gen. Jnl. Document No.';
            TableRelation = "Posted Deferral Header"."Gen. Jnl. Document No.";
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "Posted Deferral Header"."Account No.";
        }
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
            TableRelation = "Posted Deferral Header"."Document Type";
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Posted Deferral Header"."Document No.";
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Posted Deferral Header"."Line No.";
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(12; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            NotBlank = true;
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.", "Posting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InitFromDeferralLine(DeferralLine: Record "Deferral Line"; GenJnlDocNo: Code[20]; AccountNo: Code[20]; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; DeferralAccount: Code[20])
    begin
        Init();
        TransferFields(DeferralLine);
        "Gen. Jnl. Document No." := GenJnlDocNo;
        "Account No." := AccountNo;
        "Document Type" := NewDocumentType;
        "Document No." := NewDocumentNo;
        "Line No." := NewLineNo;
        "Deferral Account" := DeferralAccount;
        OnBeforeInitFromDeferralLine(Rec, DeferralLine);
        Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromDeferralLine(var PostedDeferralLine: Record "Posted Deferral Line"; DeferralLine: Record "Deferral Line")
    begin
    end;
}

