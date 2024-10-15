page 12210 "Withholding Tax Lines"
{
    AutoSplitKey = true;
    Caption = 'Withholding Tax Lines';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Withholding Tax Line";

    layout
    {
        area(content)
        {
            group(Header)
            {
                field("Total Base - Excluded Amount"; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Base - Excluded Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount of the original purchase that is excluded from the withholding tax calculation as defined by law.';
                }
            }
            repeater(General)
            {
                field("Base - Excluded Amount"; "Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation, based on exclusions allowed by law.';
                }
                field("Non-Taxable Income Type"; "Non-Taxable Income Type")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = ' ,,2,,6,,8,9,,,,13,4,14,21,22,23,24';
                    ToolTip = 'Specifies the type of non-taxable income.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        if GetFilter("Withholding Tax Entry No.") <> '' then
            Evaluate(WithholdingTax."Entry No.", GetFilter("Withholding Tax Entry No."));
        if WithholdingTax.FindFirst() then
            TotalAmount := WithholdingTax."Base - Excluded Amount";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CheckAmounts());
    end;

    var
        AmountNotEqualQst: Label 'The total amount of all lines is %1, which is not equal to the value of the Base - Excluded Amount field (%2) on the Withholding Tax Card. This will result in an error when you export the entry. \ Do you want to close the page anyway?', Comment = '%1=amount,%2=another amount';
        TotalAmount: Decimal;

    local procedure CheckAmounts(): Boolean
    var
        WithholdingTax: Record "Withholding Tax";
        ConfirmManagement: Codeunit "Confirm Management";
        TotalLineAmount: Decimal;
    begin
        if not FindSet() then
            exit(true);
        WithholdingTax.SetRange("Entry No.", "Withholding Tax Entry No.");
        WithholdingTax.FindFirst();
        TotalLineAmount := GetAmountForEntryNo("Withholding Tax Entry No.");
        if WithholdingTax."Base - Excluded Amount" = TotalLineAmount then
            exit(true);
        exit(ConfirmManagement.GetResponse(
            StrSubstNo(AmountNotEqualQst, TotalLineAmount, WithholdingTax."Base - Excluded Amount"), false));
    end;
}

