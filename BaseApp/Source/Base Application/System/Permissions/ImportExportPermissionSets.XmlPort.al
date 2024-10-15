namespace System.Security.AccessControl;

xmlport 9171 "Import/Export Permission Sets"
{
    Caption = 'Import/Export Permission Sets';
    Format = VariableText;

    schema
    {
        textelement(Root)
        {
            tableelement("Permission Set"; "Permission Set")
            {
                XmlName = 'UserRole';
                fieldelement(RoleID; "Permission Set"."Role ID")
                {
                }
                fieldelement(Name; "Permission Set".Name)
                {
                }
            }
            tableelement("Tenant Permission Set"; "Tenant Permission Set")
            {
                MinOccurs = Zero;
                XmlName = 'UserRoleTenant';
                fieldelement(TenantRoleID; "Tenant Permission Set"."Role ID")
                {
                }
                fieldelement(TenantName; "Tenant Permission Set".Name)
                {
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
}

