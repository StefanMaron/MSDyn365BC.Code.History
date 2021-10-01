#if not CLEAN19
page 9890 "SmartList Permission Mgmt"
{
    Caption = 'SmartList Permission Management';
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Permission Set Buffer";
    SourceTableTemporary = true;
    SourceTableView = where(Type = const("User-Defined"));
    UsageCategory = None;
    RefreshOnActivate = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Permission Set';
                Editable = false;

                field(PermissionSet; "Role ID")
                {
                    ApplicationArea = All;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the permission set.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the record.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(PermissionSets)
            {
                ApplicationArea = All;
                Caption = 'Permission Sets';
                ToolTip = 'Manage permission sets that you can assign to the users of the database.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Image = Permission;

                trigger OnAction()
                var
                    PermissionSetsPage: Page "Permission Sets";
                begin
                    PermissionSetsPage.RunModal();
                    FillRecordBuffer();
                end;
            }
        }
    }

    var
        GlobalQueryManagement: Record "Designed Query Management";

    procedure SetManagementRecords(var QueryManagement: Record "Designed Query Management")
    begin
        GlobalQueryManagement := QueryManagement;
        GlobalQueryManagement.Copy(QueryManagement);
    end;

    trigger OnOpenPage()
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
        FillRecordBuffer();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Management: Codeunit "SmartList Mgmt";
    begin
        if (CloseAction in [ACTION::OK, ACTION::LookupOK]) then begin
            CurrPage.SetSelectionFilter(Rec);
            Management.BulkAddQueryPermissions(GlobalQueryManagement, Rec);
        end;
    end;
}
#endif