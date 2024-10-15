page 31107 "Get Doc.No and Date"
{
    Caption = 'Close Line with Document No.';
    PageType = StandardDialog;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CloseDocNo; CloseDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Document No.';
                    ToolTip = 'Specifies no. of  the closed document';
                }
                field(CloseDate; CloseDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Date';
                    ToolTip = 'Specifies closed date';
                }
            }
        }
    }

    actions
    {
    }

    var
        CloseDocNo: Code[20];
        CloseDate: Date;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure SetValues(NewDocNo: Code[20]; NewPostingDate: Date)
    begin
        CloseDocNo := NewDocNo;
        CloseDate := NewPostingDate;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure GetValues(var NewDocNo: Code[20]; var NewPostingDate: Date)
    begin
        NewDocNo := CloseDocNo;
        NewPostingDate := CloseDate;
    end;
}

