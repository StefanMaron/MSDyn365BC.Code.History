page 9894 "SmartList Export Dialog"
{
    Caption = 'SmartList Export';
    Extensible = false;
    PageType = StandardDialog;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Filename; Filename)
            {
                ApplicationArea = All;
                Caption = 'Filename';
                Editable = true;
                ToolTip = 'Specifies the filename.';
            }
        }
    }

    trigger OnInit()
    var
        Now: DateTime;
    begin
        Now := CurrentDateTime();
        Filename := Format(Now, 0, 'SmartList <Year4>-<Month,2>-<Day,2> <Hours24,2>.<Minutes,2>.<Seconds,2>');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction in [ACTION::OK, ACTION::LookupOK]) then
            if Filename = '' then
                Error('A filename must be specified.');

    end;

    procedure GetFilename(): Text
    begin
        exit(Filename);
    end;

    var
        Filename: Text[250];
}