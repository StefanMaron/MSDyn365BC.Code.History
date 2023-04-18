page 105 "New Account Schedule Name"
{
    Caption = 'New Row Definition';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(AccountSheduleGroup)
            {
                Caption = 'Row definition';
                field(SourceAccountScheduleName; OldName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Row Definition';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing row definition in the package.';
                }
                field(NewAccountScheduleName; NewName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Row Definition';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new row definition after importing.';
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
#if not CLEAN22
            group(ColumnLayoutGroup)
            {
                Caption = 'Default Column Layout';
                Visible = false;
                ObsoleteReason = 'Columns have been moved to FinancialReports page, extend NewFinancialReport.Page.al instead';
                ObsoleteTag = '22.0';
                ObsoleteState = Pending;
                field(SourceColumnLayoutName; '')
                {
                    ObsoleteReason = 'Columns have been moved to FinancialReports page, extend NewFinancialReport.Page.al instead';
                    ObsoleteTag = '22.0';
                    ObsoleteState = Pending;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Column Layout Name';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing column layout in the package.';
                }
                field(NewColumnLayoutName; '')
                {
                    ObsoleteReason = 'Columns have been moved to FinancialReports page, extend NewFinancialReport.Page.al instead';
                    ObsoleteTag = '22.0';
                    ObsoleteState = Pending;
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Column Layout Name';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new column layout after importing.';
                }
                field(AlreadyExistsColumnLayoutText; '')
                {
                    ObsoleteReason = 'Columns have been moved to FinancialReports page, extend NewFinancialReport.Page.al instead';
                    ObsoleteTag = '22.0';
                    ObsoleteState = Pending;
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                }
            }
#endif
        }
    }

    var
        OldName: Code[10];
        NewName: Code[10];
        AlreadyExistsTxt: Text;
        AlreadyExistsErr: Label 'Row definition %1 will be overwritten.', Comment = '%1 - name of the row definition.';

    procedure Set(Name: Code[10])
    begin
        OldName := Name;
        NewName := Name;
        CheckAlreadyExists();
    end;

#if not CLEAN22
    [Obsolete('Use Set only with the Name parameter now. Column definition is now stored in Financial Report.', '22.0')]
    procedure Set(Name: Code[10]; ColumnLayout: Code[10])
    begin
        Set(Name);
        CheckAlreadyExists();
    end;
#endif

    procedure GetName(): Code[10]
    begin
        exit(NewName);
    end;

#if not CLEAN22
    [Obsolete('Column definition is now stored in Financial Report.', '22.0')]
    procedure GetColumnLayoutName(): Code[10]
    begin
    end;
#endif

    local procedure CheckAlreadyExists()
    begin
        CheckAccScheduleAlreadyExists();
    end;

    local procedure CheckAccScheduleAlreadyExists()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AlreadyExistsTxt := '';
        if AccScheduleName.Get(NewName) then
            AlreadyExistsTxt := StrSubstNo(AlreadyExistsErr, NewName);
    end;

}