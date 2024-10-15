namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
#if not CLEAN23
using Microsoft.Finance.ReceivablesPayables;
#endif
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

table 1706 "Deferral Posting Buffer"
{
    Caption = 'Deferral Posting Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Prepmt. Exch. Rate Difference,G/L Account,Item,Resource,Fixed Asset';
            OptionMembers = "Prepmt. Exch. Rate Difference","G/L Account",Item,Resource,"Fixed Asset";
        }
        field(3; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        field(4; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        field(5; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        field(6; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(7; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(8; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        field(9; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        field(10; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        field(11; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        field(12; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        field(13; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(14; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(15; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(16; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = SystemMetadata;
        }
        field(17; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(18; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(19; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(20; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            DataClassification = SystemMetadata;
        }
        field(21; "Period Description"; Text[100])
        {
            Caption = 'Period Description';
            DataClassification = SystemMetadata;
        }
        field(22; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            DataClassification = SystemMetadata;
        }
        field(23; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(24; "Sales/Purch Amount"; Decimal)
        {
            Caption = 'Sales/Purch Amount';
            DataClassification = SystemMetadata;
        }
        field(25; "Sales/Purch Amount (LCY)"; Decimal)
        {
            Caption = 'Sales/Purch Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(26; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            DataClassification = SystemMetadata;
        }
        field(27; "Partial Deferral"; Boolean)
        {
            Caption = 'Partial Deferral';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = SystemMetadata;
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Deferral Doc. Type", "Document No.", "Deferral Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure PrepareSales(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        Clear(Rec);
        Type := SalesLine.Type.AsInteger();
        "System-Created Entry" := true;
        "Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Job No." := SalesLine."Job No.";

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then begin
            "Tax Area Code" := SalesLine."Tax Area Code";
            "Tax Group Code" := SalesLine."Tax Group Code";
            "Tax Liable" := SalesLine."Tax Liable";
            "Use Tax" := false;
        end;
        "Deferral Code" := SalesLine."Deferral Code";
        "Deferral Doc. Type" := Enum::"Deferral Document Type"::Sales;
        "Document No." := DocumentNo;

        OnAfterPrepareSales(Rec, SalesLine);
    end;

    procedure ReverseAmounts()
    begin
        Amount := -Amount;
        "Amount (LCY)" := -"Amount (LCY)";
        "Sales/Purch Amount" := -"Sales/Purch Amount";
        "Sales/Purch Amount (LCY)" := -"Sales/Purch Amount (LCY)";
    end;

    procedure PreparePurch(PurchLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        Clear(Rec);
        Type := PurchLine.Type.AsInteger();
        "System-Created Entry" := true;
        "Global Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Job No." := PurchLine."Job No.";

        if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then begin
            "Tax Area Code" := PurchLine."Tax Area Code";
            "Tax Group Code" := PurchLine."Tax Group Code";
            "Tax Liable" := PurchLine."Tax Liable";
            "Use Tax" := false;
        end;
        "Deferral Code" := PurchLine."Deferral Code";
        "Deferral Doc. Type" := Enum::"Deferral Document Type"::Purchase;
        "Document No." := DocumentNo;

        OnAfterPreparePurch(Rec, PurchLine);
    end;

    local procedure PrepareRemainderAmounts(NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20])
    begin
        "Amount (LCY)" := 0;
        Amount := 0;
        "Sales/Purch Amount (LCY)" := NewAmountLCY;
        "Sales/Purch Amount" := NewAmount;
        "G/L Account" := GLAccount;
        "Deferral Account" := DeferralAccount;
        "Partial Deferral" := true;
    end;

    procedure PrepareRemainderSales(SalesLine: Record "Sales Line"; NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20]; DeferralLineNo: Integer)
    begin
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, GLAccount, DeferralAccount);
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
        "Gen. Posting Type" := "Gen. Posting Type"::Sale;
        "Deferral Line No." := DeferralLineNo;

        OnAfterPrepareRemainderSales(Rec, SalesLine);
    end;

    procedure PrepareRemainderPurchase(PurchaseLine: Record "Purchase Line"; NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20]; DeferralLineNo: Integer)
    begin
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, GLAccount, DeferralAccount);
        "Gen. Bus. Posting Group" := PurchaseLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := PurchaseLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := PurchaseLine."VAT Prod. Posting Group";
        "Gen. Posting Type" := "Gen. Posting Type"::Purchase;
        "Deferral Line No." := DeferralLineNo;

        OnAfterPrepareRemainderPurchase(Rec, PurchaseLine);
    end;

#if not CLEAN23
    [Obsolete('Replaced by PrepareInitialAmounts()', '20.0')]
    procedure PrepareInitialPair(InvoicePostBuffer: Record "Invoice Post. Buffer"; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20])
    var
        NewAmountLCY: Decimal;
        NewAmount: Decimal;
    begin
        if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
            NewAmountLCY := RemainAmtToDefer;
            NewAmount := RemainAmtToDeferACY;
        end else begin
            NewAmountLCY := InvoicePostBuffer.Amount;
            NewAmount := InvoicePostBuffer."Amount (ACY)";
        end;
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, DeferralAccount, GLAccount);
        "Amount (LCY)" := NewAmountLCY;
        Amount := NewAmount;
    end;
#endif

    procedure PrepareInitialAmounts(AmountLCY: Decimal; AmountACY: decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20])
    begin
        PrepareInitialAmounts(AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, GLAccount, DeferralAccount, 0, 0);
    end;

    procedure PrepareInitialAmounts(AmountLCY: Decimal; AmountACY: decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20]; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        NewAmountLCY: Decimal;
        NewAmount: Decimal;
    begin
        if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
            NewAmountLCY := RemainAmtToDefer;
            NewAmount := RemainAmtToDeferACY;
        end else begin
            NewAmountLCY := AmountLCY - DiscountAmount;
            NewAmount := AmountACY - DiscountAmountACY;
        end;
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, DeferralAccount, GLAccount);
        "Amount (LCY)" := NewAmountLCY;
        Amount := NewAmount;
    end;

    procedure InitFromDeferralLine(DeferralLine: Record "Deferral Line")
    begin
        "Amount (LCY)" := DeferralLine."Amount (LCY)";
        Amount := DeferralLine.Amount;
        "Sales/Purch Amount (LCY)" := DeferralLine."Amount (LCY)";
        "Sales/Purch Amount" := DeferralLine.Amount;
        "Posting Date" := DeferralLine."Posting Date";
        Description := DeferralLine.Description;
    end;

#if not CLEAN23
    [Obsolete('Replaced by procedure Update without parameter InvoicePostBuffer.', '19.0')]
    procedure Update(DeferralPostBuffer: Record "Deferral Posting Buffer"; InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        Rec := DeferralPostBuffer;
        SetRange(Type, DeferralPostBuffer.Type);
        SetRange("G/L Account", DeferralPostBuffer."G/L Account");
        SetRange("Gen. Bus. Posting Group", DeferralPostBuffer."Gen. Bus. Posting Group");
        SetRange("Gen. Prod. Posting Group", DeferralPostBuffer."Gen. Prod. Posting Group");
        SetRange("VAT Bus. Posting Group", DeferralPostBuffer."VAT Bus. Posting Group");
        SetRange("VAT Prod. Posting Group", DeferralPostBuffer."VAT Prod. Posting Group");
        SetRange("Tax Area Code", DeferralPostBuffer."Tax Area Code");
        SetRange("Tax Group Code", DeferralPostBuffer."Tax Group Code");
        SetRange("Tax Liable", DeferralPostBuffer."Tax Liable");
        SetRange("Use Tax", DeferralPostBuffer."Use Tax");
        SetRange("Dimension Set ID", DeferralPostBuffer."Dimension Set ID");
        SetRange("Job No.", DeferralPostBuffer."Job No.");
        SetRange("Deferral Code", DeferralPostBuffer."Deferral Code");
        SetRange("Posting Date", DeferralPostBuffer."Posting Date");
        SetRange("Partial Deferral", DeferralPostBuffer."Partial Deferral");
        SetRange("Deferral Line No.", DeferralPostBuffer."Deferral Line No.");
        OnUpdateOnAfterSetFilters(Rec, DeferralPostBuffer);
        if FindFirst() then begin
            Amount += DeferralPostBuffer.Amount;
            "Amount (LCY)" += DeferralPostBuffer."Amount (LCY)";
            "Sales/Purch Amount" += DeferralPostBuffer."Sales/Purch Amount";
            "Sales/Purch Amount (LCY)" += DeferralPostBuffer."Sales/Purch Amount (LCY)";
            if not DeferralPostBuffer."System-Created Entry" then
                "System-Created Entry" := false;
            if IsCombinedDeferralZero() then
                Delete()
            else
                Modify();
        end else begin
            "Entry No." := GetLastEntryNo() + 1;
            "Dimension Set ID" := InvoicePostBuffer."Dimension Set ID";
            "Global Dimension 1 Code" := InvoicePostBuffer."Global Dimension 1 Code";
            "Global Dimension 2 Code" := InvoicePostBuffer."Global Dimension 2 Code";
            OnBeforeDeferralPostBufferInsert(Rec, DeferralPostBuffer, InvoicePostBuffer);
            Insert();
        end;
    end;
#endif

    procedure Update(DeferralPostBuffer: Record "Deferral Posting Buffer")
    begin
        SetRange(Type, DeferralPostBuffer.Type);
        SetRange("G/L Account", DeferralPostBuffer."G/L Account");
        SetRange("Gen. Bus. Posting Group", DeferralPostBuffer."Gen. Bus. Posting Group");
        SetRange("Gen. Prod. Posting Group", DeferralPostBuffer."Gen. Prod. Posting Group");
        SetRange("VAT Bus. Posting Group", DeferralPostBuffer."VAT Bus. Posting Group");
        SetRange("VAT Prod. Posting Group", DeferralPostBuffer."VAT Prod. Posting Group");
        SetRange("Tax Area Code", DeferralPostBuffer."Tax Area Code");
        SetRange("Tax Group Code", DeferralPostBuffer."Tax Group Code");
        SetRange("Tax Liable", DeferralPostBuffer."Tax Liable");
        SetRange("Use Tax", DeferralPostBuffer."Use Tax");
        SetRange("Dimension Set ID", DeferralPostBuffer."Dimension Set ID");
        SetRange("Job No.", DeferralPostBuffer."Job No.");
        SetRange("Deferral Code", DeferralPostBuffer."Deferral Code");
        SetRange("Posting Date", DeferralPostBuffer."Posting Date");
        SetRange("Partial Deferral", DeferralPostBuffer."Partial Deferral");
        SetRange("Deferral Line No.", DeferralPostBuffer."Deferral Line No.");
        OnUpdateOnAfterSetFilters(Rec, DeferralPostBuffer);
        if FindFirst() then begin
            Amount += DeferralPostBuffer.Amount;
            "Amount (LCY)" += DeferralPostBuffer."Amount (LCY)";
            "Sales/Purch Amount" += DeferralPostBuffer."Sales/Purch Amount";
            "Sales/Purch Amount (LCY)" += DeferralPostBuffer."Sales/Purch Amount (LCY)";
            if not DeferralPostBuffer."System-Created Entry" then
                "System-Created Entry" := false;
            if IsCombinedDeferralZero() then
                Delete()
            else
                Modify();
        end else begin
            Rec := DeferralPostBuffer;
            "Entry No." := GetLastEntryNo() + 1;
            OnUpdateOnBeforeDeferralPostBufferInsert(Rec, DeferralPostBuffer);
            Insert();
        end;
    end;

    local procedure IsCombinedDeferralZero(): Boolean
    begin
        if (Amount = 0) and ("Amount (LCY)" = 0) and
           ("Sales/Purch Amount" = 0) and ("Sales/Purch Amount (LCY)" = 0)
        then
            exit(true);

        exit(false);
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareSales(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreparePurch(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; PurchaseLine: Record "Purchase Line");
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by OnUpdateOnBeforeDeferralPostBufferInsert().', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeferralPostBufferInsert(var ToDeferralPostingBuffer: Record "Deferral Posting Buffer"; FromDeferralPostingBuffer: Record "Deferral Posting Buffer"; InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOnAfterSetFilters(var DeferralPostingBufferRec: Record "Deferral Posting Buffer"; DeferralPostBuffer: Record "Deferral Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOnBeforeDeferralPostBufferInsert(var ToDeferralPostingBuffer: Record "Deferral Posting Buffer"; FromDeferralPostingBuffer: Record "Deferral Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareRemainderPurchase(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareRemainderSales(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;
}

