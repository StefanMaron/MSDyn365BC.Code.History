page 26576 "Create Requisites Codes"
{
    Caption = 'Create Requisites Codes';
    PageType = Card;

    layout
    {
    }

    actions
    {
    }

    var
        StatutoryReportTable: Record "Statutory Report Table";
        ReportName: Code[20];
        ReportTableName: Code[20];
        RowCode: Text[20];

    [Scope('OnPrem')]
    procedure SetParameters(NewReportName: Code[20]; NewTableName: Code[20])
    begin
    end;

    [Scope('OnPrem')]
    procedure GetParameters(var NewRowCode: Text[20])
    begin
    end;
}

