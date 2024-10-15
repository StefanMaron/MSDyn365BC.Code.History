namespace Microsoft.Service.Maintenance;

page 5992 "Troubleshooting Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Troubleshooting Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the troubleshooting comment or guidelines.';
                }
            }
        }
    }

    actions
    {
    }
}

