page 2021 "Office Attachments"
{
    Caption = 'Office Attachments';
    DataCaptionExpression = PageCaptionTxt;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Exchange Object";
    SourceTableTemporary = true;
    SourceTableView = SORTING(Name)
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attach';
                    ToolTip = 'Select';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Name';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if Count = 1 then begin
            Selected := true;
            Modify();
        end
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            onSave();
    end;

    local procedure onSave(): Boolean
    begin
        SetRange(Selected, true);
        if FindSet() then begin
            repeat
                OfficeMgt.SendToAttachments(Rec);
            until Next() = 0;
            OfficeMgt.DisplaySuccessMessage(Rec);
        end;
    end;

    var
        OfficeMgt: Codeunit "Office Management";
        PageCaptionTxt: Label 'Select Attachment to Send';
}

