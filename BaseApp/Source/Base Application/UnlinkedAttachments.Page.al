page 199 "Unlinked Attachments"
{
    Caption = 'Unlinked Files';
    Editable = false;
    PageType = List;
    SourceTable = "Unlinked Attachment";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file type.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the record was created.';
                }
                field(Id; Id)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the record ID.';
                }
            }
        }
    }

    actions
    {
    }
}

