table 1248 "Ledger Entry Matching Buffer"
{
    Caption = 'Ledger Entry Matching Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Account Type"; Option)
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Customer,Vendor,G/L Account,Bank Account';
            OptionMembers = Customer,Vendor,"G/L Account","Bank Account";
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(5; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = SystemMetadata;
        }
        field(8; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(12; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(20; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(21; "Remaining Amt. Incl. Discount"; Decimal)
        {
            Caption = 'Remaining Amt. Incl. Discount';
            DataClassification = SystemMetadata;
        }
        field(22; "Pmt. Discount Due Date"; Date)
        {
            Caption = 'Pmt. Discount Due Date';
            DataClassification = SystemMetadata;
        }
        field(11700; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
        field(11701; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
        field(11702; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Account Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertFromCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; UseLCYAmounts: Boolean; var UsePaymentDiscounts: Boolean)
    begin
        Clear(Rec);
        "Entry No." := CustLedgerEntry."Entry No.";
        "Account Type" := "Account Type"::Customer;
        "Account No." := CustLedgerEntry."Customer No.";
        "Due Date" := CustLedgerEntry."Due Date";
        "Posting Date" := CustLedgerEntry."Posting Date";
        "Document No." := CustLedgerEntry."Document No.";
        "External Document No." := CustLedgerEntry."External Document No.";

        if UseLCYAmounts then
            "Remaining Amount" := CustLedgerEntry."Remaining Amt. (LCY)"
        else
            "Remaining Amount" := CustLedgerEntry."Remaining Amount";

        "Pmt. Discount Due Date" := GetCustomerLedgerEntryDiscountDueDate(CustLedgerEntry);

        "Remaining Amt. Incl. Discount" := "Remaining Amount";
        if "Pmt. Discount Due Date" > 0D then begin
            if UseLCYAmounts then
                "Remaining Amt. Incl. Discount" -=
                  Round(CustLedgerEntry."Remaining Pmt. Disc. Possible" / CustLedgerEntry."Adjusted Currency Factor")
            else
                "Remaining Amt. Incl. Discount" -= CustLedgerEntry."Remaining Pmt. Disc. Possible";
            UsePaymentDiscounts := true;
        end;

        // NAVCZ
        "Specific Symbol" := CustLedgerEntry."Specific Symbol";
        "Variable Symbol" := CustLedgerEntry."Variable Symbol";
        "Constant Symbol" := CustLedgerEntry."Constant Symbol";
        // NAVCZ

        OnBeforeInsertFromCustomerLedgerEntry(Rec, CustLedgerEntry);
        Insert(true);
    end;

    procedure InsertFromVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; UseLCYAmounts: Boolean; var UsePaymentDiscounts: Boolean)
    begin
        Clear(Rec);
        "Entry No." := VendorLedgerEntry."Entry No.";
        "Account Type" := "Account Type"::Vendor;
        "Account No." := VendorLedgerEntry."Vendor No.";
        "Due Date" := VendorLedgerEntry."Due Date";
        "Posting Date" := VendorLedgerEntry."Posting Date";
        "Document No." := VendorLedgerEntry."Document No.";
        "External Document No." := VendorLedgerEntry."External Document No.";

        if UseLCYAmounts then
            "Remaining Amount" := VendorLedgerEntry."Remaining Amt. (LCY)"
        else
            "Remaining Amount" := VendorLedgerEntry."Remaining Amount";

        "Pmt. Discount Due Date" := GetVendorLedgerEntryDiscountDueDate(VendorLedgerEntry);

        "Remaining Amt. Incl. Discount" := "Remaining Amount";
        if "Pmt. Discount Due Date" > 0D then begin
            if UseLCYAmounts then
                "Remaining Amt. Incl. Discount" -=
                  Round(VendorLedgerEntry."Remaining Pmt. Disc. Possible" / VendorLedgerEntry."Adjusted Currency Factor")
            else
                "Remaining Amt. Incl. Discount" -= VendorLedgerEntry."Remaining Pmt. Disc. Possible";
            UsePaymentDiscounts := true;
        end;

        // NAVCZ
        "Specific Symbol" := VendorLedgerEntry."Specific Symbol";
        "Variable Symbol" := VendorLedgerEntry."Variable Symbol";
        "Constant Symbol" := VendorLedgerEntry."Constant Symbol";
        // NAVCZ

        OnBeforeInsertFromVendorLedgerEntry(Rec, VendorLedgerEntry);
        Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertFromGeneralLedgerEntry(GLEntry: Record "G/L Entry")
    begin
        // NAVCZ
        Clear(Rec);
        "Entry No." := GLEntry."Entry No.";
        "Account Type" := "Account Type"::"G/L Account";
        "Account No." := GLEntry."G/L Account No.";
        "Posting Date" := GLEntry."Posting Date";
        "Document No." := GLEntry."Document No.";
        "External Document No." := GLEntry."External Document No.";
        "Remaining Amount" := GLEntry.RemainingAmount;
        "Remaining Amt. Incl. Discount" := "Remaining Amount";
        "Variable Symbol" := GLEntry."Variable Symbol";
        Insert(true);
    end;

    procedure InsertFromBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        Clear(Rec);
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Account Type" := "Account Type"::"Bank Account";
        "Account No." := BankAccountLedgerEntry."Bank Account No.";
        "Bal. Account Type" := BankAccountLedgerEntry."Bal. Account Type";
        "Bal. Account No." := BankAccountLedgerEntry."Bal. Account No.";
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Document Type" := BankAccountLedgerEntry."Document Type";
        "Document No." := BankAccountLedgerEntry."Document No.";
        "External Document No." := BankAccountLedgerEntry."External Document No.";
        "Remaining Amount" := BankAccountLedgerEntry."Remaining Amount";
        "Remaining Amt. Incl. Discount" := "Remaining Amount";
        OnBeforeInsertFromBankAccountLedgerEntry(Rec, BankAccountLedgerEntry);
        Insert(true);
    end;

    procedure GetApplicableRemainingAmount(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; UsePaymentDiscounts: Boolean): Decimal
    begin
        if not UsePaymentDiscounts then
            exit("Remaining Amount");

        if BankAccReconciliationLine."Transaction Date" > "Pmt. Discount Due Date" then
            exit("Remaining Amount");

        exit("Remaining Amt. Incl. Discount");
    end;

    procedure GetNoOfLedgerEntriesWithinRange(MinAmount: Decimal; MaxAmount: Decimal; TransactionDate: Date; UsePaymentDiscounts: Boolean): Integer
    begin
        exit(GetNoOfLedgerEntriesInAmountRange(MinAmount, MaxAmount, TransactionDate, '>=%1&<=%2', UsePaymentDiscounts));
    end;

    procedure GetNoOfLedgerEntriesOutsideRange(MinAmount: Decimal; MaxAmount: Decimal; TransactionDate: Date; UsePaymentDiscounts: Boolean): Integer
    begin
        exit(GetNoOfLedgerEntriesInAmountRange(MinAmount, MaxAmount, TransactionDate, '<%1|>%2', UsePaymentDiscounts));
    end;

    local procedure GetNoOfLedgerEntriesInAmountRange(MinAmount: Decimal; MaxAmount: Decimal; TransactionDate: Date; RangeFilter: Text; UsePaymentDiscounts: Boolean): Integer
    var
        NoOfEntreis: Integer;
    begin
        SetFilter("Remaining Amount", RangeFilter, MinAmount, MaxAmount);
        SetFilter("Pmt. Discount Due Date", '<%1', TransactionDate);
        NoOfEntreis := Count;

        SetRange("Remaining Amount");

        if UsePaymentDiscounts then begin
            SetFilter("Remaining Amt. Incl. Discount", RangeFilter, MinAmount, MaxAmount);
            SetFilter("Pmt. Discount Due Date", '>=%1', TransactionDate);
            NoOfEntreis += Count;
            SetRange("Remaining Amt. Incl. Discount");
        end;

        SetRange("Pmt. Discount Due Date");

        exit(NoOfEntreis);
    end;

    local procedure GetCustomerLedgerEntryDiscountDueDate(CustLedgerEntry: Record "Cust. Ledger Entry"): Date
    begin
        if CustLedgerEntry."Remaining Pmt. Disc. Possible" = 0 then
            exit(0D);

        if CustLedgerEntry."Pmt. Disc. Tolerance Date" >= CustLedgerEntry."Pmt. Discount Date" then
            exit(CustLedgerEntry."Pmt. Disc. Tolerance Date");

        exit(CustLedgerEntry."Pmt. Discount Date");
    end;

    local procedure GetVendorLedgerEntryDiscountDueDate(VendorLedgerEntry: Record "Vendor Ledger Entry"): Date
    begin
        if VendorLedgerEntry."Remaining Pmt. Disc. Possible" = 0 then
            exit(0D);

        if VendorLedgerEntry."Pmt. Disc. Tolerance Date" >= VendorLedgerEntry."Pmt. Discount Date" then
            exit(VendorLedgerEntry."Pmt. Disc. Tolerance Date");

        exit(VendorLedgerEntry."Pmt. Discount Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromCustomerLedgerEntry(var LedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromVendorLedgerEntry(var LedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromBankAccountLedgerEntry(var LedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;
}

