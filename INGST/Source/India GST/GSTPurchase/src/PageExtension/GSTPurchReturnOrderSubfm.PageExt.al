pageextension 18091 "GST Purch. Return Order Subfm" extends "Purchase Return Order Subform"
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
        Modify("Cross-Reference No.")
        {
            Trigger OnAfterValidate()
            begin
                SaveRecords();
            end;
        }
        Modify(Quantity)
        {
            Trigger OnAfterValidate()
            begin
                SaveRecords();
            end;
        }
        Modify("Line Amount")
        {
            Trigger OnAfterValidate()
            begin
                SaveRecords();
            end;
        }
        Modify("Line Discount %")
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
                ToolTip = 'Specifies an identifier for the GST group  used to calculate and post GST.';
            }
            field("GST Group Type"; "GST Group Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST group is assigned for goods or service.';
            }
            field(Exempted; Exempted)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specified whether the return order is exempted form GST or not.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnPurchaseLine(Rec, xRec);
                end;
            }
            field("GST Jurisdiction Type"; "GST Jurisdiction Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type related to GST jurisdiction. For example, interstate/intrastate.';
            }
            field("GST Credit"; "GST Credit")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies if the GST credit has to be availed or not.';
                trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnPurchaseLine(Rec, xRec);
                end;
            }
            field("GST Assessable Value"; "GST Assessable Value")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the assessable value on which GST will be calculated in case of import purchase.';
                trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnPurchaseLine(Rec, xRec);
                end;
            }
            field("Custom Duty Amount"; "Custom Duty Amount")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the custom duty amount  on the Purchase Return.';
                trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnPurchaseLine(Rec, xRec);
                end;

            }
        }
    }
    Local Procedure SaveRecords()
    begin
        CurrPage.SaveRecord();
    end;
}