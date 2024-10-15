namespace Microsoft.FixedAssets.Journal;

page 5609 "FA Journal Setup"
{
    Caption = 'FA Journal Setup';
    DataCaptionFields = "Depreciation Book Code";
    PageType = List;
    SourceTable = "FA Journal Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("FA Jnl. Template Name"; Rec."FA Jnl. Template Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies an FA journal template.';
                }
                field("FA Jnl. Batch Name"; Rec."FA Jnl. Batch Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the relevant FA journal batch name.';
                }
                field("Gen. Jnl. Template Name"; Rec."Gen. Jnl. Template Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a general journal template.';
                }
                field("Gen. Jnl. Batch Name"; Rec."Gen. Jnl. Batch Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the relevant general journal batch name.';
                }
                field("Insurance Jnl. Template Name"; Rec."Insurance Jnl. Template Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies an insurance journal template.';
                }
                field("Insurance Jnl. Batch Name"; Rec."Insurance Jnl. Batch Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the relevant insurance journal batch name.';
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

