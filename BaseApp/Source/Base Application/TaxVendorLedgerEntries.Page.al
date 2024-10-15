page 17244 "Tax Vendor Ledger Entries"
{
    Caption = 'Tax Vendor Ledger Entries';
    DataCaptionFields = "Vendor No.";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor that is associated with the person.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Original Amt. (LCY)"; "Original Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Amount)
                {
                    ToolTip = 'Specifies the amount.';
                    Visible = false;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the ledger entry.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ToolTip = 'Specifies the amount that remains to be paid.';
                    Visible = false;
                }
                field("Remaining Amt. (LCY)"; "Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be paid, expressed in LCY.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Pmt. Disc. Tolerance Date"; "Pmt. Disc. Tolerance Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest date the amount in the entry must be paid in order for payment discount tolerance to be granted.';
                }
                field("Original Pmt. Disc. Possible"; "Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Remaining Pmt. Disc. Possible"; "Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining payment discount which can be received if the payment is made before the payment discount date.';
                }
                field("Max. Payment Tolerance"; "Max. Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("On Hold"; "On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                }
                field("User ID"; "User ID")
                {
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Vendor Ledg. Entries";
                    RunPageLink = "Vendor Ledger Entry No." = FIELD("Entry No."),
                                  "Vendor No." = FIELD("Vendor No.");
                    RunPageView = SORTING("Vendor Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunObject = Page "Applied Vendor Entries";
                    RunPageOnRec = true;
                }
                action("Apply Entries")
                {
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    RunObject = Page "Apply Vendor Entries";
                    RunPageLink = "Vendor No." = FIELD("Vendor No."),
                                  Open = CONST(true);
                    RunPageView = SORTING("Vendor No.", Open);
                    ShortCutKey = 'Shift+F11';
                    Visible = false;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoOnFormat;
        VendorNoOnFormat;
        DescriptionOnFormat;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not UseTmpVendLedgerEntry then
            exit(Find(Which));
        TmpVendLedgerEntry.Copy(Rec);
        ResultFind := TmpVendLedgerEntry.Find(Which);
        if ResultFind then
            Rec := TmpVendLedgerEntry;
        exit(ResultFind);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if not UseTmpVendLedgerEntry then
            exit(Next(Steps));
        TmpVendLedgerEntry := Rec;
        ResultNext := TmpVendLedgerEntry.Next(Steps);
        if ResultNext <> 0 then
            Rec := TmpVendLedgerEntry;
        exit(ResultNext);
    end;

    var
        TmpVendLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Navigate: Page Navigate;
        UseTmpVendLedgerEntry: Boolean;
        ResultFind: Boolean;
        ResultNext: Integer;

    [Scope('OnPrem')]
    procedure BuildTmpVendLedgerEntry(VendNo: Code[20]; DateBegin: Date; DateEnd: Date; DueFilter: Text[30]; PositiveEntry: Boolean)
    begin
        Reset;
        SetCurrentKey("Vendor No.", "Posting Date");
        SetRange("Vendor No.", VendNo);
        SetRange("Posting Date", DateBegin, DateEnd);
        SetRange(Positive, PositiveEntry);
        if FindSet then
            repeat
                TmpVendLedgerEntry := Rec;
                TmpVendLedgerEntry.Insert();
            until Next = 0;

        Reset;
        SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        SetRange("Vendor No.", VendNo);
        SetRange(Positive, PositiveEntry);
        SetFilter("Due Date", DueFilter);
        SetFilter("Date Filter", '..%1', DateBegin - 1);
        if FindSet then
            repeat
                CalcFields("Remaining Amt. (LCY)");
                if "Remaining Amt. (LCY)" <> 0 then begin
                    TmpVendLedgerEntry := Rec;
                    if TmpVendLedgerEntry.Insert() then;
                end;
            until Next = 0;

        Reset;
        SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        SetRange("Vendor No.", VendNo);
        SetRange(Positive, PositiveEntry);
        SetFilter("Due Date", DueFilter);
        SetFilter("Date Filter", '..%1', DateEnd);
        if FindSet then
            repeat
                CalcFields("Remaining Amt. (LCY)");
                if "Remaining Amt. (LCY)" <> 0 then begin
                    TmpVendLedgerEntry := Rec;
                    if TmpVendLedgerEntry.Insert() then;
                end;
            until Next = 0;
        Reset;
        SetFilter("Date Filter", DueFilter);
        UseTmpVendLedgerEntry := true;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if Open = true then begin
            CalcFields(Amount);
            if Amount < 0 then;
        end;
    end;

    local procedure VendorNoOnFormat()
    begin
        if Open = true then begin
            CalcFields(Amount);
            if Amount < 0 then;
        end;
    end;

    local procedure DescriptionOnFormat()
    begin
        if Open = true then begin
            CalcFields(Amount);
            if Amount < 0 then;
        end;
    end;
}

