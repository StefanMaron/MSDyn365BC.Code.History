page 12136 "Computed Contribution"
{
    Caption = 'Computed Contribution';
    Editable = false;
    PageType = List;
    SourceTable = "Computed Contribution";

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
                    ToolTip = 'Specifies the transaction date of the source document that generated the contribution tax entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number that refers to the source document that generated the contribution tax entry.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number, which links the vendor''s source document to the contribution tax entry.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number of the vendor that is related to the contribution tax entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the contribution tax entry is posted.';
                }
                field("Social Security Code"; "Social Security Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Social Security code that is applied to the contribution tax entry.';
                }
                field("Gross Amount"; "Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to Social Security tax.';
                }
                field("Soc.Sec.Non Taxable Amount"; "Soc.Sec.Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from Social Security tax liability, based on provisions in the law.';
                }
                field("INAIL Code"; "INAIL Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the INAIL contribution tax code that is applied to the purchase for workers'' compensation insurance.';
                }
                field("INAIL Gross Amount"; "INAIL Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to INAIL contribution tax.';
                }
                field("INAIL Non Taxable Amount"; "INAIL Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the INAIL contribution tax, based on provisions in the law.';
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

