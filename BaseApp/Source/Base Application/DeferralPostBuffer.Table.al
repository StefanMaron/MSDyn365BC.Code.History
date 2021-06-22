table 1703 "Deferral Post. Buffer"
{
    Caption = 'Deferral Post. Buffer';
    ObsoleteReason = 'Replace with tab 1703 Deferral Posting Buffer';
    ObsoleteState = Removed;
    ReplicateData = false;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Prepmt. Exch. Rate Difference,G/L Account,Item,Resource,Fixed Asset';
            OptionMembers = "Prepmt. Exch. Rate Difference","G/L Account",Item,Resource,"Fixed Asset";
        }
        field(2; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(3; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(4; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(5; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(6; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(7; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
        }
        field(8; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
        }
        field(9; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        field(10; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        field(11; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = SystemMetadata;
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(14; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(15; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = SystemMetadata;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
        }
        field(18; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(19; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            DataClassification = SystemMetadata;
        }
        field(20; "Period Description"; Text[100])
        {
            Caption = 'Period Description';
            DataClassification = SystemMetadata;
        }
        field(21; "Deferral Doc. Type"; Option)
        {
            Caption = 'Deferral Doc. Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Purchase,Sales,G/L';
            OptionMembers = Purchase,Sales,"G/L";
        }
        field(22; "Document No."; Code[20])
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
        field(26; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
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
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = SystemMetadata;
        }
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Type, "G/L Account", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Area Code", "Tax Group Code", "Tax Liable", "Use Tax", "Dimension Set ID", "Job No.", "Deferral Code", "Posting Date", "Partial Deferral")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure PrepareSales(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        Clear(Rec);
        Type := SalesLine.Type;
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
        "Deferral Doc. Type" := DeferralUtilities.GetSalesDeferralDocType;
        "Document No." := DocumentNo;
    end;

    procedure ReverseAmounts()
    begin
        Amount := -Amount;
        "Amount (LCY)" := -"Amount (LCY)";
        "Sales/Purch Amount" := -"Sales/Purch Amount";
        "Sales/Purch Amount (LCY)" := -"Sales/Purch Amount (LCY)";
    end;

    procedure PreparePurch(PurchLine: Record "Purchase Line"; DocumentNo: Code[20])
    var
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        Clear(Rec);
        Type := PurchLine.Type;
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
        "Deferral Doc. Type" := DeferralUtilities.GetPurchDeferralDocType;
        "Document No." := DocumentNo;
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

    procedure PrepareRemainderSales(SalesLine: Record "Sales Line"; NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20])
    begin
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, GLAccount, DeferralAccount);
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
        "Gen. Posting Type" := "Gen. Posting Type"::Sale;
    end;

    procedure PrepareRemainderPurchase(PurchaseLine: Record "Purchase Line"; NewAmountLCY: Decimal; NewAmount: Decimal; GLAccount: Code[20]; DeferralAccount: Code[20])
    begin
        PrepareRemainderAmounts(NewAmountLCY, NewAmount, GLAccount, DeferralAccount);
        "Gen. Bus. Posting Group" := PurchaseLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := PurchaseLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := PurchaseLine."VAT Prod. Posting Group";
        "Gen. Posting Type" := "Gen. Posting Type"::Purchase;
    end;

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
}

