page 9891 "SmartList Group Mgmt"
{
    Caption = 'SmartList Group Management';
    Extensible = false;
    PageType = StandardDialog;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            field(Group; Group)
            {
                ApplicationArea = All;
                Caption = 'Group';
                Editable = true;
                ToolTip = 'Specifies the group.';
            }
        }
    }

    procedure SetManagementRecords(var QueryManagement: Record "Designed Query Management")
    begin
        GlobalQueryManagement := QueryManagement;
        GlobalQueryManagement.Copy(QueryManagement);
    end;

    procedure BulkAssignGroup(NewGroup: Text[100])
    var
        Management: Codeunit "SmartList Mgmt";
    begin
        Management.BulkAssignGroup(GlobalQueryManagement, NewGroup);
    end;

    trigger OnOpenPage()
    begin
        if not SmartListManagement.DoesUserHaveManagementAccess(UserSecurityId()) then
            Error(UserDoesNotHaveManagementAccessErr);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction in [ACTION::OK, ACTION::LookupOK]) then
            BulkAssignGroup(Group);
    end;

    var
        GlobalQueryManagement: Record "Designed Query Management";
        SmartListManagement: Codeunit "SmartList Mgmt";
        UserDoesNotHaveManagementAccessErr: Label 'You do not have permission to manage SmartLists. Contact your system administrator.';
        Group: Text[100];
}