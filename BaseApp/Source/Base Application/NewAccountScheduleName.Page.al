page 105 "New Account Schedule Name"
{
    Caption = 'New Account Schedule Name';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(AccountSheduleGroup)
            {
                Caption = 'Account Schedule';
                field(SourceAccountScheduleName; OldName[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Account Schedule Name';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing account schedule in the package.';
                }
                field(NewAccountScheduleName; NewName[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Account Schedule Name';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new account schedule after importing.';
                    trigger OnValidate()
                    begin
                        CheckAccScheduleAlreadyExists();
                        CurrPage.Update();
                    end;
                }
                field(AlreadyExistsText; AlreadyExistsTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                }
            }
            group(ColumnLayoutGroup)
            {
                Caption = 'Default Column Layout';
                Visible = ShowColumnLayout;
                field(SourceColumnLayoutName; OldName[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Column Layout Name';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing column layout in the package.';
                }
                field(NewColumnLayoutName; NewName[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Column Layout Name';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new column layout after importing.';
                    trigger OnValidate()
                    begin
                        CheckColumnLayoutAlreadyExists();
                        CurrPage.Update();
                    end;
                }
                field(AlreadyExistsColumnLayoutText; AlreadyExistsColumnLayoutTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                }
            }
        }
    }

    var
        OldName: array[2] of Code[10];
        NewName: array[2] of Code[10];
        ShowColumnLayout: Boolean;
        AlreadyExistsTxt: Text;
        AlreadyExistsColumnLayoutTxt: Text;
        AlreadyExistsErr: Label 'Account schedule %1 will be overwritten.', Comment = '%1 - name of the account schedule.';
        AlreadyExistsColumnLayoutErr: Label 'Column layout %1 will be overwritten.', Comment = '%1 - name of the column layout.';

    procedure Set(Name: Code[10]; ColumnLayout: Code[10])
    begin
        OldName[1] := Name;
        NewName[1] := Name;
        OldName[2] := ColumnLayout;
        NewName[2] := ColumnLayout;
        ShowColumnLayout := ColumnLayout <> '';
        CheckAlreadyExists();
    end;

    procedure GetName(): Code[10]
    begin
        exit(NewName[1]);
    end;

    procedure GetColumnLayoutName(): Code[10]
    begin
        if ShowColumnLayout then
            exit(NewName[2]);
    end;

    local procedure CheckAlreadyExists()
    begin
        CheckAccScheduleAlreadyExists();
        CheckColumnLayoutAlreadyExists();
    end;

    local procedure CheckAccScheduleAlreadyExists()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AlreadyExistsTxt := '';
        if AccScheduleName.Get(NewName[1]) then
            AlreadyExistsTxt := StrSubstNo(AlreadyExistsErr, NewName[1]);
    end;

    local procedure CheckColumnLayoutAlreadyExists()
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        AlreadyExistsColumnLayoutTxt := '';
        if ShowColumnLayout then
            if ColumnLayoutName.Get(NewName[2]) then
                AlreadyExistsColumnLayoutTxt := StrSubstNo(AlreadyExistsColumnLayoutErr, NewName[2]);
    end;
}