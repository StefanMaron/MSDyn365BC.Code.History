page 31073 "Whse. Net Change Template List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Warehouse Net Change Templates';
    PageType = List;
    SourceTable = "Whse. Net Change Template";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1220004)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ToolTip = 'Specifies name of export acc. schedule';
                }
                field(Description; Description)
                {
                    ToolTip = 'Specifies the description for net change template list.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ToolTip = 'Specifies the code for the Gen. Bus. Posting Group that applies to the entry.';
                }
            }
        }
    }

    actions
    {
    }
}

