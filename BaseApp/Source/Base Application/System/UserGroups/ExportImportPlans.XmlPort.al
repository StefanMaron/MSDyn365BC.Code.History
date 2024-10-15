#if not CLEAN22
namespace System.Security.AccessControl;

xmlport 9010 "Export/Import Plans"
{
    Caption = 'Export/Import Plans';
    UseRequestPage = false;
    Direction = Import;
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Default permission sets per plan are defined using the Plan Configuration codeunit. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    schema
    {
        textelement(entitlements)
        {
            textelement(Plan)
            {
                XmlName = 'entitlement';
                textelement(type)
                {
                }
                textelement(id)
                {
                }
                textelement(name)
                {
                }
                textelement(entitlementSetId)
                {
                }
                textelement(entitlementSetName)
                {
                }
                textelement(isEvaluation)
                {
                }
                textelement(roleCenterId)
                {
                }
                textelement(includeDynamicsExtensions)
                {
                }
                textelement(includeFreeRange)
                {
                }
                textelement(includeInfrastructure)
                {
                }
                tableelement("User Group Plan"; "User Group Plan")
                {
                    XmlName = 'relatedUserGroup';
                    fieldattribute(setId; "User Group Plan"."User Group Code")
                    {
                    }
                    textattribute(onlylicensetxt)
                    {
                        Occurrence = Optional;
                        XmlName = 'onlyLicense';

                        trigger OnAfterAssignVariable()
                        begin
                            Evaluate(OnlyLicenseVar, onlyLicenseTxt);
                        end;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        OnlyLicenseVar := false;
                    end;

                    trigger OnBeforeInsertRecord()
                    var
                        UserGroupPlan: Record "User Group Plan";
                    begin
                        if OnlyLicenseVar or UserGroupPlan.Get(id, "User Group Plan"."User Group Code") then
                            currXMLport.Skip();
                        "User Group Plan"."Plan ID" := id;
                    end;
                }
                textelement(licenseGroup)
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

    var
        OnlyLicenseVar: Boolean;
}

#endif