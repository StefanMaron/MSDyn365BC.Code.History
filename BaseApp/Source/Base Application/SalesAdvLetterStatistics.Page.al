#if not CLEAN19
page 31004 "Sales Adv. Letter Statistics"
{
    Caption = 'Sales Adv. Letter Statistics (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Sales Advance Letter Header";
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
                field("SalesAdvanceLetterLineGre.Amount"; SalesAdvanceLetterLineGre.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the document.';
                }
                field("SalesAdvanceLetterLineGre.""VAT Amount"""; SalesAdvanceLetterLineGre."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the vat amount';
                }
                field("SalesAdvanceLetterLineGre.""Amount Including VAT"""; SalesAdvanceLetterLineGre."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total of the amounts in all the amount fields on the sales lines with a specific VAT Identifier. The amount includes VAT.';
                }
                field(AmountInclVATLCY; AmountInclVATLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total of the amounts in all the amount fields on the sales lines with a specific VAT Identifier. The amount includes VAT, the amount is in the local currency.';
                }
                field("SalesAdvanceLetterLineGre.""Amount To Link"""; SalesAdvanceLetterLineGre."Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount To Receive';
                    Editable = false;
                    ToolTip = 'Specifies the amount to recive';
                }
                field("SalesAdvanceLetterLineGre.""Amount Linked"""; SalesAdvanceLetterLineGre."Amount Linked")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Received';
                    Editable = false;
                    ToolTip = 'Specifies recived amount';
                }
                field("SalesAdvanceLetterLineGre.""Amount Linked To Journal Line"""; SalesAdvanceLetterLineGre."Amount Linked To Journal Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amt. Reserved For Jnl. Line';
                    Editable = false;
                    ToolTip = 'Specifies amt. reserved for jnl. Line';
                }
                field("SalesAdvanceLetterLineGre.""Amount To Invoice"""; SalesAdvanceLetterLineGre."Amount To Invoice")
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
                    ToolTip = 'Specifies vat amount to invoice of purch. adv. letter statistics';
                }
                field("SalesAdvanceLetterLineGre.""Amount Invoiced"""; SalesAdvanceLetterLineGre."Amount Invoiced")
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
                    ToolTip = 'Specifies invoiced vat amount of purch. adv. letter statistics';
                }
                field("SalesAdvanceLetterLineGre.""Amount To Deduct"""; SalesAdvanceLetterLineGre."Amount To Deduct")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount To Deduct';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was used in final sales invoice.';
                }
                field("SalesAdvanceLetterLineGre.""Amount Deducted"""; SalesAdvanceLetterLineGre."Amount Deducted")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Deducted';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was used in final sales invoice.';
                }
            }
            part(SubForm; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        UseDate: Date;
    begin
        if PrevNo = "No." then
            exit;
        PrevNo := "No.";
        FilterGroup(2);
        SetRange("No.", PrevNo);
        FilterGroup(0);

        Clear(SalesAdvanceLetterLineGre);
        SalesAdvanceLetterLine.CalcVATAmountLines(Rec, TempVATAmountLine1, SalesAdvanceLetterLineGre, TotalVATToInvoice, TotalVATInvoiced);

        if "Posting Date" = 0D then
            UseDate := WorkDate()
        else
            UseDate := "Posting Date";

        AmountInclVATLCY :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            UseDate, "Currency Code", SalesAdvanceLetterLineGre."Amount Including VAT", "Currency Factor");

        SubformIsReady := true;
        SetVATSpecification();
    end;

    trigger OnOpenPage()
    begin
        SalesSetup.Get();
        AllowVATDifference := false;
        SubformIsEditable := AllowVATDifference;
        CurrPage.Editable := SubformIsEditable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification();
        if TempVATAmountLine1.GetAnyLineModified() then
            UpdateVATOnSalesLines();
        exit(true);
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        SalesAdvanceLetterLineGre: Record "Sales Advance Letter Line";
        CurrExchRate: Record "Currency Exchange Rate";
        TotalVATToInvoice: Decimal;
        TotalVATInvoiced: Decimal;
        SubformIsReady: Boolean;
        SubformIsEditable: Boolean;
        AllowVATDifference: Boolean;
        PrevNo: Code[20];
        AmountInclVATLCY: Decimal;

    local procedure UpdateHeaderInfo(var VATAmountLine: Record "VAT Amount Line")
    begin
        SalesAdvanceLetterLineGre."VAT Amount" := VATAmountLine.GetTotalVATAmount();
        SalesAdvanceLetterLineGre."Amount Including VAT" := VATAmountLine.GetTotalAmountInclVAT();
    end;

    local procedure GetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.GetTempVATAmountLine(TempVATAmountLine1);
        UpdateHeaderInfo(TempVATAmountLine1);
    end;

    local procedure SetVATSpecification()
    begin
        if not SubformIsReady then
            exit;
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine1);
        CurrPage.SubForm.PAGE.InitGlobals("Currency Code", AllowVATDifference, true, true, false, 0);
    end;

    local procedure UpdateVATOnSalesLines()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        GetVATSpecification();
        if TempVATAmountLine1.GetAnyLineModified() then
            SalesAdvanceLetterLine.UpdateVATOnLines(Rec, SalesAdvanceLetterLine, TempVATAmountLine1);
        PrevNo := '';
    end;
}
#endif
