#if not CLEAN18
page 905 "Assembly Setup"
{
    AccessByPermission = TableData "BOM Component" = R;
    AdditionalSearchTerms = 'kitting setup';
    ApplicationArea = Assembly;
    Caption = 'Assembly Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Assembly Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Stockout Warning"; "Stockout Warning")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies whether the assembly availability warning appears during sales order entry.';
                }
                field("Copy Component Dimensions from"; "Copy Component Dimensions from")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how dimension codes are distributed to assembly components when they are consumed in assembly order posting.';
                }
                field("Default Location for Orders"; "Default Location for Orders")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies at which location assembly orders are created by default.';
                }
                field("Copy Comments when Posting"; "Copy Comments when Posting")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies that comments on assembly order lines are copied to the resulting posted documents.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code for the Gen. Bus. Posting Group that applies to the entry.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Assembly Order Nos."; "Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly orders when they are created.';
                }
                field("Assembly Quote Nos."; "Assembly Quote Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly quotes when they are created.';
                }
                field("Blanket Assembly Order Nos."; "Blanket Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly blanket orders when they are created.';
                }
                field("Posted Assembly Order Nos."; "Posted Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly orders when they are posted.';
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Create Movements Automatically"; "Create Movements Automatically")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that an inventory movement for the required components is created automatically when you create an inventory pick.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

#endif