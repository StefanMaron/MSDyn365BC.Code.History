page 31091 "Reverse Charges"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Reverse Charges';
    CardPageID = "Reverse Charge";
    Editable = false;
    PageType = List;
    SourceTable = "Reverse Charge Header";
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reverse charge.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Declaration Period"; "Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies declaration Period (month, quarter).';
                }
                field("Period No."; "Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT period.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of report';
                }
                field("Declaration Type"; "Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration type for the declaration header (normal, corrective, corrective-supplementary).';
                }
                field("Statement Type"; "Statement Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration type for the declaration header.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of reverse charges';
                }
            }
        }
    }

    actions
    {
    }
}

