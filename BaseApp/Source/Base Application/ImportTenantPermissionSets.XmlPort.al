xmlport 9174 "Import Tenant Permission Sets"
{
    Caption = 'Import Tenant Permission Sets';
    Direction = Import;
    Encoding = UTF8;
    PreserveWhiteSpace = true;
    UseRequestPage = false;

    schema
    {
        textelement(PermissionSets)
        {
            MaxOccurs = Once;
            tableelement("Tenant Permission Set"; "Tenant Permission Set")
            {
                MinOccurs = Zero;
                XmlName = 'PermissionSet';
                fieldattribute(AppID; "Tenant Permission Set"."App ID")
                {
                    Occurrence = Optional;
                }
                fieldattribute(RoleID; "Tenant Permission Set"."Role ID")
                {
                }
                fieldattribute(RoleName; "Tenant Permission Set".Name)
                {
                }
                tableelement("Tenant Permission"; "Tenant Permission")
                {
                    LinkFields = "App ID" = FIELD("App ID"), "Role ID" = FIELD("Role ID");
                    LinkTable = "Tenant Permission Set";
                    MinOccurs = Zero;
                    XmlName = 'Permission';
                    fieldelement(ObjectType; "Tenant Permission"."Object Type")
                    {
                    }
                    fieldelement(ObjectID; "Tenant Permission"."Object ID")
                    {
                    }
                    fieldelement(ReadPermission; "Tenant Permission"."Read Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(InsertPermission; "Tenant Permission"."Insert Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ModifyPermission; "Tenant Permission"."Modify Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(DeletePermission; "Tenant Permission"."Delete Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ExecutePermission; "Tenant Permission"."Execute Permission")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(SecurityFilter; "Tenant Permission"."Security Filter")
                    {
                        MinOccurs = Zero;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        "Tenant Permission"."Read Permission" := "Tenant Permission"."Read Permission"::" ";
                        "Tenant Permission"."Insert Permission" := "Tenant Permission"."Insert Permission"::" ";
                        "Tenant Permission"."Modify Permission" := "Tenant Permission"."Modify Permission"::" ";
                        "Tenant Permission"."Delete Permission" := "Tenant Permission"."Delete Permission"::" ";
                        "Tenant Permission"."Execute Permission" := "Tenant Permission"."Execute Permission"::" ";
                    end;
                }

                trigger OnBeforeInsertRecord()
                var
                    TenantPermissionSet: Record "Tenant Permission Set";
                begin
                    if TenantPermissionSet.Get("Tenant Permission Set"."App ID", "Tenant Permission Set"."Role ID") then
                        Error(PermissionSetAlreadyExistsErr, "Tenant Permission Set"."Role ID");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPreXmlPort()
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers;
    end;

    var
        PermissionSetAlreadyExistsErr: Label 'Permission set %1 already exists.', Comment = '%1 = Role ID';
}

