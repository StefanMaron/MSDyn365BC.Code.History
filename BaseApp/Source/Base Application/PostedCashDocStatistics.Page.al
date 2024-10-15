page 11739 "Posted Cash Doc. Statistics"
{
    Caption = 'Posted Cash Doc. Statistics (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Posted Cash Document Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

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
                field("AmountExclVAT[1]"; AmountExclVAT[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Excluding VAT';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is excluding VAT.';
                }
                field("VATAmount[1]"; VATAmount[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'VAT amount';
                    Editable = false;
                    ToolTip = 'Specifies cash document amount.';
                }
                field("AmountInclVAT[1]"; AmountInclVAT[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is including VAT.';
                }
                field("AmountExclVATLCY[1]"; AmountExclVATLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Excluding VAT (LCY)';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is excluding VAT in the local currency.';
                }
                field("VATAmountLCY[1]"; VATAmountLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'VAT amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is in the local currency.';
                }
                field("AmountInclVATLCY[1]"; AmountInclVATLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT (LCY)';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is including VAT in the local currency.';
                }
                field(NoOfVATLines_Document; TempVATAmountLine1.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of VAT lines.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine1, false);
                        UpdateHeaderInfo(1);
                    end;
                }
            }
            group("External Document")
            {
                Caption = 'External Document';
                field(ExternalCurrencyCode; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("AmountExclVAT[2]"; AmountExclVAT[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Excluding VAT';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is excluding VAT.';
                }
                field("VATAmount[2]"; VATAmount[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'VAT amount';
                    Editable = false;
                    ToolTip = 'Specifies cash document amount.';
                }
                field("AmountInclVAT[2]"; AmountInclVAT[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is including VAT.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the number that the vendor uses on the invoice they sent to you or number of receipt.';
                }
                field("AmountExclVATLCY[2]"; AmountExclVATLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Excluding VAT (LCY)';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is excluding VAT in the local currency.';
                }
                field("VATAmountLCY[2]"; VATAmountLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'VAT amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is in the local currency.';
                }
                field("AmountInclVATLCY[2]"; AmountInclVATLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Including VAT (LCY)';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies cash document amount. The amount is including VAT in the local currency.';
                }
                field(NoOfVATLines_External; TempVATAmountLine2.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of VAT Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of VAT lines.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine2, false);
                        UpdateHeaderInfo(2);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        PostedCashDocHeader.Get("Cash Desk No.", "Cash Document No.");

        UpdateLine(1, TempVATAmountLine1);
        UpdateLine(2, TempVATAmountLine2);

        UpdateHeaderInfo(1);
        UpdateHeaderInfo(2);
    end;

    var
        PostedCashDocHeader: Record "Posted Cash Document Header";
        Currency: Record Currency;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        TempVATAmountLine2: Record "VAT Amount Line" temporary;
        VATLinesForm: Page "VAT Amount Lines";
        AllowVATDifference: Boolean;
        AmountExclVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        AmountInclVAT: array[2] of Decimal;
        AmountExclVATLCY: array[2] of Decimal;
        VATAmountLCY: array[2] of Decimal;
        AmountInclVATLCY: array[2] of Decimal;

    local procedure UpdateHeaderInfo(IndexNo: Integer)
    var
        TotalPostedCashDocLine: Record "Posted Cash Document Line";
    begin
        TotalPostedCashDocLine.Reset();
        TotalPostedCashDocLine.SetCurrentKey("Cash Desk No.", "Cash Document No.", "External Document No.");
        TotalPostedCashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        TotalPostedCashDocLine.SetRange("Cash Document No.", "Cash Document No.");
        if IndexNo = 2 then
            TotalPostedCashDocLine.SetRange("External Document No.", "External Document No.");

        TotalPostedCashDocLine.CalcSums(
          TotalPostedCashDocLine."VAT Base Amount",
          TotalPostedCashDocLine."Amount Including VAT",
          TotalPostedCashDocLine."VAT Base Amount (LCY)",
          TotalPostedCashDocLine."Amount Including VAT (LCY)");

        AmountExclVAT[IndexNo] := TotalPostedCashDocLine."VAT Base Amount";
        AmountInclVAT[IndexNo] := TotalPostedCashDocLine."Amount Including VAT";
        VATAmount[IndexNo] := AmountInclVAT[IndexNo] - AmountExclVAT[IndexNo];
        AmountExclVATLCY[IndexNo] := TotalPostedCashDocLine."VAT Base Amount (LCY)";
        AmountInclVATLCY[IndexNo] := TotalPostedCashDocLine."Amount Including VAT (LCY)";
        VATAmountLCY[IndexNo] := AmountInclVATLCY[IndexNo] - AmountExclVATLCY[IndexNo];
    end;

    [Scope('OnPrem')]
    procedure UpdateLine(IndexNo: Integer; var VATAmountLine: Record "VAT Amount Line")
    var
        PostedCashDocLine: Record "Posted Cash Document Line";
    begin
        if PostedCashDocHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PostedCashDocHeader."Currency Code");

        VATAmountLine.DeleteAll();

        with PostedCashDocLine do begin
            SetRange("Cash Desk No.", Rec."Cash Desk No.");
            SetRange("Cash Document No.", Rec."Cash Document No.");
            SetFilter("Account Type", '>0');
            if IndexNo = 2 then
                SetRange("External Document No.", Rec."External Document No.");
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
                        VATAmountLine.Positive := Amount >= 0;
                        VATAmountLine."Currency Code" := "Currency Code";
                        VATAmountLine."VAT %" := "VAT %";
                        VATAmountLine.Modified := true;
                        VATAmountLine.Insert();
                    end;

                    VATAmountLine."VAT Base (Non Deductible)" += "VAT Base (Non Deductible)";
                    VATAmountLine."VAT Amount (Non Deductible)" += "VAT Amount (Non Deductible)";
                    VATAmountLine."Line Amount" += Amount;
                    VATAmountLine."Amount Including VAT" += "Amount Including VAT";
                    VATAmountLine."VAT Base" += "VAT Base Amount";
                    VATAmountLine."VAT Amount" += "Amount Including VAT" - "VAT Base Amount";
                    VATAmountLine."VAT Difference" += "VAT Difference";
                    VATAmountLine."Amount Including VAT (LCY)" += "Amount Including VAT (LCY)";
                    VATAmountLine."VAT Base (LCY)" += "VAT Base Amount (LCY)";
                    VATAmountLine."VAT Amount (LCY)" += "Amount Including VAT (LCY)" - "VAT Base Amount (LCY)";
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
          PostedCashDocHeader."Amounts Including VAT", false, 0);
        VATLinesForm.RunModal;
        VATLinesForm.GetTempVATAmountLine(VATLinesToDrillDown);
    end;
}

