report 17370 "Copy Position"
{
    Caption = 'Copy Position';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PositionNumber; PositionNumber)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Confirmed := false;
        if HideDialog then
            Confirmed := true
        else
            if Confirm(Text14700, false, PositionNumber, Position."No.") then
                Confirmed := true;

        if Confirmed then
            while PositionNumber > 0 do begin
                Position.CopyPosition(Today);
                PositionNumber := PositionNumber - 1;
            end;
    end;

    var
        Position: Record Position;
        PositionNumber: Integer;
        Text14700: Label '%1 copies of current position %2 will be created. Continue?';
        HideDialog: Boolean;
        Confirmed: Boolean;

    [Scope('OnPrem')]
    procedure Set(NewPosition: Record Position; NewPositionNumber: Integer; NewHideDialog: Boolean)
    begin
        Position := NewPosition;
        PositionNumber := NewPositionNumber;
        HideDialog := NewHideDialog;
    end;
}

