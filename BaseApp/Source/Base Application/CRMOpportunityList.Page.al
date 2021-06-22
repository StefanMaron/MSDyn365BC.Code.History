page 5343 "CRM Opportunity List"
{
    ApplicationArea = Suite;
    Caption = 'Opportunities - Microsoft Dynamics 365 Sales';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Dynamics 365 Sales';
    SourceTable = "CRM Opportunity";
    SourceTableView = SORTING(Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(StateCode; StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    OptionCaption = 'Open,Won,Lost';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(StatusCode; StatusCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status Reason';
                    OptionCaption = ' ,In Progress,On Hold,Won,Canceled,Out-Sold';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Topic';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(EstimatedCloseDate; EstimatedCloseDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Est. Close Date';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(EstimatedValue; EstimatedValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Est. Revenue';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(ParentContactIdName; ParentContactIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact Name';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(ParentAccountIdName; ParentAccountIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Account Name';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(CloseProbability; CloseProbability)
                {
                    ApplicationArea = Suite;
                    Caption = 'Probability';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(OpportunityRatingCode; OpportunityRatingCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Rating';
                    OptionCaption = 'Hot,Warm,Cold';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(Need; Need)
                {
                    ApplicationArea = Suite;
                    Caption = 'Need';
                    OptionCaption = ' ,Must have,Should have,Good to have,No need';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                action(CRMGotoOpportunities)
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunity';
                    Image = CoupledOpportunity;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Specifies the sales opportunity that is coupled to this Dynamics 365 Sales opportunity.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(DATABASE::"CRM Opportunity", OpportunityId));
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(OpportunityId, DATABASE::Opportunity, RecordID) then
            if CurrentlyCoupledCRMOpportunity.OpportunityId = OpportunityId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
        end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        FilterGroup(4);
        SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Opportunity"));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMOpportunity: Record "CRM Opportunity";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMOpportunity(CRMOpportunity: Record "CRM Opportunity")
    begin
        CurrentlyCoupledCRMOpportunity := CRMOpportunity;
    end;
}

