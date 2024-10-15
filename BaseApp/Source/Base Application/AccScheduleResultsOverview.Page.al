#if not CLEAN19
page 31089 "Acc. Schedule Results Overview"
{
    Caption = 'Acc. Schedule Results Overview (Obsolete)';
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Acc. Schedule Result Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Result Code"; Rec."Result Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of account schedule results.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of account schedule results.';
                }
                field("Date Filter"; Rec."Date Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date filter of account schedule results.';
                }
                field("Acc. Schedule Name"; Rec."Acc. Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the account schedule.';
                }
                field("Column Layout Name"; Rec."Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the column layout that you want to use in the window.';
                }
            }
            part(SubForm; "Acc. Sch. Res. Subform Matrix")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Result Code" = FIELD("Result Code");
            }
            group("Dimension Filters")
            {
                Caption = 'Dimension Filters';
                field("Dimension 1 Filter"; Rec."Dimension 1 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies dimensions which was used by account schedule results creating.';
                }
                field("Dimension 2 Filter"; Rec."Dimension 2 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies dimensions which was used by account schedule results creating.';
                }
                field("Dimension 3 Filter"; Rec."Dimension 3 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies dimensions which was used by account schedule results creating.';
                }
                field("Dimension 4 Filter"; Rec."Dimension 4 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies dimensions which was used by account schedule results creating.';
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Result Date"; Rec."Result Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the created date of account schedule results.';
                }
                field("Result Time"; Rec."Result Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the created time of account schedule results.';
                }
                field(ShowOnlyChangedValues; ShowOnlyChangedValues)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Only Changed Values';
                    ToolTip = 'Specifies when the only changed values are to be show';

                    trigger OnValidate()
                    begin
                        ShowOnlyChangedValuesOnAfterVa();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Allows print the account schedule results.';

                    trigger OnAction()
                    var
                        AccScheduleResultHeader: Record "Acc. Schedule Result Header";
                    begin
                        AccScheduleResultHeader := Rec;
                        AccScheduleResultHeader.SetRecFilter();
                        REPORT.RunModal(REPORT::"Account Schedule Result", true, false, AccScheduleResultHeader);
                    end;
                }
                action("Export to Excel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Excel';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Allows the account schedule results export to excel.';

                    trigger OnAction()
                    var
                        ExpAccSchedResToExcel: Report "Exp. Acc. Sched. Res. to Excel";
                    begin
                        ExpAccSchedResToExcel.SetOptions("Result Code", false);
                        ExpAccSchedResToExcel.Run();
                    end;
                }
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of the account schedule results.';

                trigger OnAction()
                begin
                    MATRIX_SetWanted := MATRIX_SetWanted::Next;
                    UpdateColumnSet();
                    CurrPage.SubForm.PAGE.Load(MATRIX_ColumnSet, MATRIX_ColumnCaption);
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Previous Set';

                trigger OnAction()
                begin
                    MATRIX_SetWanted := MATRIX_SetWanted::Previous;
                    UpdateColumnSet();
                    CurrPage.SubForm.PAGE.Load(MATRIX_ColumnSet, MATRIX_ColumnCaption);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if xRec."Result Code" <> "Result Code" then
            MATRIX_SetWanted := MATRIX_SetWanted::Initial;
        UpdateColumnSet();
        CurrPage.SubForm.PAGE.Load(MATRIX_ColumnSet, MATRIX_ColumnCaption);
    end;

    var
        ShowOnlyChangedValues: Boolean;
        MATRIX_SetWanted: Option Initial,Next,Previous,Same;
        StackCounter: Integer;
        MATRIX_ColumnSet: array[4] of Integer;
        MATRIX_ColumnCaption: array[4] of Text[1024];

    [Scope('OnPrem')]
    procedure UpdateColumnSet()
    var
        AccSchedResultColumn: Record "Acc. Schedule Result Column";
    begin
        AccSchedResultColumn.Reset();
        AccSchedResultColumn.SetRange("Result Code", "Result Code");

        case MATRIX_SetWanted of
            MATRIX_SetWanted::Initial:
                begin
                    MATRIX_SetWanted := MATRIX_SetWanted::Same;
                    if AccSchedResultColumn.FindFirst() then begin
                        Clear(MATRIX_ColumnSet);
                        ClearMATRIX_ColumnCaption();
                        for StackCounter := 1 to 4 do begin
                            MATRIX_ColumnSet[StackCounter] := AccSchedResultColumn."Line No.";
                            MATRIX_ColumnCaption[StackCounter] := GetColumnName(MATRIX_ColumnSet[StackCounter]);
                            if AccSchedResultColumn.Next() = 0 then
                                exit;
                        end;
                    end;
                end;
            MATRIX_SetWanted::Next:
                begin
                    MATRIX_SetWanted := MATRIX_SetWanted::Same;
                    if MATRIX_ColumnSet[4] <> 0 then
                        AccSchedResultColumn.SetFilter("Line No.", '%1..', MATRIX_ColumnSet[4])
                    else
                        exit;
                    if AccSchedResultColumn.FindFirst() then
                        for StackCounter := 1 to 4 do begin
                            if AccSchedResultColumn.Next() = 0 then
                                exit;
                            if (StackCounter = 1) and (AccSchedResultColumn."Line No." <> MATRIX_ColumnSet[4]) then begin
                                Clear(MATRIX_ColumnSet);
                                ClearMATRIX_ColumnCaption();
                            end;
                            MATRIX_ColumnSet[StackCounter] := AccSchedResultColumn."Line No.";
                            MATRIX_ColumnCaption[StackCounter] := GetColumnName(MATRIX_ColumnSet[StackCounter]);
                        end;
                end;
            MATRIX_SetWanted::Previous:
                begin
                    MATRIX_SetWanted := MATRIX_SetWanted::Same;
                    if MATRIX_ColumnSet[1] <> 0 then
                        AccSchedResultColumn.SetFilter("Line No.", '..%1', MATRIX_ColumnSet[1])
                    else
                        exit;
                    if AccSchedResultColumn.FindLast() then
                        AccSchedResultColumn.Next := -4;
                    if AccSchedResultColumn."Line No." <> MATRIX_ColumnSet[1] then begin
                        Clear(MATRIX_ColumnSet);
                        ClearMATRIX_ColumnCaption();
                        for StackCounter := 1 to 4 do begin
                            MATRIX_ColumnSet[StackCounter] := AccSchedResultColumn."Line No.";
                            MATRIX_ColumnCaption[StackCounter] := GetColumnName(MATRIX_ColumnSet[StackCounter]);
                            if AccSchedResultColumn.Next() = 0 then
                                exit;
                        end;
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetColumnName(ColumnNo: Integer): Text[1024]
    var
        AccSchedResultCol: Record "Acc. Schedule Result Column";
    begin
        AccSchedResultCol.SetRange("Result Code", "Result Code");
        AccSchedResultCol.SetRange("Line No.", ColumnNo);
        if AccSchedResultCol.FindFirst() then
            exit(AccSchedResultCol."Column Header");
        exit('');
    end;

    [Scope('OnPrem')]
    procedure ClearMATRIX_ColumnCaption()
    var
        i: Integer;
    begin
        for i := 1 to 4 do
            MATRIX_ColumnCaption[i] := '';
    end;

    local procedure ShowOnlyChangedValuesOnAfterVa()
    begin
        CurrPage.SubForm.PAGE.SetShowOnlyChangeValue(ShowOnlyChangedValues);
    end;
}
#endif
