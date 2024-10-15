page 17329 "Tax Calc. Corresp. Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Calculation Correspondence Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Calc. G/L Corr. Entry";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Debit Account No."; "Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account number associated with the tax calculation corresponding entry.';
                }
                field("Credit Account No."; "Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account number associated with the tax calculation corresponding entry.';
                }
                field("Tax Register ID Totaling"; "Tax Register ID Totaling")
                {
                    ToolTip = 'Specifies the totaling tax register ID associated with the tax calculation corresponding entry.';
                    Visible = false;
                }
                field("TaxCalcName()"; TaxCalcName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Registers List';

                    trigger OnAssistEdit()
                    begin
                        LookupTaxCalcHeader;
                    end;

                    trigger OnDrillDown()
                    begin
                        DrillDownTaxCalcHeader;
                    end;
                }
                field("Debit Account Name"; "Debit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account name associated with the tax calculation corresponding entry.';
                }
                field("Credit Account Name"; "Credit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account name associated with the tax calculation corresponding entry.';
                }
            }
        }
    }

    actions
    {
    }
}

