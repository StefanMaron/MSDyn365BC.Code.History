page 443 "Reminder Comment List"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    DataCaptionExpression = Caption(Rec);
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Reminder Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document the comment is attached to: either Reminder or Issued Reminder.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment itself.';
                }
            }
        }
    }

    actions
    {
    }

    var
        Text000: Label 'untitled', Comment = 'it is a caption for empty page';
        Text001: Label 'Reminder';

    procedure Caption(ReminderCommentLine: Record "Reminder Comment Line"): Text
    begin
        if ReminderCommentLine."No." = '' then
            exit(Text000);
        exit(Text001 + ' ' + ReminderCommentLine."No." + ' ');
    end;
}

