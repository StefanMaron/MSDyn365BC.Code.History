xmlport 9172 "Import/Export Permissions"
{
    Caption = 'Import/Export Permissions';
    Format = VariableText;

    schema
    {
        textelement(Root)
        {
            tableelement(Permission; Permission)
            {
                XmlName = 'Permission';
                fieldelement(RoleID; Permission."Role ID")
                {
                    FieldValidate = no;
                }
                fieldelement(RoleName; Permission."Role Name")
                {
                }
                fieldelement(ObjectType; Permission."Object Type")
                {
                }
                fieldelement(ObjectID; Permission."Object ID")
                {
                    FieldValidate = no;
                }
                fieldelement(ObjectName; Permission."Object Name")
                {
                }
                fieldelement(ReadPermission; Permission."Read Permission")
                {
                }
                fieldelement(InsertPermission; Permission."Insert Permission")
                {
                }
                fieldelement(ModifyPermission; Permission."Modify Permission")
                {
                }
                fieldelement(DeletePermission; Permission."Delete Permission")
                {
                }
                fieldelement(ExecutePermission; Permission."Execute Permission")
                {
                }
                fieldelement(SecurityFilter; Permission."Security Filter")
                {
                }

                trigger OnBeforeInsertRecord()
                begin
                    if (RoleID <> '') and (Permission."Role ID" <> RoleID) then
                        currXMLport.Skip();

                    if Permission.Get(Permission."Role ID", Permission."Object Type", Permission."Object ID") then
                        currXMLport.Skip();

                    InsertPermissionSet(Permission);
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
    begin
        if Permission.GetFilter("Role ID") <> '' then
            RoleID := Permission.GetRangeMin("Role ID");
    end;

    var
        RoleID: Code[20];

    local procedure InsertPermissionSet(Permission: Record Permission)
    var
        PermissionSet: Record "Permission Set";
    begin
        if not PermissionSet.Get(Permission."Role ID") then begin
            PermissionSet.Init();
            PermissionSet."Role ID" := Permission."Role ID";
            PermissionSet.Name := Permission."Role Name";
            PermissionSet.Insert();
        end;
    end;
}

