page 593 "Change Log Setup (Table) List"
{
    Caption = 'Change Log Setup (Table) List';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = true;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ID';
                    Editable = false;
                    ToolTip = 'Specifies the ID of the table. ';
                }
                field("Object Caption"; "Object Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the table.';
                }
                field(LogInsertion; ChangeLogSetupTable."Log Insertion")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Insertion';
                    OptionCaption = ' ,Some Fields,All Fields';
                    ToolTip = 'Specifies where insertions of new data are logged. Blank: No insertions in any fields are logged. Some fields: Insertions are logged for selected fields. All fields: Insertions are logged for all fields.';

                    trigger OnAssistEdit()
                    begin
                        with ChangeLogSetupTable do
                            TestField("Log Insertion", "Log Insertion"::"Some Fields");
                        AssistEdit;
                    end;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        NewValue: Option;
                    begin
                        if ChangeLogSetupTable."Table No." <> "Object ID" then begin
                            NewValue := ChangeLogSetupTable."Log Insertion";
                            GetRec;
                            ChangeLogSetupTable."Log Insertion" := NewValue;
                        end;

                        if xChangeLogSetupTable.Get(ChangeLogSetupTable."Table No.") then begin
                            if (xChangeLogSetupTable."Log Insertion" = xChangeLogSetupTable."Log Insertion"::"Some Fields") and
                               (xChangeLogSetupTable."Log Insertion" <> ChangeLogSetupTable."Log Insertion")
                            then
                                if ConfirmManagement.GetResponseOrDefault(
                                     StrSubstNo(Text002, xChangeLogSetupTable.FieldCaption("Log Insertion"), xChangeLogSetupTable."Log Insertion"), true)
                                then
                                    ChangeLogSetupTable.DelChangeLogFields(0);
                        end;
                        ChangeLogSetupTableLogInsertio;
                    end;
                }
                field(LogModification; ChangeLogSetupTable."Log Modification")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Modification';
                    OptionCaption = ' ,Some Fields,All Fields';
                    ToolTip = 'Specifies that any modification of data is logged.';

                    trigger OnAssistEdit()
                    begin
                        with ChangeLogSetupTable do
                            TestField("Log Modification", "Log Modification"::"Some Fields");
                        AssistEdit;
                    end;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        NewValue: Option;
                    begin
                        if ChangeLogSetupTable."Table No." <> "Object ID" then begin
                            NewValue := ChangeLogSetupTable."Log Modification";
                            GetRec;
                            ChangeLogSetupTable."Log Modification" := NewValue;
                        end;

                        if xChangeLogSetupTable.Get(ChangeLogSetupTable."Table No.") then begin
                            if (xChangeLogSetupTable."Log Modification" = xChangeLogSetupTable."Log Modification"::"Some Fields") and
                               (xChangeLogSetupTable."Log Modification" <> ChangeLogSetupTable."Log Modification")
                            then
                                if ConfirmManagement.GetResponseOrDefault(
                                     StrSubstNo(Text002, xChangeLogSetupTable.FieldCaption("Log Modification"), xChangeLogSetupTable."Log Modification"), true)
                                then
                                    ChangeLogSetupTable.DelChangeLogFields(1);
                        end;
                        ChangeLogSetupTableLogModifica;
                    end;
                }
                field(LogDeletion; ChangeLogSetupTable."Log Deletion")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Deletion';
                    OptionCaption = ' ,Some Fields,All Fields';
                    ToolTip = 'Specifies that any deletion of data is logged.';

                    trigger OnAssistEdit()
                    begin
                        with ChangeLogSetupTable do
                            TestField("Log Deletion", "Log Deletion"::"Some Fields");
                        AssistEdit;
                    end;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        NewValue: Option;
                    begin
                        if ChangeLogSetupTable."Table No." <> "Object ID" then begin
                            NewValue := ChangeLogSetupTable."Log Deletion";
                            GetRec;
                            ChangeLogSetupTable."Log Deletion" := NewValue;
                        end;

                        if xChangeLogSetupTable.Get(ChangeLogSetupTable."Table No.") then begin
                            if (xChangeLogSetupTable."Log Deletion" = xChangeLogSetupTable."Log Deletion"::"Some Fields") and
                               (xChangeLogSetupTable."Log Deletion" <> ChangeLogSetupTable."Log Deletion")
                            then
                                if ConfirmManagement.GetResponseOrDefault(
                                     StrSubstNo(Text002, xChangeLogSetupTable.FieldCaption("Log Deletion"), xChangeLogSetupTable."Log Deletion"), true)
                                then
                                    ChangeLogSetupTable.DelChangeLogFields(2);
                        end;
                        ChangeLogSetupTableLogDeletion;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetRec;
    end;

    trigger OnOpenPage()
    begin
        FilterGroup(2);
        SetRange("Object Type", "Object Type"::Table);
        SetRange("Object ID", 0, 2000000000);
        FilterGroup(0);
    end;

    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        xChangeLogSetupTable: Record "Change Log Setup (Table)";
        Text002: Label 'You have changed the %1 field to no longer be %2. Do you want to remove the field selections?';

    local procedure AssistEdit()
    var
        "Field": Record "Field";
        ChangeLogSetupFieldList: Page "Change Log Setup (Field) List";
    begin
        Field.FilterGroup(2);
        Field.SetRange(TableNo, "Object ID");
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.FilterGroup(0);
        with ChangeLogSetupTable do
            ChangeLogSetupFieldList.SelectColumn(
              "Log Insertion" = "Log Insertion"::"Some Fields",
              "Log Modification" = "Log Modification"::"Some Fields",
              "Log Deletion" = "Log Deletion"::"Some Fields");
        ChangeLogSetupFieldList.SetTableView(Field);
        ChangeLogSetupFieldList.Run;
    end;

    local procedure UpdateRec()
    begin
        with ChangeLogSetupTable do
            if ("Log Insertion" = "Log Insertion"::" ") and ("Log Modification" = "Log Modification"::" ") and
               ("Log Deletion" = "Log Deletion"::" ")
            then begin
                if Delete then;
            end else
                if not Modify then
                    Insert;
    end;

    local procedure GetRec()
    begin
        if not ChangeLogSetupTable.Get("Object ID") then begin
            ChangeLogSetupTable.Init();
            ChangeLogSetupTable."Table No." := "Object ID";
        end;
    end;

    procedure SetSource()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        DeleteAll();

        AllObjWithCaption.SetCurrentKey("Object Type", "Object ID");
        AllObjWithCaption.SetRange("Object Type", "Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", 0, 2000000006);

        if AllObjWithCaption.Find('-') then
            repeat
                Rec := AllObjWithCaption;
                Insert;
            until AllObjWithCaption.Next = 0;
    end;

    local procedure ChangeLogSetupTableLogInsertio()
    begin
        UpdateRec;
    end;

    local procedure ChangeLogSetupTableLogModifica()
    begin
        UpdateRec;
    end;

    local procedure ChangeLogSetupTableLogDeletion()
    begin
        UpdateRec;
    end;
}

