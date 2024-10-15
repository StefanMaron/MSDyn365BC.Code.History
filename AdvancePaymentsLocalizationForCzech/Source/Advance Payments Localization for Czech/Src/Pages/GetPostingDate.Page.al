page 31229 "Get Posting Date CZZ"
{
    Caption = 'Get Posting Date';
    PageType = StandardDialog;
    InstructionalText = 'It is required to set the posting date.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies posting date.';
                }
            }
        }
    }

    var
        PostingDate: Date;

    procedure SetValues(NewPostingDate: Date)
    begin
        PostingDate := NewPostingDate;
    end;

    procedure GetValues(var NewPostingDate: Date)
    begin
        NewPostingDate := PostingDate;
    end;
}
