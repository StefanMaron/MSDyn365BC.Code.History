pageextension 18850 "Sales Quote TCS" extends "Sales Quote"
{
    layout
    {
        addlast(General)
        {
            field("Exclude GST in TCS Base"; Rec."Exclude GST in TCS Base")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Select this field to exclude GST value in the TCS Base.';

                trigger OnValidate()
                var
                    SalesLine: Record "Sales Line";
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    SalesLine.SetRange("Document Type", Rec."Document Type");
                    SalesLine.SetRange("Document No.", Rec."No.");
                    if SalesLine.FindSet() then
                        repeat
                            if SalesLine.Type <> SalesLine.Type::" " then
                                CalculateTax.CallTaxEngineOnSalesLine(SalesLine, SalesLine);
                        until SalesLine.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
        }
    }
}