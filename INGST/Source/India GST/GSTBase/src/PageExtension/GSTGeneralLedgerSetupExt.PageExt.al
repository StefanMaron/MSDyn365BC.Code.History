pageextension 18004 "GST General Ledger Setup Ext" extends "General Ledger Setup"
{
    layout
    {
        addafter("Application")
        {
            group("Tax Information")
            {
                group("GST")
                {
                    field("State Code - Kerala"; rec."State Code - Kerala")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the state code that will be used to GST calculation of Kerala Cess.';
                    }
                    field("GST Distribution Nos."; Rec."GST Distribution Nos.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code for the number series that will be used to assign numbers to GST distribution.';

                    }
                    field("GST Credit Adj. Jnl Nos."; Rec."GST Credit Adj. Jnl Nos.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code for the number series that will be used to assign numbers to GST credit adjustment journal.';

                    }
                    field("GST Settlement Nos."; Rec."GST Settlement Nos.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code for the number series that will be used to assign numbers to GST settlement.';

                    }
                    field("GST Recon. Tolerance"; Rec."GST Recon. Tolerance")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the tolerance level for GST reconciliation.';

                    }
                    field("GST Inv. Rounding Type"; Rec."GST Inv. Rounding Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the GST invoice rounding type to be used in GST entry.';
                    }
                    field("GST Inv. Rounding Precision"; Rec."GST Inv. Rounding Precision")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the GST invoice rounding precision to be used in GST entry.';
                    }
                    field("GST Inv. Rounding Account"; Rec."GST Inv. Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies invoice rounding general ledger account number to be used for GST entry';
                    }
                    field("GST Rounding Precision"; Rec."GST Rounding Precision")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the GST rounding precision to be used in GST entry.';
                    }
                    field("GST Rounding Type"; Rec."GST Rounding Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the GST rounding type to be used in GST entry.';
                    }

                }
            }
        }
    }
}