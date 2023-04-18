page 703 "Merge Duplicate Subform"
{
    Caption = 'Merge Duplicate Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Merge Duplicates Line Buffer";
    SourceTableTemporary = true;
    SourceTableView = SORTING("In Primary Key");

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = "In Primary Key" = "In Primary Key"::Yes;
                    ToolTip = 'Specifies the ID of the table.';
                    Visible = IsTableLine;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = "In Primary Key" = "In Primary Key"::Yes;
                    ToolTip = 'Specifies the name of the table.';
                    Visible = IsTableLine;
                }
                field(ID; ID)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleExpr;
                    ToolTip = 'Specifies the ID of the field.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    Editable = false;
                    StyleExpr = StyleExpr;
                    ToolTip = 'Specifies the name of the field.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type of the field.';
                    Visible = NOT IsTableLine;
                }
                field("In Primary Key"; Rec."In Primary Key")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the field is part of the primary key.';
                }
                field("Current Value"; Rec."Current Value")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value of the field in the current record.';
                    Visible = NOT IsTableLine;
                }
                field("Current Count"; Rec."Current Count")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of records related to the current record.';
                    Visible = IsTableLine;
                }
                field(Override; Override)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsOverrideEnabled;
                    ToolTip = 'Specifies if the field value of the current record should be overridden by the value of the duplicate record. ';
                    Visible = NOT IsTableLine;

                    trigger OnValidate()
                    begin
                        SetStyle();
                        CurrPage.Update();
                    end;
                }
                field("Duplicate Value"; Rec."Duplicate Value")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Alternate Value';
                    Editable = IsFieldEditable;
                    Style = Strong;
                    StyleExpr = Override OR Modified;
                    ToolTip = 'Specifies the value of the field in the duplicate record.';
                    Visible = NOT IsTableLine;

                    trigger OnValidate()
                    begin
                        SetStyle();
                        CurrPage.Update();
                    end;
                }
                field("Duplicate Count"; Rec."Duplicate Count")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of records related to the duplicate record.';
                    Visible = IsTableLine;
                }
                field(Conflicts; Conflicts)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = Conflicts > 0;
                    ToolTip = 'Specifies if conflicting records exist.';
                    Visible = IsTableLine;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if "Can Be Renamed" then begin
            IsFieldEditable := not HasFieldToOverride();
            IsOverrideEnabled := false;
        end else begin
            IsOverrideEnabled := not HasModifiedField();
            IsFieldEditable := false;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        IsTableLine := Type = Type::Table;
        SetStyle();
    end;

    var
        StyleExpr: Text;
        IsTableLine: Boolean;
        IsFieldEditable: Boolean;
        IsOverrideEnabled: Boolean;

    procedure Set(var TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary)
    begin
        Copy(TempMergeDuplicatesLineBuffer, true);
        FilterGroup(2);
        TempMergeDuplicatesLineBuffer.CopyFilter(Type, Type);
        FilterGroup(0);
        if FindFirst() then;
    end;

    local procedure SetStyle()
    begin
        if Override then
            StyleExpr := 'StrongAccent'
        else
            if "In Primary Key" = "In Primary Key"::Yes then
                if Modified then
                    StyleExpr := 'Attention'
                else
                    StyleExpr := 'Strong'
            else
                StyleExpr := 'Standard';
    end;
}

