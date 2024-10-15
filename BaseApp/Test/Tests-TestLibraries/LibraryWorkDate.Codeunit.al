codeunit 143050 "Library - WorkDate"
{

    trigger OnRun()
    begin
    end;

    var
        DefaultWorkDate: Date;

    [Scope('OnPrem')]
    procedure SetWorkDate(Date: Date)
    begin
        if Date = 0D then
            exit;
        if DefaultWorkDate = 0D then
            DefaultWorkDate := WorkDate;

        WorkDate := Date;
    end;

    [Scope('OnPrem')]
    procedure GetDefaultWorkDate(): Date
    begin
        if DefaultWorkDate = 0D then
            exit(WorkDate);
        exit(DefaultWorkDate);
    end;
}

