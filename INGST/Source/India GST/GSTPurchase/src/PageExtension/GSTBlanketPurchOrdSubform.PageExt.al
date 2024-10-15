pageextension 18098 "GST Blanket Purch Ord Subform" extends "Blanket Purchase Order Subform"
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

        addafter(Quantity)
        {
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
                    CalculateTax.CallTaxEngineOnPurchaseLine(Rec, xRec);
                end;
            }
            field("GST Assessable Value"; "GST Assessable Value")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the assessable value on which GST will be calculated in case of import purchase.';
                Trigger OnValidate()
                var
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    CalculateTax.CallTaxEngineOnPurchaseLine(Rec, xRec);
                end;
            }
            field("Custom Duty Amount"; "Custom Duty Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the custom duty amount  on the transfer line.';
                Trigger OnValidate()
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