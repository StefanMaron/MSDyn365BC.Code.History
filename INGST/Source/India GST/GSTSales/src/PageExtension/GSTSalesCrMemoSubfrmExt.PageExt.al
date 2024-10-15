pageextension 18147 "GST Sales. Cr. Memo Subfrm Ext" extends "Sales Cr. Memo Subform"
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
        addafter("Qty. to Assign")
        {

            field("GST Group Code"; "GST Group Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies an unique identifier for the GST group code used to calculate and post GST.';
            }
            field("GST Group Type"; "GST Group Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST group is assigned for goods or service.';
            }
            field(Exempted; Exempted)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the line is exempted from GST.';
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
        }
    }
    Local Procedure SaveRecords()
    begin
        CurrPage.SaveRecord();
    end;
}