page 5433 "Automation - RS Package File"
{
    Caption = 'Automation - RS Package File';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tenant Config. Package File";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(content; Content)
                {
                    ApplicationArea = All;
                    Caption = 'Content', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CodeFilter: Text;
    begin
        if not FilesLoaded then begin
            CodeFilter := GetFilter(Code);
            if CodeFilter = '' then
                Error(CodeNotSpecifiedForLinesErr);
            if not FindFirst then
                exit(false);
            FilesLoaded := true;
        end;

        exit(true);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(AutomationAPIManagement);
    end;

    var
        AutomationAPIManagement: Codeunit "Automation - API Management";
        FilesLoaded: Boolean;
        CodeNotSpecifiedForLinesErr: Label 'You must specify a Configuration Package Code before uploading a Configuration Package File.', Locked = true;
}

