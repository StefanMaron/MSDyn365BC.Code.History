page 11784 "Non Deductible VAT Setup"
{
    Caption = 'Non Deductible VAT Setup';
    PageType = List;
    SourceTable = "Non Deductible VAT Setup";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("From Date"; "From Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies from which date is valid % non deductible VAT setup.';
                }
                field("Non Deductible VAT %"; "Non Deductible VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the % for non deductible VAT.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220000; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220001; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

