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
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer related to this entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Original Amt. (LCY)"; Rec."Original Amt. (LCY)")
                {
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the ledger entry.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be paid.';
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be paid, expressed in LCY.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Pmt. Disc. Tolerance Date"; Rec."Pmt. Disc. Tolerance Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest date the amount in the entry must be paid in order for payment discount tolerance to be granted.';
                }
                field("Original Pmt. Disc. Possible"; Rec."Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Remaining Pmt. Disc. Possible"; Rec."Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining payment discount which can be received if the payment is made before the payment discount date.';
                }
                field("Max. Payment Tolerance"; Rec."Max. Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
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
                        Rec.ShowDimensions();
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Cust. Ledg. Entries";
                    RunPageLink = "Cust. Ledger Entry No." = field("Entry No."),
                                  "Customer No." = field("Customer No.");
                    RunPageView = sorting("Cust. Ledger Entry No.", "Posting Date");
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
                    RunPageLink = "Customer No." = field("Customer No."),
                                  Open = const(true);
                    RunPageView = sorting("Customer No.", Open);
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
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not UseTmpCustLedgerEntry then
            exit(Rec.Find(Which));
        TmpCustLedgerEntry.Copy(Rec);
        FindResult := TmpCustLedgerEntry.Find(Which);
        if FindResult then
            Rec := TmpCustLedgerEntry;
        exit(FindResult);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if not UseTmpCustLedgerEntry then
            exit(Rec.Next(Steps));
        TmpCustLedgerEntry := Rec;
        NextResult := TmpCustLedgerEntry.Next(Steps);
        if NextResult <> 0 then
            Rec := TmpCustLedgerEntry;
        exit(NextResult);
    end;

    var
        TmpCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        Navigate: Page Navigate;
        UseTmpCustLedgerEntry: Boolean;
        FindResult: Boolean;
        NextResult: Integer;

    [Scope('OnPrem')]
    procedure BuildTmpCustLedgerEntry(CustNo: Code[20]; DateBegin: Date; DateEnd: Date; DueFilter: Text[30]; PositiveEntry: Boolean)
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Customer No.", "Posting Date");
        Rec.SetRange("Customer No.", CustNo);
        Rec.SetRange("Posting Date", DateBegin, DateEnd);
        Rec.SetRange(Positive, PositiveEntry);
        if Rec.FindSet() then
            repeat
                TmpCustLedgerEntry := Rec;
                TmpCustLedgerEntry.Insert();
            until Rec.Next() = 0;

        Rec.Reset();
        Rec.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        Rec.SetRange("Customer No.", CustNo);
        Rec.SetRange(Positive, PositiveEntry);
        Rec.SetFilter("Due Date", DueFilter);
        Rec.SetFilter("Date Filter", '..%1', DateBegin - 1);
        if Rec.FindSet() then
            repeat
                Rec.CalcFields("Remaining Amt. (LCY)");
                if Rec."Remaining Amt. (LCY)" <> 0 then begin
                    TmpCustLedgerEntry := Rec;
                    if TmpCustLedgerEntry.Insert() then;
                end;
            until Rec.Next() = 0;

        Rec.Reset();
        Rec.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        Rec.SetRange("Customer No.", CustNo);
        Rec.SetRange(Positive, PositiveEntry);
        Rec.SetFilter("Due Date", DueFilter);
        Rec.SetFilter("Date Filter", '..%1', DateEnd);
        if Rec.FindSet() then
            repeat
                Rec.CalcFields("Remaining Amt. (LCY)");
                if Rec."Remaining Amt. (LCY)" <> 0 then begin
                    TmpCustLedgerEntry := Rec;
                    if TmpCustLedgerEntry.Insert() then;
                end;
            until Rec.Next() = 0;
        Rec.Reset();
        Rec.SetFilter("Date Filter", DueFilter);
        UseTmpCustLedgerEntry := true;
    end;
}

