page 17243 "Tax Customer Ledger Entries"
{
    Caption = 'Tax Customer Ledger Entries';
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Cust. Ledger Entry";

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
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer related to this entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
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
                field("Salesperson Code"; "Salesperson Code")
                {
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';
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
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the ledger entry.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be paid.';
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
                        ShowDimensions;
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Cust. Ledg. Entries";
                    RunPageLink = "Cust. Ledger Entry No." = FIELD("Entry No."),
                                  "Customer No." = FIELD("Customer No.");
                    RunPageView = SORTING("Cust. Ledger Entry No.", "Posting Date");
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
                    RunObject = Page "Applied Customer Entries";
                    RunPageOnRec = true;
                }
                action("Apply Entries")
                {
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    RunObject = Page "Apply Customer Entries";
                    RunPageLink = "Customer No." = FIELD("Customer No."),
                                  Open = CONST(true);
                    RunPageView = SORTING("Customer No.", Open);
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
                Caption = '&Navigate';
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

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not UseTmpCustLedgerEntry then
            exit(Find(Which));
        TmpCustLedgerEntry.Copy(Rec);
        ResultFind := TmpCustLedgerEntry.Find(Which);
        if ResultFind then
            Rec := TmpCustLedgerEntry;
        exit(ResultFind);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if not UseTmpCustLedgerEntry then
            exit(Next(Steps));
        TmpCustLedgerEntry := Rec;
        ResultNext := TmpCustLedgerEntry.Next(Steps);
        if ResultNext <> 0 then
            Rec := TmpCustLedgerEntry;
        exit(ResultNext);
    end;

    var
        TmpCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        Navigate: Page Navigate;
        UseTmpCustLedgerEntry: Boolean;
        ResultFind: Boolean;
        ResultNext: Integer;

    [Scope('OnPrem')]
    procedure BuildTmpCustLedgerEntry(CustNo: Code[20]; DateBegin: Date; DateEnd: Date; DueFilter: Text[30]; PositiveEntry: Boolean)
    begin
        Reset;
        SetCurrentKey("Customer No.", "Posting Date");
        SetRange("Customer No.", CustNo);
        SetRange("Posting Date", DateBegin, DateEnd);
        SetRange(Positive, PositiveEntry);
        if FindSet then
            repeat
                TmpCustLedgerEntry := Rec;
                TmpCustLedgerEntry.Insert();
            until Next = 0;

        Reset;
        SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        SetRange("Customer No.", CustNo);
        SetRange(Positive, PositiveEntry);
        SetFilter("Due Date", DueFilter);
        SetFilter("Date Filter", '..%1', DateBegin - 1);
        if FindSet then
            repeat
                CalcFields("Remaining Amt. (LCY)");
                if "Remaining Amt. (LCY)" <> 0 then begin
                    TmpCustLedgerEntry := Rec;
                    if TmpCustLedgerEntry.Insert() then;
                end;
            until Next = 0;

        Reset;
        SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        SetRange("Customer No.", CustNo);
        SetRange(Positive, PositiveEntry);
        SetFilter("Due Date", DueFilter);
        SetFilter("Date Filter", '..%1', DateEnd);
        if FindSet then
            repeat
                CalcFields("Remaining Amt. (LCY)");
                if "Remaining Amt. (LCY)" <> 0 then begin
                    TmpCustLedgerEntry := Rec;
                    if TmpCustLedgerEntry.Insert() then;
                end;
            until Next = 0;
        Reset;
        SetFilter("Date Filter", DueFilter);
        UseTmpCustLedgerEntry := true;
    end;
}

