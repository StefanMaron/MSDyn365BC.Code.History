page 7000073 Suffixes
{
    Caption = 'Suffixes';
    PageType = List;
    SourceTable = Suffix;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Acc. Code"; Rec."Bank Acc. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank code that identifies the banking entity that assigns the bank suffixes.';
                }
                field(Suffix; Suffix)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a three-digit number that is used by financial institutions to identify the ordering customer.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the nature of the operation for which the bank has assigned a suffix.';
                }
            }
        }
    }

    actions
    {
    }
}

