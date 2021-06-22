codeunit 9654 "Design-time Report Selection"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        SelectedCustomLayoutCode: Code[20];

    procedure SetSelectedCustomLayout(NewCustomLayoutCode: Code[20])
    begin
        SelectedCustomLayoutCode := NewCustomLayoutCode;
    end;

    procedure GetSelectedCustomLayout(): Code[20]
    begin
        exit(SelectedCustomLayoutCode);
    end;
}

