page 9848 "SmartList Permissions"
{
    Caption = 'SmartList Permissions';
    DelayedInsert = true;
    Extensible = false;
    PageType = List;
    PopulateAllFields = true;
    ShowFilter = false;
    SourceTable = "Designed Query Permission";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = false;

                group(GeneralSub)
                {
                    Editable = false;
                    ShowCaption = false;

                    field("Role ID"; "Role ID")
                    {
                        ApplicationArea = All;
                        Caption = 'Permission Set';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the permission set that the permission belongs to.';
                    }
                }
            }
            repeater(Group)
            {
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                    LookupPageID = "Designed Query Objects";
                    ToolTip = 'Specifies the ID of the object that the permissions apply to.';

                    trigger OnValidate()
                    begin
                        CalcFields("Object Name");
                    end;
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'SmartList Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the object that the permissions apply to.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        SetAutoCalcFields("Object Name");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        if ("Object ID" = 0) then
            exit(false);

        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();

        "App ID" := '00000000-0000-0000-0000-000000000000';
        "Read Permission" := "Read Permission"::Yes;
        "Insert Permission" := "Insert Permission"::" ";
        "Modify Permission" := "Modify Permission"::" ";
        "Delete Permission" := "Delete Permission"::" ";
        "Execute Permission" := "Execute Permission"::Yes;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
        exit(true);
    end;
}