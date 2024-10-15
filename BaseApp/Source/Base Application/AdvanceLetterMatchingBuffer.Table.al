table 31035 "Advance Letter Matching Buffer"
{
    Caption = 'Advance Letter Matching Buffer';
#if not CLEAN19
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(2; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Customer,Vendor';
            OptionMembers = Customer,Vendor;
        }
        field(6; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
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
        field(15; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(20; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(25; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
        field(26; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
        field(27; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Letter Type", "Letter No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN19

    [Scope('OnPrem')]
    procedure InsertFromSalesAdvanceLetterHeader(SalesAdvanceLetterHdr: Record "Sales Advance Letter Header"; UseLCYAmounts: Boolean)
    begin
        Clear(Rec);
        "Letter Type" := "Letter Type"::Sales;
        "Letter No." := SalesAdvanceLetterHdr."No.";
        "Account Type" := "Account Type"::Customer;
        "Account No." := SalesAdvanceLetterHdr."Bill-to Customer No.";
        "Due Date" := SalesAdvanceLetterHdr."Advance Due Date";
        "Posting Date" := SalesAdvanceLetterHdr."Posting Date";

        if UseLCYAmounts then
            "Remaining Amount" := SalesAdvanceLetterHdr.GetRemAmountLCY()
        else
            "Remaining Amount" := SalesAdvanceLetterHdr.GetRemAmount();

        "External Document No." := SalesAdvanceLetterHdr."External Document No.";
        "Specific Symbol" := SalesAdvanceLetterHdr."Specific Symbol";
        "Variable Symbol" := SalesAdvanceLetterHdr."Variable Symbol";
        "Constant Symbol" := SalesAdvanceLetterHdr."Constant Symbol";

        Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertFromPurchaseAdvanceLetterHeader(PurchAdvanceLetterHdr: Record "Purch. Advance Letter Header"; UseLCYAmounts: Boolean)
    begin
        Clear(Rec);
        "Letter Type" := "Letter Type"::Purchase;
        "Letter No." := PurchAdvanceLetterHdr."No.";
        "Account Type" := "Account Type"::Vendor;
        "Account No." := PurchAdvanceLetterHdr."Pay-to Vendor No.";
        "Due Date" := PurchAdvanceLetterHdr."Advance Due Date";
        "Posting Date" := PurchAdvanceLetterHdr."Posting Date";

        if UseLCYAmounts then
            "Remaining Amount" := -PurchAdvanceLetterHdr.GetRemAmountLCY()
        else
            "Remaining Amount" := -PurchAdvanceLetterHdr.GetRemAmount();

        "External Document No." := PurchAdvanceLetterHdr."External Document No.";
        "Specific Symbol" := PurchAdvanceLetterHdr."Specific Symbol";
        "Variable Symbol" := PurchAdvanceLetterHdr."Variable Symbol";
        "Constant Symbol" := PurchAdvanceLetterHdr."Constant Symbol";

        Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetNoOfAdvanceLettersWithinRange(MinAmount: Decimal; MaxAmount: Decimal): Integer
    begin
        exit(GetNoOfAdvanceLettersInAmountRange(MinAmount, MaxAmount, '>=%1&<=%2'));
    end;

    local procedure GetNoOfAdvanceLettersInAmountRange(MinAmount: Decimal; MaxAmount: Decimal; RangeFilter: Text): Integer
    var
        NoOfEntreis: Integer;
    begin
        SetFilter("Remaining Amount", RangeFilter, MinAmount, MaxAmount);
        NoOfEntreis := Count;
        SetRange("Remaining Amount");
        exit(NoOfEntreis);
    end;
#endif
}

