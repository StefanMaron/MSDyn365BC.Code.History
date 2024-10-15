page 11734 "Cash Document Statistics"
{
    Caption = 'Cash Document Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Cash Document Line";

    layout
    {
        area(content)
        {
            group(Document)
            {
                Caption = 'Document';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field(AmountExclVAT; AmountExclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Excluding VAT';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is excluding VAT.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'VAT amount';
                    Editable = false;
                    ToolTip = 'Specifies cash document amount.';
                }
                field(AmountInclVAT; AmountInclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is including VAT.';
                }
                field(AmountExclVATLCY; AmountExclVATLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Excluding VAT (LCY)';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is excluding VAT in the local currency.';
                }
                field(VATAmountLCY; VATAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'VAT amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is in the local currency.';
                }
                field(AmountInclVATLCY; AmountInclVATLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT (LCY)';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is including VAT in the local currency.';
                }
                field(NoOfVATLines_Document; TempVATAmountLine.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of VAT lines.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine, false);
                        UpdateHeaderInfo;
                    end;
                }
                field(AmountExclVATDeduct; AmountExclVATDeduct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Base (Non Deductible)';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies non deductible vat base of cash document';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field(VATAmountDeduct; VATAmountDeduct)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'VAT Amount (Non Deductible)';
                    Editable = false;
                    ToolTip = 'Specifies non deductible vat amount of cash document';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CashDocHeader.Get("Cash Desk No.", "Cash Document No.");

        UpdateLine(TempVATAmountLine);
        UpdateHeaderInfo;
    end;

    var
        CashDocHeader: Record "Cash Document Header";
        Currency: Record Currency;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATLinesForm: Page "VAT Amount Lines";
        AllowVATDifference: Boolean;
        AmountExclVAT: Decimal;
        VATAmount: Decimal;
        AmountInclVAT: Decimal;
        AmountExclVATLCY: Decimal;
        VATAmountLCY: Decimal;
        AmountInclVATLCY: Decimal;
        AmountExclVATDeduct: Decimal;
        VATAmountDeduct: Decimal;

    local procedure UpdateHeaderInfo()
    var
        TotalCashDocLine: Record "Cash Document Line";
    begin
        TotalCashDocLine.Reset();
        TotalCashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        TotalCashDocLine.SetRange("Cash Document No.", "Cash Document No.");

        TotalCashDocLine.CalcSums(
          TotalCashDocLine."VAT Base Amount",
          TotalCashDocLine."Amount Including VAT",
          TotalCashDocLine."VAT Base Amount (LCY)",
          TotalCashDocLine."Amount Including VAT (LCY)",
          TotalCashDocLine."VAT Base (Non Deductible)",
          TotalCashDocLine."VAT Amount (Non Deductible)");

        AmountExclVAT := TotalCashDocLine."VAT Base Amount";
        AmountExclVATDeduct := TotalCashDocLine."VAT Base (Non Deductible)";
        AmountInclVAT := TotalCashDocLine."Amount Including VAT";
        VATAmount := AmountInclVAT - AmountExclVAT;
        VATAmountDeduct := TotalCashDocLine."VAT Amount (Non Deductible)";
        AmountExclVATLCY := TotalCashDocLine."VAT Base Amount (LCY)";
        AmountInclVATLCY := TotalCashDocLine."Amount Including VAT (LCY)";
        VATAmountLCY := AmountInclVATLCY - AmountExclVATLCY;
    end;

    [Scope('OnPrem')]
    procedure UpdateLine(var VATAmountLine: Record "VAT Amount Line")
    var
        CashDocLine: Record "Cash Document Line";
    begin
        if CashDocHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(CashDocHeader."Currency Code");

        VATAmountLine.DeleteAll();

        with CashDocLine do begin
            SetRange("Cash Desk No.", Rec."Cash Desk No.");
            SetRange("Cash Document No.", Rec."Cash Document No.");
            SetFilter("Account Type", '>0');
            if FindSet then
                repeat
                    if "VAT Calculation Type" in
                       ["VAT Calculation Type"::"Reverse Charge VAT", "VAT Calculation Type"::"Sales Tax"]
                    then
                        "VAT %" := 0;

                    if not VATAmountLine.Get("VAT Identifier", "VAT Calculation Type", '', false, Amount >= 0) then begin
                        VATAmountLine.Init();
                        VATAmountLine."VAT Identifier" := "VAT Identifier";
                        VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                        VATAmountLine."VAT %" := "VAT %";
                        VATAmountLine.Modified := true;
                        VATAmountLine.Positive := Amount >= 0;
                        VATAmountLine."Currency Code" := "Currency Code";
                        VATAmountLine.Insert();
                    end;

                    VATAmountLine."Line Amount" += Amount;
                    VATAmountLine."VAT Base" += "VAT Base Amount";
                    VATAmountLine."VAT Amount" += "Amount Including VAT" - "VAT Base Amount";
                    VATAmountLine."Amount Including VAT" += "Amount Including VAT";
                    VATAmountLine."VAT Base (Non Deductible)" += "VAT Base (Non Deductible)";
                    VATAmountLine."VAT Amount (Non Deductible)" += "VAT Amount (Non Deductible)";
                    VATAmountLine."VAT Difference" += "VAT Difference";
                    VATAmountLine."VAT Base (LCY)" += "VAT Base Amount (LCY)";
                    VATAmountLine."VAT Amount (LCY)" += "Amount Including VAT (LCY)" - "VAT Base Amount (LCY)";
                    VATAmountLine."Amount Including VAT (LCY)" += "Amount Including VAT (LCY)";
                    VATAmountLine."VAT Difference (LCY)" += "VAT Difference (LCY)";
                    VATAmountLine.Modify();
                until Next = 0;
            SetRange("Account Type");
        end;

        with VATAmountLine do
            if FindSet then
                repeat
                    "Calculated VAT Amount" := "VAT Amount" - "VAT Difference";
                    Modify;
                until Next = 0;
    end;

    [Scope('OnPrem')]
    procedure VATLinesDrillDown(var VATLinesToDrillDown: Record "VAT Amount Line"; ThisTabAllowsVATEditing: Boolean)
    begin
        AllowVATDifference := false;
        Clear(VATLinesForm);
        VATLinesForm.SetTempVATAmountLine(VATLinesToDrillDown);
        VATLinesForm.InitGlobals(
          "Currency Code", AllowVATDifference, AllowVATDifference and ThisTabAllowsVATEditing,
          CashDocHeader."Amounts Including VAT", false, 0);
        VATLinesForm.RunModal;
        VATLinesForm.GetTempVATAmountLine(VATLinesToDrillDown);
    end;
}

