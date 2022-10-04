#if not CLEAN21
xmlport 9173 "Export Permission Sets"
{
    Caption = 'Export Permission Sets';
    Direction = Export;
    Encoding = UTF8;
    PreserveWhiteSpace = true;
    UseRequestPage = false;
    ObsoleteTag = '21.0';
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with "Export Permission Sets Tenant" or "Export Permission Sets System"';

    schema
    {
        textelement(PermissionSets)
        {
            tableelement("Aggregate Permission Set"; "Aggregate Permission Set")
            {
                MinOccurs = Zero;
                XmlName = 'PermissionSet';
                fieldattribute(AppID; "Aggregate Permission Set"."App ID")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if ExportInExtensionSchema = true then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(RoleID; "Aggregate Permission Set"."Role ID")
                {
                }
                fieldattribute(RoleName; "Aggregate Permission Set".Name)
                {
                }
                fieldattribute(Scope; "Aggregate Permission Set".Scope)
                {
                }
                tableelement(Permission; Permission)
                {
                    LinkFields = "Role ID" = FIELD("Role ID");
                    LinkTable = "Aggregate Permission Set";
                    MinOccurs = Zero;
                    XmlName = 'Permission';
                    SourceTableView = SORTING("Role ID", "Object Type", "Object ID");
                    fieldelement(ObjectType; Permission."Object Type")
                    {
                    }
                    fieldelement(ObjectID; Permission."Object ID")
                    {
                    }
                    fieldelement(ReadPermission; Permission."Read Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if Permission."Read Permission" = Permission."Read Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(InsertPermission; Permission."Insert Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if Permission."Insert Permission" = Permission."Insert Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(ModifyPermission; Permission."Modify Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if Permission."Modify Permission" = Permission."Modify Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(DeletePermission; Permission."Delete Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if Permission."Delete Permission" = Permission."Delete Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(ExecutePermission; Permission."Execute Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if Permission."Execute Permission" = Permission."Execute Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(SecurityFilter; Permission."Security Filter")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if Format(Permission."Security Filter") = '' then
                                currXMLport.Skip();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "Aggregate Permission Set".Scope <> "Aggregate Permission Set".Scope::System then
                            currXMLport.Skip();
                    end;
                }
                tableelement("Expanded Permission"; "Expanded Permission")
                {
                    LinkFields = "App ID" = FIELD("App ID"), "Role ID" = FIELD("Role ID"), Scope = FIELD(Scope);
                    LinkTable = "Aggregate Permission Set";
                    MinOccurs = Zero;
                    XmlName = 'TenantPermission';
                    SourceTableView = SORTING("App ID", "Role ID", "Object Type", "Object ID");
                    fieldelement(ObjectType; "Expanded Permission"."Object Type")
                    {
                    }
                    fieldelement(ObjectID; "Expanded Permission"."Object ID")
                    {
                    }
                    fieldelement(ReadPermission; "Expanded Permission"."Read Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if "Expanded Permission"."Read Permission" = "Expanded Permission"."Read Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(InsertPermission; "Expanded Permission"."Insert Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if "Expanded Permission"."Insert Permission" = "Expanded Permission"."Insert Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(ModifyPermission; "Expanded Permission"."Modify Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if "Expanded Permission"."Modify Permission" = "Expanded Permission"."Modify Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(DeletePermission; "Expanded Permission"."Delete Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if "Expanded Permission"."Delete Permission" = "Expanded Permission"."Delete Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(ExecutePermission; "Expanded Permission"."Execute Permission")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if "Expanded Permission"."Execute Permission" = "Expanded Permission"."Execute Permission"::" " then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(SecurityFilter; "Expanded Permission"."Security Filter")
                    {
                        MinOccurs = Zero;

                        trigger OnBeforePassField()
                        begin
                            if Format("Expanded Permission"."Security Filter") = '' then
                                currXMLport.Skip();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "Aggregate Permission Set".Scope <> "Aggregate Permission Set".Scope::Tenant then
                            currXMLport.Skip();
                    end;
                }
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

    var
        ExportInExtensionSchema: Boolean;

    procedure SetExportToExtensionSchema(ExtensionSchema: Boolean)
    begin
        ExportInExtensionSchema := ExtensionSchema;
    end;
}
#endif