page 579 "Post Application"
{
    Caption = 'Post Application';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DocNo; DocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of the entry to be applied.';
                }
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the entry to be applied.';
                }
            }
        }
    }

    actions
    {
    }

    var
        DocNo: Code[20];
        PostingDate: Date;

    procedure SetValues(NewDocNo: Code[20]; NewPostingDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetValues(NewDocNo, NewPostingDate, IsHandled);
        if IsHandled then
            exit;

        DocNo := NewDocNo;
        PostingDate := NewPostingDate;
    end;

    procedure GetValues(var NewDocNo: Code[20]; var NewPostingDate: Date)
    begin
        OnBeforeGetValues(NewDocNo, NewPostingDate);

        NewDocNo := DocNo;
        NewPostingDate := PostingDate;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetValues(var NewDocNo: Code[20]; var NewPostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetValues(var NewDocNo: Code[20]; var NewPostingDate: Date)
    begin
    end;
}

