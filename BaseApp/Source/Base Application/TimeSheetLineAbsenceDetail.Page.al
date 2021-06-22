page 969 "Time Sheet Line Absence Detail"
{
    Caption = 'Time Sheet Line Absence Detail';
    PageType = StandardDialog;
    SourceTable = "Time Sheet Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Cause of Absence Code"; "Cause of Absence Code")
                {
                    ApplicationArea = Jobs, BasicHR;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies a list of standard absence codes, from which you may select one.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies a description of the time sheet line.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        AllowEdit := GetAllowEdit(0, ManagerRole);
    end;

    var
        ManagerRole: Boolean;
        AllowEdit: Boolean;

    procedure SetParameters(TimeSheetLine: Record "Time Sheet Line"; NewManagerRole: Boolean)
    begin
        Rec := TimeSheetLine;
        Insert;
        ManagerRole := NewManagerRole;
    end;
}

