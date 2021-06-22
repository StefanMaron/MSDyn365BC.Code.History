page 5349 "CRM Case List"
{
    ApplicationArea = Suite, Service;
    Caption = 'Cases - Microsoft Dynamics 365 Sales';
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Dynamics 365 Sales';
    SourceTable = "CRM Incident";
    SourceTableView = SORTING(Title);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Title; Title)
                {
                    ApplicationArea = Suite;
                    Caption = 'Case Title';
                    ToolTip = 'Specifies the name of the case.';
                }
                field(StateCode; StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    OptionCaption = 'Active,Resolved,Canceled';
                    ToolTip = 'Specifies the status of the case.';
                }
                field(TicketNumber; TicketNumber)
                {
                    ApplicationArea = Suite;
                    Caption = 'Case Number';
                    ToolTip = 'Specifies the number of the case.';
                }
                field(CreatedOn; CreatedOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Created On';
                    ToolTip = 'Specifies when the sales order was created.';
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
                action(CRMGoToCase)
                {
                    ApplicationArea = Suite;
                    Caption = 'Case';
                    Image = CoupledOrder;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View the case.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(DATABASE::"CRM Incident", IncidentId));
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;
}

