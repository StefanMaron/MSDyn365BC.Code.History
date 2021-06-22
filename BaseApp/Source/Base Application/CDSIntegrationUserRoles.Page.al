page 7205 "CDS Integration User Roles"
{
    Caption = 'Dataverse Integration User Roles', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
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
        if not RequiredRoles.ContainsKey(RoleId) then begin
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
        CRMSystemuserroles: Record "CRM Systemuserroles";
        CDSRole: Record "CRM Role";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CollectedRoles: Dictionary of [Guid, Boolean];
        RequiredRoleIdList: List of [Guid];
        IntegrationUserId: Guid;
        RequiredRoleId: Guid;
        TempConnectionName: Text;
    begin
        CDSConnectionSetup.Get();
        CDSIntegrationImpl.CheckConnectionRequiredFields(CDSConnectionSetup, false);

        IntegrationUserId := CDSIntegrationImpl.GetIntegrationUserId(CDSConnectionSetup);

        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        CDSIntegrationImpl.RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        if not IsNullGuid(IntegrationUserId) then begin
            CRMSystemuserroles.SetRange(SystemUserId, IntegrationUserId);
            if CRMSystemuserroles.FindSet() then
                repeat
                    CDSRole.SetRange(RoleId, CRMSystemuserroles.RoleId);
                    if CDSRole.FindFirst() then begin
                        Init();
                        TransferFields(CDSRole);
                        Insert();
                        CollectedRoles.Add(RoleId, true);
                    end;
                until CRMSystemuserroles.Next() = 0;
        end;

        CDSIntegrationImpl.GetIntegrationRequiredRoles(RequiredRoleIdList);
        foreach RequiredRoleId in RequiredRoleIdList do begin
            if not RequiredRoles.ContainsKey(RequiredRoleId) then
                RequiredRoles.Add(RequiredRoleId, true);
            if not CollectedRoles.ContainsKey(RequiredRoleId) then begin
                Init();
                CDSRole.SetRange(RoleId, RequiredRoleId);
                if CDSRole.FindFirst() then
                    Name := CDSRole.Name
                else
                    Name := Format(RequiredRoleId);
                RoleId := RequiredRoleId;
                Insert();
                CollectedRoles.Add(RoleId, true);
            end;
        end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    var
        RequiredRoles: Dictionary of [Guid, Boolean];
        IsAssigned: Boolean;
        StyleExpression: Text;
}

