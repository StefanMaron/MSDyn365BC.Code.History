page 594 "Change Log Setup (Field) List"
{
    Caption = 'Change Log Setup (Field) List';
    DataCaptionExpression = PageCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Field";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the field.';
                }
                field("Field Caption"; "Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the caption of the field, that is, the name that will be shown in the user interface.';
                }
                field("Log Insertion"; LogIns)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Insertion';
                    ToolTip = 'Specifies whether to log the insertion for the selected line on the change log.';
                    Visible = LogInsertionVisible;
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;

                    trigger OnValidate()
                    begin
                        if not InsVisible then begin
                            LogInsertionVisible := false;
                            Error(CannotChangeColumnErr);
                        end;
                        UpdateRec;
                    end;
                }
                field("Log Modification"; LogMod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Modification';
                    ToolTip = 'Specifies whether to log the modification for the selected line on the change log.';
                    Visible = LogModificationVisible;
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;

                    trigger OnValidate()
                    begin
                        if not ModVisible then begin
                            LogModificationVisible := false;
                            Error(CannotChangeColumnErr);
                        end;
                        UpdateRec;
                    end;
                }
                field("Log Deletion"; LogDel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Deletion';
                    ToolTip = 'Specifies whether to log the deletion for the selected line on the change log.';
                    Visible = LogDeletionVisible;
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;

                    trigger OnValidate()
                    begin
                        if not DelVisible then begin
                            LogDeletionVisible := false;
                            Error(CannotChangeColumnErr);
                        end;
                        UpdateRec;
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        PageIsEditable := CurrPage.Editable();
        GetRec;
        TransFromRec;
    end;

    trigger OnAfterGetRecord()
    begin
        GetRec;
        TransFromRec;
    end;

    trigger OnInit()
    begin
        LogDeletionVisible := true;
        LogModificationVisible := true;
        LogInsertionVisible := true;
    end;

    trigger OnOpenPage()
    begin
        FilterGroup(2);
        SetRange(Class, Class::Normal);
        FilterGroup(0);
        PageCaption := Format(TableNo) + ' ' + TableName;
    end;

    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        CannotChangeColumnErr: Label 'You cannot change this column.';
        LogIns: Boolean;
        LogMod: Boolean;
        LogDel: Boolean;
        InsVisible: Boolean;
        ModVisible: Boolean;
        DelVisible: Boolean;
        [InDataSet]
        LogInsertionVisible: Boolean;
        [InDataSet]
        LogModificationVisible: Boolean;
        [InDataSet]
        LogDeletionVisible: Boolean;
        PageCaption: Text[250];
        PageIsEditable: Boolean;

    procedure SelectColumn(NewInsVisible: Boolean; NewModVisible: Boolean; NewDelVisible: Boolean)
    begin
        InsVisible := NewInsVisible;
        ModVisible := NewModVisible;
        DelVisible := NewDelVisible;

        LogInsertionVisible := InsVisible;
        LogModificationVisible := ModVisible;
        LogDeletionVisible := DelVisible;
    end;

    local procedure UpdateRec()
    begin
        GetRec;
        TransToRec;
        with ChangeLogSetupField do
            if not ("Log Insertion" or "Log Modification" or "Log Deletion") then begin
                if Delete then;
            end else
                if not Modify then
                    Insert;
    end;

    local procedure GetRec()
    begin
        if not ChangeLogSetupField.Get(TableNo, "No.") then begin
            ChangeLogSetupField.Init();
            ChangeLogSetupField."Table No." := TableNo;
            ChangeLogSetupField."Field No." := "No.";
        end;
    end;

    local procedure TransFromRec()
    begin
        LogIns := ChangeLogSetupField."Log Insertion";
        LogMod := ChangeLogSetupField."Log Modification";
        LogDel := ChangeLogSetupField."Log Deletion";
    end;

    local procedure TransToRec()
    begin
        ChangeLogSetupField."Log Insertion" := LogIns;
        ChangeLogSetupField."Log Modification" := LogMod;
        ChangeLogSetupField."Log Deletion" := LogDel;
    end;
}

