page 9842 "User Group by Plan"
{
    Caption = 'User Group by Plan';
    Editable = false;
    LinksAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Browse';
    ShowFilter = false;
    SourceTable = "User Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SelectedCompany; SelectedCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    TableRelation = Company;
                    ToolTip = 'Specifies the company.';

                    trigger OnValidate()
                    begin
                        Company.Name := SelectedCompany;
                        if SelectedCompany <> '' then begin
                            Company.Find('=<>');
                            SelectedCompany := Company.Name;
                        end;
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Permission Set';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Group Code';
                    ToolTip = 'Specifies a user group.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Group Name';
                    ToolTip = 'Specifies the name of a user group.';
                }
                field(Column1; IsMemberOfPlan[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[1];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 1;
                }
                field(Column2; IsMemberOfPlan[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[2];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 2;
                }
                field(Column3; IsMemberOfPlan[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[3];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 3;
                }
                field(Column4; IsMemberOfPlan[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[4];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 4;
                }
                field(Column5; IsMemberOfPlan[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[5];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 5;
                }
                field(Column6; IsMemberOfPlan[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[6];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 6;
                }
                field(Column7; IsMemberOfPlan[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[7];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 7;
                }
                field(Column8; IsMemberOfPlan[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[8];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 8;
                }
                field(Column9; IsMemberOfPlan[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[9];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 9;
                }
                field(Column10; IsMemberOfPlan[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + PlanNameArray[10];
                    ToolTip = 'Specifies if the user is a member of this subscription plan.';
                    Visible = NoOfPlans >= 10;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetUserGroupPlanParameters;
    end;

    trigger OnAfterGetRecord()
    begin
        GetUserGroupPlanParameters;
    end;

    trigger OnOpenPage()
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        SelectedCompany := CompanyName;
        NoOfPlans := AzureADPlan.GetAvailablePlansCount();
        PermissionPagesMgt.Init(NoOfPlans, ArrayLen(PlanNameArray));
    end;

    var
        Company: Record Company;
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        SelectedCompany: Text[30];
        PlanNameArray: array[10] of Text[55];
        PlanIDArray: array[10] of Guid;
        IsMemberOfPlan: array[10] of Boolean;
        NoOfPlans: Integer;

    local procedure GetUserGroupPlanParameters()
    var
        Plan: Query Plan;
        columnNumber: Integer;
    begin
        Clear(PlanIDArray);
        Clear(PlanNameArray);
        Clear(IsMemberOfPlan);

        if Plan.Open() then begin
            while Plan.Read() do begin
                columnNumber += 1;
                if PermissionPagesMgt.IsInColumnsRange(columnNumber) then begin
                    PlanIDArray[columnNumber - PermissionPagesMgt.GetOffset] := Plan.Plan_ID;
                    PlanNameArray[columnNumber - PermissionPagesMgt.GetOffset] := StrSubstNo('%1 %2', 'Plan ', Plan.Plan_Name);
                    IsMemberOfPlan[columnNumber - PermissionPagesMgt.GetOffset] := IsUserGroupInPlan(Code, Plan.Plan_ID);
                end;
            end;
        end;
    end;

    local procedure IsUserGroupInPlan(UserGroupCode: Code[20]; PlanID: Guid): Boolean
    var
        UserGroupPlan: Record "User Group Plan";
    begin
        exit(UserGroupPlan.Get(PlanID, UserGroupCode));
    end;
}

