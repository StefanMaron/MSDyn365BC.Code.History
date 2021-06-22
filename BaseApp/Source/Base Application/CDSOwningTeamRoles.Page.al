page 7206 "CDS Owning Team Roles"
{
    Caption = 'Common Data Service Owning Team Roles', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "CRM Role";
    SourceTableTemporary = true;
    SourceTableView = SORTING(Name);

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;

                field("Role Name"; Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Role Name';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(Assigned; IsAssigned)
                {
                    ApplicationArea = Suite;
                    Caption = 'Assigned';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not BusinessUnitRequiredRoles.ContainsKey(RoleId) then begin
            StyleExpression := '';
            exit;
        end;

        IsAssigned := not IsNullGuid(SolutionId);
        if IsAssigned then
            StyleExpression := 'Favorable'
        else
            StyleExpression := 'Unfavorable';
    end;

    trigger OnInit()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CrmTeam: Record "CRM Team";
        CDSTeamroles: Record "CDS Teamroles";
        CRMRole: Record "CRM Role";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        BusinessUnitCollectedRoles: Dictionary of [Guid, Boolean];
        OrganizationRequiredRoleIdList: List of [Guid];
        DefaultOwningTeamId: Guid;
        DefaultOwningBusinessUnitId: Guid;
        OrganisationRequiredRoleName: Text;
        OrganizationRequiredRoleId: Guid;
        BusinessUnitRequiredRoleId: Guid;
        TempConnectionName: Text;
    begin
        CDSConnectionSetup.Get();
        CDSIntegrationImpl.CheckConnectionRequiredFields(CDSConnectionSetup, false);

        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        CDSIntegrationImpl.RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        DefaultOwningTeamId := CDSIntegrationImpl.GetOwningTeamId(CDSConnectionSetup);
        if not IsNullGuid(DefaultOwningTeamId) then
            if CRMTeam.Get(DefaultOwningTeamId) then begin
                DefaultOwningBusinessUnitId := CRMTeam.BusinessUnitId;
                CDSTeamroles.SetRange(TeamId, DefaultOwningTeamId);
                if CDSTeamroles.FindSet() then
                    repeat
                        CRMRole.SetRange(RoleId, CDSTeamroles.RoleId);
                        if CRMRole.FindFirst() then begin
                            Init();
                            TransferFields(CRMRole);
                            Insert();
                            BusinessUnitCollectedRoles.Add(CDSTeamroles.RoleId, true);
                        end;
                    until CDSTeamroles.Next() = 0;
            end;

        CDSIntegrationImpl.GetIntegrationRequiredRoles(OrganizationRequiredRoleIdList);
        foreach OrganizationRequiredRoleId in OrganizationRequiredRoleIdList do
            if CRMRole.Get(OrganizationRequiredRoleId) then begin
                OrganisationRequiredRoleName := CRMRole.Name;
                CRMRole.Reset();
                CrmRole.SetRange(BusinessUnitId, DefaultOwningBusinessUnitId);
                CRMRole.SetRange(ParentRoleId, OrganizationRequiredRoleId);
                if CRMRole.FindFirst() then begin
                    if not BusinessUnitRequiredRoles.ContainsKey(CRMRole.RoleId) then
                        BusinessUnitRequiredRoles.Add(CRMRole.RoleId, CRMRole.Name);
                end else
                    if not BusinessUnitRequiredRoles.ContainsKey(OrganizationRequiredRoleId) then
                        BusinessUnitRequiredRoles.Add(OrganizationRequiredRoleId, OrganisationRequiredRoleName);
            end;


        foreach BusinessUnitRequiredRoleId in BusinessUnitRequiredRoles.Keys() do
            if not BusinessUnitCollectedRoles.ContainsKey(BusinessUnitRequiredRoleId) then begin
                Init();
                RoleId := BusinessUnitRequiredRoleId;
                Name := CopyStr(BusinessUnitRequiredRoles.Get(BusinessUnitRequiredRoleId), 1, MaxStrLen(Name));
                Insert();
                BusinessUnitCollectedRoles.Add(RoleId, true);
            end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    var
        BusinessUnitRequiredRoles: Dictionary of [Guid, Text];
        IsAssigned: Boolean;
        StyleExpression: Text;
}

