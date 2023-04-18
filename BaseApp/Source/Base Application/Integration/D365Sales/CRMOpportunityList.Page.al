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
                field(Name; Rec.Name)
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
        area(processing)
        {
            action(CreateFromCRM)
            {
                ApplicationArea = Suite;
                Caption = 'Create in Business Central';
                Image = NewOpportunity;
                ToolTip = 'Generate an opportunity from the coupled Dynamics 365 Sales opportunity.';

                trigger OnAction()
                var
                    CRMOpportunity: Record "CRM Opportunity";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CRMOpportunity);
                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CRMOpportunity);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Opportunities';
                Image = FilterLines;
                ToolTip = 'Do not show coupled opportunities.';

                trigger OnAction()
                begin
                    MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Opportunities';
                Image = ClearFilter;
                ToolTip = 'Show coupled opportunities.';

                trigger OnAction()
                begin
                    MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateFromCRM_Promoted; CreateFromCRM)
                {
                }
                group(Category_Synchronize)
                {
                    Caption = 'Synchronize';

                    actionref(CRMGotoOpportunities_Promoted; CRMGotoOpportunities)
                    {
                    }
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Dynamics 365 Sales', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
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
                Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Mark(true);
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

