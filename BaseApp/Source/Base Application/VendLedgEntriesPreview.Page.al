page 128 "Vend. Ledg. Entries Preview"
{
    Caption = 'Vendor Entries Preview';
    DataCaptionFields = "Vendor No.";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Ledger Entry";
    SourceTableTemporary = true;

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
                    Editable = false;
                    ToolTip = 'Specifies the vendor entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the document type that the vendor entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the vendor entry''s document number.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the vendor account that the entry is linked to.';
                }
                field("Message to Recipient"; "Message to Recipient")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the message exported to the payment file when you use the Export Payments to File function in the Payment Journal window.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the vendor entry.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                    Visible = false;
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Payment Reference"; "Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment of the purchase invoice.';
                }
                field("Creditor No."; "Creditor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor who sent the purchase invoice.';
                }
                field(OriginalAmountFCY; OriginalAmountFCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the vendor ledger entry before you post.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(2);
                    end;
                }
                field(OriginalAmountLCY; OriginalAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the original amount linked to the vendor ledger entry, in local currency.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(2);
                    end;
                }
                field(AmountFCY; AmountFCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the vendor entry.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(0);
                    end;
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the ledger entry, in the local currency.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(0);
                    end;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Debit Amount (LCY)"; "Debit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Credit Amount (LCY)"; "Credit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
                    Visible = false;
                }
                field(RemainingAmountFCY; RemainingAmountFCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount on the vendor ledger entry before you post.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(1);
                    end;
                }
                field(RemainingAmountLCY; RemainingAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount linked to the vendor ledger entry on the line, in local currency. ';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(1);
                    end;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the due date on the entry.';
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
                    ToolTip = 'Specifies the discount that you can obtain if the entry is applied to before the payment discount date.';
                }
                field("Remaining Pmt. Disc. Possible"; "Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining payment discount which can be received if the payment is made before the payment discount date.';
                }
                field("Max. Payment Tolerance"; "Max. Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum tolerated amount the entry can differ from the amount on the invoice or credit memo.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
                }
                field("On Hold"; "On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                }
                field("Exported to Payment File"; "Exported to Payment File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the entry was created as a result of exporting a payment journal line.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
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
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Ellipsis = true;
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    var
                        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
                    begin
                        GenJnlPostPreview.ShowDimensions(DATABASE::"Vendor Ledger Entry", "Entry No.", "Dimension Set ID");
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleTxt := SetStyle;
        CalcAmounts(AmountFCY, AmountLCY, RemainingAmountFCY, RemainingAmountLCY, OriginalAmountFCY, OriginalAmountLCY);
    end;

    var
        TempDetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        StyleTxt: Text;
        AmountFCY: Decimal;
        AmountLCY: Decimal;
        RemainingAmountFCY: Decimal;
        RemainingAmountLCY: Decimal;
        OriginalAmountLCY: Decimal;
        OriginalAmountFCY: Decimal;

    procedure Set(var TempVendLedgerEntry: Record "Vendor Ledger Entry" temporary; var TempDetailedVendLedgEntry2: Record "Detailed Vendor Ledg. Entry" temporary)
    begin
        if TempVendLedgerEntry.FindSet then
            repeat
                Rec := TempVendLedgerEntry;
                Insert;
            until TempVendLedgerEntry.Next = 0;

        if TempDetailedVendLedgEntry2.FindSet then
            repeat
                TempDetailedVendLedgEntry := TempDetailedVendLedgEntry2;
                TempDetailedVendLedgEntry.Insert();
            until TempDetailedVendLedgEntry2.Next = 0;
    end;

    local procedure CalcAmounts(var AmountFCY: Decimal; var AmountLCY: Decimal; var RemainingAmountFCY: Decimal; var RemainingAmountLCY: Decimal; var OriginalAmountFCY: Decimal; var OriginalAmountLCY: Decimal)
    begin
        AmountFCY := 0;
        AmountLCY := 0;
        RemainingAmountLCY := 0;
        RemainingAmountFCY := 0;
        OriginalAmountLCY := 0;
        OriginalAmountFCY := 0;

        TempDetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", "Entry No.");
        if TempDetailedVendLedgEntry.FindSet then
            repeat
                if TempDetailedVendLedgEntry."Entry Type" = TempDetailedVendLedgEntry."Entry Type"::"Initial Entry" then begin
                    OriginalAmountFCY += TempDetailedVendLedgEntry.Amount;
                    OriginalAmountLCY += TempDetailedVendLedgEntry."Amount (LCY)";
                end;
                if not (TempDetailedVendLedgEntry."Entry Type" in [TempDetailedVendLedgEntry."Entry Type"::Application,
                                                                   TempDetailedVendLedgEntry."Entry Type"::"Appln. Rounding"])
                then begin
                    AmountFCY += TempDetailedVendLedgEntry.Amount;
                    AmountLCY += TempDetailedVendLedgEntry."Amount (LCY)";
                end;
                RemainingAmountFCY += TempDetailedVendLedgEntry.Amount;
                RemainingAmountLCY += TempDetailedVendLedgEntry."Amount (LCY)";
            until TempDetailedVendLedgEntry.Next = 0;
    end;

    local procedure DrilldownAmounts(AmountType: Option Amount,"Remaining Amount","Original Amount")
    var
        DetailedVendEntriesPreview: Page "Detailed Vend. Entries Preview";
    begin
        case AmountType of
            AmountType::Amount:
                TempDetailedVendLedgEntry.SetFilter("Entry Type", '<>%1&<>%2',
                  TempDetailedVendLedgEntry."Entry Type"::Application, TempDetailedVendLedgEntry."Entry Type"::"Appln. Rounding");
            AmountType::"Original Amount":
                TempDetailedVendLedgEntry.SetRange("Entry Type", TempDetailedVendLedgEntry."Entry Type"::"Initial Entry");
            AmountType::"Remaining Amount":
                TempDetailedVendLedgEntry.SetRange("Entry Type");
        end;
        DetailedVendEntriesPreview.Set(TempDetailedVendLedgEntry);
        DetailedVendEntriesPreview.RunModal;
        Clear(DetailedVendEntriesPreview);
    end;
}

