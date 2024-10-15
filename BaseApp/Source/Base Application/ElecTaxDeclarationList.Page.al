page 11412 "Elec. Tax Declaration List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Eletronic Tax Declarations';
    CardPageID = "Elec. Tax Declaration Card";
    Editable = false;
    PageType = List;
    SourceTable = "Elec. Tax Declaration Header";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("Declaration Type"; "Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the electronic declaration concerns a VAT or ICP declaration.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the electronic declaration that you are setting up.';
                }
                field("Declaration Period"; "Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration period.';
                }
                field("Declaration Year"; "Declaration Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration year.';
                }
                field("Message ID"; "Message ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the response message from the Tax authority.';
                }
                field("Our Reference"; "Our Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identification for the electronic declaration.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the electronic declaration.';
                }
            }
        }
    }

    actions
    {
    }
}

