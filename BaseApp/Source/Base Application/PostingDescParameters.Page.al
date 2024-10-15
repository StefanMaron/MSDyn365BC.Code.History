page 11786 "Posting Desc. Parameters"
{
    Caption = 'Posting Desc. Parameters';
    DataCaptionFields = "Posting Desc. Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Posting Desc. Parameter";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of posting description will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';

    layout
    {
        area(content)
        {
            repeater(Control1220003)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting description number.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of payment order lines';
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a field name for the posting parameter.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220005; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220004; Notes)
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

