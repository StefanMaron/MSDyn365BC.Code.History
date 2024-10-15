page 14955 "Tax Allocation Posting Setup"
{
    Caption = 'Tax Allocation Posting Setup';
    PageType = List;
    SourceTable = "Tax Allocation Posting Setup";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Main Posting Group"; "Main Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payroll Element Code"; "Payroll Element Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Allocated Posting Group"; "Tax Allocated Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

