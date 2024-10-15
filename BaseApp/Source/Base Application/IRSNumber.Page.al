page 10911 "IRS Number"
{
    ApplicationArea = Basic, Suite;
    Caption = 'IRS Number';
    PageType = List;
    SourceTable = "IRS Numbers";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("IRS Number"; "IRS Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an Internal Revenue Service (IRS) tax number as defined by the Icelandic tax authorities.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a name for the Internal Revenue Service (IRS) tax number.';
                }
                field("Reverse Prefix"; "Reverse Prefix")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the balance of the general ledger accounts with this IRS tax number must reverse the negative operator in IRS reports.';
                }
            }
        }
    }

    actions
    {
    }
}

