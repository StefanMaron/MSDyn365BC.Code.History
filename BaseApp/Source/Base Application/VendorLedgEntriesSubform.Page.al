page 31056 "Vendor Ledg. Entries Subform"
{
    Caption = 'Vendor Ledger Entries';
    DataCaptionFields = "Vendor No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Vendor Ledger Entry";
    SourceTableView = SORTING(Open, "Due Date")
                      WHERE(Open = CONST(true));
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220037)
            {
                Editable = false;
                ShowCaption = false;
                field(MARK; Mark)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark';
                    Editable = false;
                    ToolTip = 'Specifies the funkction allows to mark the selected entries.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document type that the vendor entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor entry''s document number.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of vendor''s document.';
                    Visible = false;
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of vendor.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the customer entry.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code associated with the vendor ledger entries.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code associated with the vendor ledger entries.';
                    Visible = false;
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason code on the entry.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original entry.';
                }
                field("Original Amt. (LCY)"; "Original Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount that the entry originally consisted of, in LCY.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry. The amount is shown in the currency of the original transaction.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount after doing credit process.';
                }
                field("Remaining Amt. (LCY)"; "Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to. The amount is shown in LCY.';
                    Visible = false;
                }
                field("Amount on Payment Order (LCY)"; "Amount on Payment Order (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount on payment order.';
                    Visible = false;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of balancing account used on the entry.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the balancing account number used on the entry.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date on the entry.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment discount date.';
                }
                field("Pmt. Disc. Tolerance Date"; "Pmt. Disc. Tolerance Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the amount in the entry must be paid in order for a payment discount tolerance to be granted on the document.';
                }
                field("Original Pmt. Disc. Possible"; "Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount that the customer can obtain if the entry is applied to before the payment discount date. The contents of this field can not be adjusted after the entry is posted.';
                }
                field("Remaining Pmt. Disc. Possible"; "Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining payment discount that is available if the entry is totally applied to within the payment period.';
                }
                field("Max. Payment Tolerance"; "Max. Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum tolerated amount that the amount in the entry can differ from the amount on the invoice or credit memo.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if vendor ledg. Entry is open';
                }
                field("On Hold"; "On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the posted document will be included in the payment suggestion.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the source code that is linked to the entry.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason code on the entry.';
                    Visible = false;
                }
                field("Bank Account Code"; "Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account code for payment order.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                }
                field("Constant Symbol"; "Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    TableRelation = "Constant Symbol";
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Specific Symbol"; "Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the detail information for advance payment.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Mark)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark';
                ShortCutKey = 'Ctrl+F1';
                ToolTip = 'The funkction allows to mark the selected entries.';

                trigger OnAction()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    VendLedgEntry2: Record "Vendor Ledger Entry";
                begin
                    VendLedgEntry2 := Rec;
                    CurrPage.SetSelectionFilter(VendLedgEntry);
                    if VendLedgEntry.FindSet then
                        repeat
                            Rec := VendLedgEntry;
                            Mark := not Mark;
                        until VendLedgEntry.Next() = 0;
                    Rec := VendLedgEntry2;
                end;
            }
            action("Marked only")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Marked only';
                ToolTip = 'Specifies only the marked vendor ledger entries.';

                trigger OnAction()
                begin
                    MarkedOnly := not MarkedOnly;
                end;
            }
        }
    }

    [Scope('OnPrem')]
    procedure GetBalance() ValueBalance: Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        Clear(ValueBalance);
        VendLedgEntry.Copy(Rec);
        VendLedgEntry.MarkedOnly(true);
        if VendLedgEntry.FindSet then
            repeat
                VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
                ValueBalance += VendLedgEntry."Remaining Amt. (LCY)";
            until VendLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetEntries(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry.Copy(Rec);
        VendLedgEntry.MarkedOnly(true);
    end;

    [Scope('OnPrem')]
    procedure ApplyFilters(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        Reset;
        CopyFilters(VendLedgEntry);
        SetCurrentKey("Vendor No.", Open);
        SetRange(Open, true);
        CurrPage.Update(false);
    end;
}

