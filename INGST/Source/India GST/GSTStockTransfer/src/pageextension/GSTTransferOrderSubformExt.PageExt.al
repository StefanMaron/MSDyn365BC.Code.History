pageextension 18396 "GST Transfer Order Subform Ext" extends "Transfer Order Subform"
{

    layout
    {
        modify(Quantity)
        {
            trigger OnAfterValidate()
            var
                TaxCaseExecution: Codeunit "Use Case Execution";
            begin
                CurrPage.SaveRecord();
                TaxCaseExecution.HandleEvent('OnAfterTransferPrirce', Rec, '', 0);
            end;
        }
        addafter(Quantity)
        {
            field(Amount; Rec.Amount)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the amount for the item on the transfer line.';
            }
            field("Transfer Price"; Rec."Transfer Price")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Transfer Price for the item on the transfer line.';
                trigger OnValidate()
                begin
                    CurrPage.SaveRecord();
                end;
            }
        }
        addafter("Receipt Date")
        {
            field("Custom Duty Amount"; Rec."Custom Duty Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the custom duty amount  on the transfer line.';
                trigger OnValidate()
                var
                    TaxCaseExecution: Codeunit "Use Case Execution";
                begin
                    CurrPage.SaveRecord();
                    TaxCaseExecution.HandleEvent('OnAfterTransferPrirce', Rec, '', 0);
                end;
            }
            field("GST Assessable Value"; Rec."GST Assessable Value")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST assessable value on the transfer line.';
                trigger OnValidate()
                var
                    TaxCaseExecution: Codeunit "Use Case Execution";
                begin
                    CurrPage.SaveRecord();
                    TaxCaseExecution.HandleEvent('OnAfterTransferPrirce', Rec, '', 0);
                end;
            }
        }
    }
}