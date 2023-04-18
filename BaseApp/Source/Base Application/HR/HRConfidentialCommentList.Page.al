page 5235 "HR Confidential Comment List"
{
    Caption = 'Comment List';
    DataCaptionExpression = Caption(Rec);
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "HR Confidential Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; Date)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date when the comment was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code for the comment.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    var
        Employee: Record Employee;
        ConfidentialInfo: Record "Confidential Information";
        Text000: Label 'untitled', Comment = 'it is a caption for empty page';

    procedure Caption(HRCommentLine: Record "HR Confidential Comment Line"): Text
    begin
        if ConfidentialInfo.Get(HRCommentLine."No.", HRCommentLine.Code, HRCommentLine."Table Line No.") and
           Employee.Get(HRCommentLine."No.")
        then
            exit(HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
              ConfidentialInfo."Confidential Code");
        exit(Text000);
    end;
}

