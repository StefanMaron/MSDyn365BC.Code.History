page 5239 "Empl. Ledger Entries Preview"
{
    Caption = 'Employee Entries Preview';
    DataCaptionFields = "Employee No.";
    Editable = false;
    PageType = List;
    SourceTable = "Employee Ledger Entry";
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
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the document type that the employee entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee entry''s document number.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of the employee that the entry is linked to.';
                }
                field("Message to Recipient"; "Message to Recipient")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the message exported to the payment file when you use the Export Payments to File function in the Payment Journal window.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description of the employee entry.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment method that was used to make the payment that resulted in the entry.';
                }
                field(OriginalAmountFCY; OriginalAmountFCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Original Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the employee ledger entry before you post.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(2);
                    end;
                }
                field(OriginalAmountLCY; OriginalAmountLCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Original Amount (LCY)';
                    Editable = false;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(2);
                    end;
                }
                field(AmountFCY; AmountFCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the employee entry.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(0);
                    end;
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount, in local currency, relating to the employee ledger entry';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(0);
                    end;
                }
                field(RemainingAmountFCY; RemainingAmountFCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount on the employee ledger entry before you post.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(1);
                    end;
                }
                field(RemainingAmountLCY; RemainingAmountLCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Remaining Amount (LCY)';
                    Editable = false;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(1);
                    end;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the type of balancing account that is used for the entry.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the number of the balancing account that is used for the entry.';
                    Visible = false;
                }
                field(Open; Open)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
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
                        GenJnlPostPreview.ShowDimensions(DATABASE::"Employee Ledger Entry", "Entry No.", "Dimension Set ID");
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
        CalcAmounts(AmountFCY, AmountLCY, RemainingAmountFCY, RemainingAmountLCY, OriginalAmountFCY, OriginalAmountLCY);
    end;

    var
        TempDetailedEmplLedgEntry: Record "Detailed Employee Ledger Entry" temporary;
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        AmountFCY: Decimal;
        AmountLCY: Decimal;
        RemainingAmountFCY: Decimal;
        RemainingAmountLCY: Decimal;
        OriginalAmountLCY: Decimal;
        OriginalAmountFCY: Decimal;

    procedure Set(var TempEmplLedgerEntry: Record "Employee Ledger Entry" temporary; var TempDetailedEmplLedgEntry2: Record "Detailed Employee Ledger Entry" temporary)
    begin
        if TempEmplLedgerEntry.FindSet then
            repeat
                Rec := TempEmplLedgerEntry;
                Insert;
            until TempEmplLedgerEntry.Next = 0;

        if TempDetailedEmplLedgEntry2.FindSet then
            repeat
                TempDetailedEmplLedgEntry := TempDetailedEmplLedgEntry2;
                TempDetailedEmplLedgEntry.Insert();
            until TempDetailedEmplLedgEntry2.Next = 0;
    end;

    local procedure CalcAmounts(var AmountFCY: Decimal; var AmountLCY: Decimal; var RemainingAmountFCY: Decimal; var RemainingAmountLCY: Decimal; var OriginalAmountFCY: Decimal; var OriginalAmountLCY: Decimal)
    begin
        AmountFCY := 0;
        AmountLCY := 0;
        RemainingAmountLCY := 0;
        RemainingAmountFCY := 0;
        OriginalAmountLCY := 0;
        OriginalAmountFCY := 0;

        TempDetailedEmplLedgEntry.SetRange("Employee Ledger Entry No.", "Entry No.");
        if TempDetailedEmplLedgEntry.FindSet then
            repeat
                if TempDetailedEmplLedgEntry."Entry Type" = TempDetailedEmplLedgEntry."Entry Type"::"Initial Entry" then begin
                    OriginalAmountFCY += TempDetailedEmplLedgEntry.Amount;
                    OriginalAmountLCY += TempDetailedEmplLedgEntry."Amount (LCY)";
                end;
                if not (TempDetailedEmplLedgEntry."Entry Type" = TempDetailedEmplLedgEntry."Entry Type"::Application)
                then begin
                    AmountFCY += TempDetailedEmplLedgEntry.Amount;
                    AmountLCY += TempDetailedEmplLedgEntry."Amount (LCY)";
                end;
                RemainingAmountFCY += TempDetailedEmplLedgEntry.Amount;
                RemainingAmountLCY += TempDetailedEmplLedgEntry."Amount (LCY)";
            until TempDetailedEmplLedgEntry.Next = 0;
    end;

    local procedure DrilldownAmounts(AmountType: Option Amount,"Remaining Amount","Original Amount")
    var
        DetailedEmplEntriesPreview: Page "Detailed Empl. Entries Preview";
    begin
        case AmountType of
            AmountType::Amount:
                TempDetailedEmplLedgEntry.SetFilter("Entry Type", '<>%1',
                  TempDetailedEmplLedgEntry."Entry Type"::Application);
            AmountType::"Original Amount":
                TempDetailedEmplLedgEntry.SetRange("Entry Type", TempDetailedEmplLedgEntry."Entry Type"::"Initial Entry");
            AmountType::"Remaining Amount":
                TempDetailedEmplLedgEntry.SetRange("Entry Type");
        end;
        DetailedEmplEntriesPreview.Set(TempDetailedEmplLedgEntry);
        DetailedEmplEntriesPreview.RunModal;
        Clear(DetailedEmplEntriesPreview);
    end;
}

