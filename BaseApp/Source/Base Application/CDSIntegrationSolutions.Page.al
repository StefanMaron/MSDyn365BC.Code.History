page 7204 "CDS Integration Solutions"
{
    Caption = 'Common Data Service Integration Solutions', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "CDS Solution";
    SourceTableTemporary = true;
    SourceTableView = SORTING(FriendlyName);

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;

                field(UniqueName; UniqueName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Unique Name';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(Name; FriendlyName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Friendly Name';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(Version; Version)
                {
                    ApplicationArea = Suite;
                    Caption = 'Version';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(InstalledOn; InstalledOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Installed On';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(IsManaged; IsManaged)
                {
                    ApplicationArea = Suite;
                    Caption = 'Managed';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if InstalledOn <> 0DT then
            StyleExpression := 'Favorable'
        else
            StyleExpression := 'Unfavorable';
    end;

    trigger OnInit()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSSolution: Record "CDS Solution";
        SolutionUniqueNameList: List of [Text];
        SolutionUniqueName: Text[50];
        TempConnectionName: Text;
    begin
        CDSConnectionSetup.Get();
        CDSIntegrationImpl.CheckConnectionRequiredFields(CDSConnectionSetup, false);

        CDSIntegrationImpl.GetIntegrationSolutions(SolutionUniqueNameList);
        if SolutionUniqueNameList.Count() = 0 then
            exit;

        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        CDSIntegrationImpl.RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        foreach SolutionUniqueName in SolutionUniqueNameList do begin
            Init();
            CDSSolution.SetRange(UniqueName, SolutionUniqueName);
            if CDSSolution.FindFirst() then
                TransferFields(CDSSolution)
            else
                UniqueName := SolutionUniqueName;
            Insert();
        end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        StyleExpression: Text;
}

