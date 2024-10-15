pageextension 18149 "GST Sales Invoice Subform Ext" extends "Sales Invoice Subform"
{
    layout
    {
        Modify("No.")
        {
            Trigger OnAfterValidate()
            begin
                SaveRecords();
            end;
        }
        Modify("Quantity")
        {
            Trigger OnAfterValidate()
            begin
                SaveRecords();
            end;
        }

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
                ToolTip = 'Specifies the GST Assessable value on which GST is calculated for the line.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnSalesLine(Rec, xRec);
                end;
            }
            field("Price Exclusive of Tax"; "Price Inclusive of Tax")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if prices are exclusive of tax on the line.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnSalesLine(Rec, xRec);
                end;
            }
            field("GST Credit"; "GST Credit")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST credit has to be availed or not.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnSalesLine(Rec, xRec);
                end;
            }
            field("Qty. to Invoice"; "Qty. to Invoice")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the quantity of items that remains to be invoiced. It is calculated as Quantity-Qty. Invoiced';
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
            field(Exempted; Exempted)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the current line is exempted of GST Calculation.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnSalesLine(Rec, xRec);
                end;
            }
        }
    }
    Local Procedure SaveRecords()
    begin
        CurrPage.SaveRecord();
    end;
}