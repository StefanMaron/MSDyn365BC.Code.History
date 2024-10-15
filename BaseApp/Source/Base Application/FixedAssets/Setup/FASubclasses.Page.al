namespace Microsoft.FixedAssets.Setup;

page 5616 "FA Subclasses"
{
    AdditionalSearchTerms = 'fixed asset subclasses buildings vehicles';
    ApplicationArea = FixedAssets;
    Caption = 'FA Subclasses';
    PageType = List;
    SourceTable = "FA Subclass";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a code for the subclass that the fixed asset belongs to.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the fixed asset subclass.';
                }
                field("FA Class Code"; Rec."FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the class that the subclass belongs to.';
                }
                field("Default FA Posting Group"; Rec."Default FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the posting group that is used when posting fixed assets that belong to this subclass.';
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

