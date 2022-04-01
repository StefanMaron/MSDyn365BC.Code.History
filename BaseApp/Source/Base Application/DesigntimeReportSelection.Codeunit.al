codeunit 9654 "Design-time Report Selection"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        SelectedCustomLayoutCode: Code[20];
        SelectedCustomLayout: Text[250];

    procedure SetSelectedCustomLayout(NewCustomLayoutCode: Code[20])
    begin
        SelectedCustomLayoutCode := NewCustomLayoutCode;
    end;

    procedure GetSelectedCustomLayout(): Code[20]
    begin
        exit(SelectedCustomLayoutCode);
    end;

    // The following methods allow us to also select layouts stored in platform tables
    // as well as App tables. SelectedCustomLayoutCode cannot select platform layouts
    // because the code field has a small size of just 20 characters.
    procedure SetSelectedLayout(NewLayoutName: Text[250])
    begin
        SelectedCustomLayout := NewLayoutName;
    end;

    procedure GetSelectedLayout(): Text[250]
    begin
        if SelectedCustomLayout = '' then
            exit(SelectedCustomLayoutCode);
        exit(SelectedCustomLayout);
    end;
}

