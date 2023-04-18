#if not CLEAN22
xmlport 9010 "Export/Import Plans"
{
    Caption = 'Export/Import Plans';
#if not CLEAN20
    Permissions = TableData "Plan Permission Set" = rimd;
#endif 
    UseRequestPage = false;
    Direction = Import;
    ObsoleteState = Pending;
    ObsoleteReason = 'The user groups functionality is deprecated. Default permission sets per plan are defined using the Plan Configuration codeunit.';
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

#if not CLEAN20
                    trigger OnAfterInsertRecord()
                    begin
                        InsertPermissionSetsFromUserGroup();
                    end;
#endif
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
#if not CLEAN20
        XLOCALTxt: Label 'Local';

    local procedure InsertPermissionSetsFromUserGroup()
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        if UserGroup.Get("User Group Plan"."User Group Code") then begin
            // make mapping between Plan and Permissionsets by using User Group
            UserGroupPermissionSet.SetRange("User Group Code", "User Group Plan"."User Group Code");
            if UserGroupPermissionSet.FindSet() then
                repeat
                    InsertPlanPermissionset(UserGroupPermissionSet."Role ID", id);
                until UserGroupPermissionSet.Next() = 0;
            InsertPlanPermissionset(XLOCALTxt, id);
        end;
        Commit();
    end;

    local procedure InsertPlanPermissionset(PermissionSetID: Code[20]; PlanId: Guid)
    var
        PlanPermissionSet: Record "Plan Permission Set";
    begin
        // do not insert Plan Permission set if doesn't exist
        Clear(PlanPermissionSet);
        if PlanPermissionSet.Get(PlanId, PermissionSetID) then
            exit;

        PlanPermissionSet.Init();
        PlanPermissionSet."Permission Set ID" := PermissionSetID;
        PlanPermissionSet."Plan ID" := UpperCase(PlanId);
        PlanPermissionSet.Insert(true);
    end;
#endif
}

#endif