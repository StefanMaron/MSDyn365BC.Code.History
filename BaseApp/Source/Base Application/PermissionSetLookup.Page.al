#if not CLEAN20
page 9841 "Permission Set Lookup"
{
    Caption = 'Permission Set Lookup';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Aggregate Permission Set";
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
    ObsoleteReason = 'Use page Lookup Permission Set from System Application';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a permission set that defines the role.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the permission set.';
                }
                field("App Name"; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    ToolTip = 'Specifies the name of the extension that provides the permission set.';
                }
                field(Scope; Scope)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the permission set is specific to your tenant or generally available in the system.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SelectedRecord := Rec;
    end;

    var
        SelectedRecord: Record "Aggregate Permission Set";

    procedure GetSelectedRecord(var CurrSelectedRecord: Record "Aggregate Permission Set")
    begin
        CurrSelectedRecord := SelectedRecord;
    end;
}
#endif