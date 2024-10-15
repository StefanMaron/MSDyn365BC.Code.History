#if not CLEAN19
page 31024 "Purch. Adv. Letter Statistics"
{
    Caption = 'Purch. Adv. Letter Statistics (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Purch. Advance Letter Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ctrAmountGeneral; PurchAdvanceLetterLineGre.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the document.';
                }
                field("PurchAdvanceLetterLineGre.""VAT Amount"""; PurchAdvanceLetterLineGre."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the vat amount';
                }
                field("PurchAdvanceLetterLineGre.""Amount Including VAT"""; PurchAdvanceLetterLineGre."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total of the amounts in all the amount fields on the purchase lines with a specific VAT Identifier. The amount includes VAT.';
                }
                field(AmountInclVATLCY; AmountInclVATLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total of the amounts in all the amount fields on the purchase lines with a specific VAT Identifier. The amount includes VAT, the amount is in the local currency.';
                }
                field("PurchAdvanceLetterLineGre.""Amount To Link"""; PurchAdvanceLetterLineGre."Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount To Receive';
                    Editable = false;
                    ToolTip = 'Specifies the amount to recive';
                }
                field("PurchAdvanceLetterLineGre.""Amount Linked"""; PurchAdvanceLetterLineGre."Amount Linked")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Received';
                    Editable = false;
                    ToolTip = 'Specifies recived amount';
                }
                field("PurchAdvanceLetterLineGre.""Amount Linked To Journal Line"""; PurchAdvanceLetterLineGre."Amount Linked To Journal Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amt. Reserved For Jnl. Line';
                    Editable = false;
                    ToolTip = 'Specifies amt. reserved for jnl. Line';
                }
                field("PurchAdvanceLetterLineGre.""Amount To Invoice"""; PurchAdvanceLetterLineGre."Amount To Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount To Invoice';
                    Editable = false;
                    ToolTip = 'Specifies the amount with advance VAT document.';
                }
                field(TotalVATToInvoice; TotalVATToInvoice)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount To Invoice';
                    Editable = false;
                    ToolTip = 'Specifies vat amount to invoice of sales adv. letter statistics';
                }
                field("PurchAdvanceLetterLineGre.""Amount Invoiced"""; PurchAdvanceLetterLineGre."Amount Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Invoiced';
                    Editable = false;
                    ToolTip = 'Specifies the amount with advance VAT document.';
                }
                field(TotalVATInvoiced; TotalVATInvoiced)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount Invoiced';
                    Editable = false;
                    ToolTip = 'Specifies invoiced vat amount of sales adv. letter statistics';
                }
                field("PurchAdvanceLetterLineGre.""Amount To Deduct"""; PurchAdvanceLetterLineGre."Amount To Deduct")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount To Deduct';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was used in final sales invoice.';
                }
                field("PurchAdvanceLetterLineGre.""Amount Deducted"""; PurchAdvanceLetterLineGre."Amount Deducted")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Deducted';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was used in final sales invoice.';
                }
                field("TempVATAmountLine1.COUNT"; TempVATAmountLine1.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of VAT lines.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(1, TempVATAmountLine1);
                    end;
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field(InvoiceAmount; PurchAdvanceLetterLineGre2."Amount Including VAT" - PurchAdvanceLetterLineGre2."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the document.';
                }
                field(InvoiceVATAmount; PurchAdvanceLetterLineGre2."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the vat amount';
                }
                field(InvoiceAmountIncludingVAT; PurchAdvanceLetterLineGre2."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total of the amounts in all the amount fields on the purchase lines with a specific VAT Identifier. The amount includes VAT.';
                }
                field("AmtIclVATLCY - VATAmtLCY"; AmtIclVATLCY - VATAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Base (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies vat base in LCY of purchase adv. Letter';
                }
                field(VATAmtLCY; VATAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the vat amount in LCY';
                }
                field(AmtIclVATLCY; AmtIclVATLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total of the amounts in all the amount fields on the purchase lines with a specific VAT Identifier. The amount includes VAT, the amount is in the local currency.';
                }
                field("TempVATAmountLine2.COUNT"; TempVATAmountLine2.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of VAT lines.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(2, TempVATAmountLine2);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
        UseDate: Date;
    begin
        if PrevNo = "No." then
            exit;
        PrevNo := "No.";
        FilterGroup(2);
        SetRange("No.", PrevNo);
        FilterGroup(0);

        Clear(PurchAdvanceLetterLineGre);
        PurchAdvanceLetterLine.CalcVATAmountLines(Rec, TempVATAmountLine1, PurchAdvanceLetterLineGre, TotalVATToInvoice, TotalVATInvoiced);

        Clear(PurchAdvanceLetterLineGre2);

        if "Posting Date" = 0D then
            UseDate := WorkDate()
        else
            UseDate := "Posting Date";

        AmountInclVATLCY :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            UseDate, "Currency Code", PurchAdvanceLetterLineGre."Amount Including VAT", "Currency Factor");

        PurchAdvanceLetterLine.InitVATLinesToInv(Rec, TempPurchAdvanceLetterLine);
        PurchAdvanceLetterLine.CalcVATAmountLines2(
          Rec, TempVATAmountLine2, PurchAdvanceLetterLineGre2, TotalVATToInvoice2, TotalVATInvoiced2, TempPurchAdvanceLetterLine);
        TempVATAmountLine1.ModifyAll(Modified, false);
        TempVATAmountLine2.ModifyAll(Modified, false);

        UpdateHeaderInfo(TempVATAmountLine1, TempVATAmountLine2);
    end;

    trigger OnOpenPage()
    begin
        PurchSetup.Get();
        AllowVATDifference := PurchSetup."Allow VAT Difference";
        SubformIsEditable := AllowVATDifference;
        CurrPage.Editable := SubformIsEditable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification();
        if TempVATAmountLine1.GetAnyLineModified() or TempVATAmountLine2.GetAnyLineModified() then
            UpdateVATOnPurchLines();
        exit(true);
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        PurchAdvanceLetterLineGre: Record "Purch. Advance Letter Line";
        TempVATAmountLine2: Record "VAT Amount Line" temporary;
        PurchAdvanceLetterLineGre2: Record "Purch. Advance Letter Line" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        VATAmountLines: Page "VAT Amount Lines";
        VATAmountLines2: Page "VAT Amount Lines";
        TotalVATToInvoice: Decimal;
        TotalVATInvoiced: Decimal;
        SubformIsEditable: Boolean;
        AllowVATDifference: Boolean;
        PrevNo: Code[20];
        TotalVATToInvoice2: Decimal;
        TotalVATInvoiced2: Decimal;
        VATAmtLCY: Decimal;
        AmtIclVATLCY: Decimal;
        AmountInclVATLCY: Decimal;

    local procedure UpdateHeaderInfo(var VATAmountLine: Record "VAT Amount Line"; var VATAmountLineInv: Record "VAT Amount Line")
    var
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
    begin
        PurchAdvanceLetterLineGre."VAT Amount" := VATAmountLine.GetTotalVATAmount();
        PurchAdvanceLetterLineGre."Amount Including VAT" := VATAmountLine.GetTotalAmountInclVAT();

        PurchAdvanceLetterLineGre2."VAT Amount" := VATAmountLineInv.GetTotalVATAmount();
        PurchAdvanceLetterLineGre2."Amount Including VAT" := VATAmountLineInv.GetTotalAmountInclVAT();

        Clear(VATAmtLCY);
        Clear(AmtIclVATLCY);
        if VATAmountLineInv.Find('-') then begin
            repeat
                VALVATBaseLCY := VATAmountLine.GetBaseLCY(Rec."Posting Date", Rec."Currency Code", Rec."Currency Factor");
                VALVATAmountLCY := VATAmountLine.GetAmountLCY(Rec."Posting Date", Rec."Currency Code", Rec."Currency Factor");
                VATAmtLCY := VATAmtLCY + VALVATAmountLCY;
                AmtIclVATLCY := AmtIclVATLCY + VALVATBaseLCY + VALVATAmountLCY;
            until VATAmountLineInv.Next() = 0;
        end;
    end;

    local procedure GetVATSpecification()
    begin
        VATAmountLines.GetTempVATAmountLine(TempVATAmountLine1);
        VATAmountLines2.GetTempVATAmountLine(TempVATAmountLine2);
        if TempVATAmountLine1.GetAnyLineModified() or TempVATAmountLine2.GetAnyLineModified() then
            UpdateHeaderInfo(TempVATAmountLine1, TempVATAmountLine2);
    end;

    local procedure UpdateVATOnPurchLines()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        GetVATSpecification();
        if TempVATAmountLine1.GetAnyLineModified() then
            PurchAdvanceLetterLine.UpdateVATOnLines(Rec, PurchAdvanceLetterLine, TempVATAmountLine1);
        if TempVATAmountLine2.GetAnyLineModified() then
            PurchAdvanceLetterLine.UpdateVATOnLineInv(Rec, PurchAdvanceLetterLine, TempVATAmountLine2);

        PrevNo := '';
    end;

    [Scope('OnPrem')]
    procedure VATLinesDrillDown(TabIndex: Integer; var VATAmountLine: Record "VAT Amount Line")
    begin
        case TabIndex of
            1:
                begin
                    Clear(VATAmountLines);
                    VATAmountLines.SetTempVATAmountLine(VATAmountLine);
                    VATAmountLines.InitGlobals("Currency Code", AllowVATDifference, false, true, false, 0);
                    VATAmountLines.RunModal();
                    VATAmountLines.GetTempVATAmountLine(VATAmountLine);
                end;
            2:
                begin
                    Clear(VATAmountLines2);
                    VATAmountLines2.SetTempVATAmountLine(VATAmountLine);
                    VATAmountLines2.InitGlobals("Currency Code", AllowVATDifference, AllowVATDifference, true, false, 0);
                    VATAmountLines2.RunModal();
                    VATAmountLines2.GetTempVATAmountLine(VATAmountLine);
                end;
        end;
        UpdateHeaderInfo(TempVATAmountLine1, TempVATAmountLine2);
    end;
}
#endif