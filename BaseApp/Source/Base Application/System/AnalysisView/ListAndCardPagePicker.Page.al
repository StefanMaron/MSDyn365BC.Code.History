namespace System.Tooling;

using System.Reflection;

page 9641 "List and Card page picker"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Page Metadata";
    Editable = false;
    Extensible = false;
    Caption = 'Choose a source page';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ID; Rec.ID)
                {
                    ToolTip = 'Specifies the page id.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the page name.';
                }
                field(PageType; Rec.PageType)
                {
                    ToolTip = 'Specifies the page type.';
                }
            }
        }
    }
}