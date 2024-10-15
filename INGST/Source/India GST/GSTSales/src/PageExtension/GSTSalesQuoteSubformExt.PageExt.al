pageextension 18154 "GST Sales Quote Subform Ext" extends "Sales Quote Subform"
{
    layout
    {
        addafter("Quantity")
        {
            field("GST on Assessable Value"; "GST on Assessable Value")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST is applicable on assessable value.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnSalesLine(Rec, xRec);
                end;
            }
            field("GST Assessable Value (LCY)"; "GST Assessable Value (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST Assessable Value of the line.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnSalesLine(Rec, xRec);
                end;
            }
            field("GST Jurisdiction Type"; "GST Jurisdiction Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type related to GST jurisdiction. For example, interstate/intrastate.';
            }
            field("GST Group Code"; "GST Group Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies an identifier for the GST group used to calculate and post GST.';
            }
            field("GST Group Type"; "GST Group Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST group is assigned for goods or service.';
            }

        }
    }
}