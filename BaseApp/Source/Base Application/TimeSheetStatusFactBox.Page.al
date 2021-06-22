page 957 "Time Sheet Status FactBox"
{
    Caption = 'Time Sheet Status';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field(Comment; Comment)
            {
                ApplicationArea = Comments;
                Caption = 'Comment';
                ToolTip = 'Specifies a comment that applies to the time sheet status.';
            }
            field(OpenQty; OpenQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Open';
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for open time sheets.';
            }
            field(SubmittedQty; SubmittedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Submitted';
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for submitted time sheets.';
            }
            field(RejectedQty; RejectedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Rejected';
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for rejected time sheets.';
            }
            field(ApprovedQty; ApprovedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Approved';
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for approved time sheets.';
            }
            field(TotalQuantity; TotalQuantity)
            {
                ApplicationArea = Jobs;
                Caption = 'Total';
                Editable = false;
                Style = Strong;
                StyleExpr = TRUE;
                ToolTip = 'Specifies the sum of time sheet hours for time sheets of all statuses.';
            }
            field(PostedQty; PostedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Posted';
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for posted time sheets.';
            }
        }
    }

    actions
    {
    }

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        OpenQty: Decimal;
        SubmittedQty: Decimal;
        RejectedQty: Decimal;
        ApprovedQty: Decimal;
        PostedQty: Decimal;
        TotalQuantity: Decimal;
        Comment: Boolean;

    procedure UpdateData(TimeSheetHeader: Record "Time Sheet Header")
    begin
        TimeSheetMgt.CalcStatusFactBoxData(
          TimeSheetHeader,
          OpenQty,
          SubmittedQty,
          RejectedQty,
          ApprovedQty,
          PostedQty,
          TotalQuantity);

        TimeSheetHeader.CalcFields(Comment);
        Comment := TimeSheetHeader.Comment;
        CurrPage.Update(false);
    end;
}

