page 31072 "Stockkeeping Unit Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Stockkeeping Unit Templates';
    PageType = List;
    SourceTable = "Stockkeeping Unit Template";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Item Category Code"; "Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies item template code';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location code.';
                }
                field("Components at Location"; "Components at Location")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the inventory location from where the production order components are to be taken.';
                }
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies replenishment system';
                }
                field("Reordering Policy"; "Reordering Policy")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies reordering policy';
                }
                field("Include Inventory"; "Include Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if will be Include Inventory';
                }
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code when transfer started';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
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

