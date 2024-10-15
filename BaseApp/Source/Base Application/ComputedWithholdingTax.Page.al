page 12135 "Computed Withholding Tax"
{
    Caption = 'Computed Withholding Tax';
    Editable = false;
    PageType = List;
    SourceTable = "Computed Withholding Tax";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the withholding tax entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a identification number that refers to the source document that generated the withholding tax entry.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number, using the vendor numbering system, which links the vendor''s source document to the withholding tax entry.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number of the vendor that is related to the withholding tax entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the withholding tax entry is posted.';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to withholding tax.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to withholding tax that has not yet been paid.';
                }
                field("Base - Excluded Amount"; "Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation, based on exclusions allowed by law.';
                }
                field("Remaining - Excluded Amount"; "Remaining - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation and has not yet been paid.';
                }
                field("Non Taxable Amount By Treaty"; "Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation based on residency.';
                }
                field("Non Taxable Remaining Amount"; "Non Taxable Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation based on residency and has not yet been paid.';
                }
                field("Withholding Tax Code"; "Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding code that is applied to this purchase.';
                }
                field("Related Date"; "Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the withholding tax entry.';
                }
                field("Payment Date"; "Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the withholding tax amount was paid to the tax authority.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run();
                end;
            }
        }
    }

    var
        Navigate: Page Navigate;
}

