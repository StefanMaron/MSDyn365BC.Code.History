page 5658 "Main Asset Components"
{
    AutoSplitKey = false;
    Caption = 'Main Asset Components';
    DataCaptionFields = "Main Asset No.";
    PageType = List;
    SourceTable = "Main Asset Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Main Asset No."; Rec."Main Asset No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the main asset. This is the asset for which components can be set up.';
                    Visible = false;
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the description linked to the fixed asset for the fixed asset number you entered in FA No. field.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the quantity of the component that is used for the main asset.';
                }
                field("Apply After Disassembly"; Rec."Apply After Disassembly")
                {
                    ToolTip = 'Specifies if the component was applied after disassembly of the main asset.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
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

