pageextension 18849 "Sales Invoice Statistics" extends "Sales Invoice Statistics"
{
    layout
    {
        addafter(AmountInclVAT)
        {
            field("Total Amount"; TotalTaxAmount)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Caption = 'Net Total';
                ToolTip = 'Specifies the total amount including Tax that will be posted to the customer''s account for all the lines in the sales document. This is the amount that the customer owes based on this sales document. If the document is a credit memo, it is the amount that you owe to the customer.';
            }
            field("TCS Amount"; TCSAmount)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Caption = 'TCS Amount';
                ToolTip = 'Specifies the total TCS amount that has been calculated for all the lines in the sales document.';
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        TCSSetup: Record "TCS Setup";
        TaxTransectionValue: Record "Tax Transaction Value";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TaxComponent: Record "Tax Component";
        TCSManagement: Codeunit "TCS Management";
        RecordIDList: List of [RecordID];
        i: Integer;
    begin
        Clear(TotalTaxAmount);
        Clear(TCSAmount);
        if not TCSSetup.Get() then
            exit;

        TaxComponent.SetRange("Tax Type", TCSSetup."Tax Type");
        TaxComponent.SetRange("Skip Posting", false);
        if TaxComponent.FindFirst() then;

        SalesInvoiceLine.SetRange("Document no.", Rec."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                RecordIDList.Add(SalesInvoiceLine.RecordId());
                TotalTaxAmount += SalesInvoiceLine.Amount;
            until SalesInvoiceLine.Next() = 0;

        for i := 1 to RecordIDList.Count() do begin
            TaxTransectionValue.SetRange("Tax Record ID", RecordIDList.Get(i));
            TaxTransectionValue.SetRange("Value Type", TaxTransectionValue."Value Type"::COMPONENT);
            TaxTransectionValue.SetRange("Tax Type", TCSSetup."Tax Type");
            TaxTransectionValue.SetRange("Value ID", TaxComponent.ID);
            if not TaxTransectionValue.IsEmpty() then begin
                TaxTransectionValue.CalcSums(Amount);
                TCSAmount += TaxTransectionValue.Amount;
            end;
        end;
        TotalTaxAmount := TotalTaxAmount + TCSAmount;
        TotalTaxAmount := TCSManagement.RoundTCSAmount(TotalTaxAmount);
        TCSAmount := TCSManagement.RoundTCSAmount(TCSAmount);
    end;

    var
        TotalTaxAmount: Decimal;
        TCSAmount: Decimal;
}