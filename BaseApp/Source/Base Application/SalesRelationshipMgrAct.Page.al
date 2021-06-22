page 9076 "Sales & Relationship Mgr. Act."
{
    Caption = 'Activities';
    PageType = CardPart;
    SourceTable = "Relationship Mgmt. Cue";

    layout
    {
        area(content)
        {
            cuegroup("Intelligent Cloud")
            {
                Caption = 'Intelligent Cloud';
                Visible = ShowIntelligentCloud;

                actions
                {
                    action("Learn More")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Learn More';
                        Image = TileInfo;
                        RunPageMode = View;
                        ToolTip = ' Learn more about the Intelligent Cloud and how it can help your business.';

                        trigger OnAction()
                        var
                            IntelligentCloudManagement: Codeunit "Intelligent Cloud Management";
                        begin
                            HyperLink(IntelligentCloudManagement.GetIntelligentCloudLearnMoreUrl);
                        end;
                    }
                    action("Intelligent Cloud Insights")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Intelligent Cloud Insights';
                        Image = TileCloud;
                        RunPageMode = View;
                        ToolTip = 'View your Intelligent Cloud insights.';

                        trigger OnAction()
                        var
                            IntelligentCloudManagement: Codeunit "Intelligent Cloud Management";
                        begin
                            HyperLink(IntelligentCloudManagement.GetIntelligentCloudInsightsUrl);
                        end;
                    }
                }
            }
            cuegroup(Contacts)
            {
                Caption = 'Contacts';
                field("Contacts - Companies"; "Contacts - Companies")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Contact List";
                    ToolTip = 'Specifies contacts assigned to a company.';
                }
                field("Contacts - Persons"; "Contacts - Persons")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Contact List";
                    ToolTip = 'Specifies contact persons.';
                }
                field("Contacts - Duplicates"; "Contacts - Duplicates")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Contact Duplicates";
                    ToolTip = 'Specifies contacts that have duplicates.';
                }
            }
            cuegroup(Opportunities)
            {
                Caption = 'Opportunities';
                field("Open Opportunities"; "Open Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Opportunity List";
                    ToolTip = 'Specifies open opportunities.';
                }
                field("Opportunities Due in 7 Days"; "Opportunities Due in 7 Days")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Opportunity Entries";
                    Style = Favorable;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies opportunities with a due date in seven days or more.';
                }
                field("Overdue Opportunities"; "Overdue Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Opportunity Entries";
                    Style = Unfavorable;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies opportunities that have exceeded the due date.';
                }
                field("Closed Opportunities"; "Closed Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Opportunity List";
                    ToolTip = 'Specifies opportunities that have been closed.';
                }
            }
            cuegroup(Sales)
            {
                Caption = 'Sales';
                field("Open Sales Quotes"; "Open Sales Quotes")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies the number of sales quotes that are not yet converted to invoices or orders.';
                }
                field("Open Sales Orders"; "Open Sales Orders")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales orders that are not fully posted.';
                }
                field("Active Campaigns"; "Active Campaigns")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Campaign List";
                    ToolTip = 'Specifies marketing campaigns that are active.';
                }
            }
            cuegroup("Data Integration")
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationCues;
                field("CDS Integration Errors"; "CDS Integration Errors")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Integration Errors';
                    DrillDownPageID = "Integration Synch. Error List";
                    ToolTip = 'Specifies the number of errors related to data integration.';
                    Visible = ShowIntegrationErrorsCue;
                }
                field("Coupled Data Synch Errors"; "Coupled Data Synch Errors")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Coupled Data Synchronization Errors';
                    DrillDownPageID = "CRM Skipped Records";
                    ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Sales.';
                    Visible = ShowD365SIntegrationCues;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CuesAndKpis: Codeunit "Cues And KPIs";
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetFilter("Due Date Filter", '<>%1&%2..%3', 0D, WorkDate, WorkDate + 7);
        SetFilter("Overdue Date Filter", '<>%1&..%2', 0D, WorkDate - 1);
        ShowIntelligentCloud := not EnvironmentInfo.IsSaaS;
        IntegrationSynchJobErrors.SetDataIntegrationUIElementsVisible(ShowDataIntegrationCues);
        ShowD365SIntegrationCues := CRMConnectionSetup.IsEnabled() or CDSIntegrationMgt.IsIntegrationEnabled();
        ShowIntegrationErrorsCue := ShowDataIntegrationCues and (not ShowD365SIntegrationCues);
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        ShowIntelligentCloud: Boolean;
        ShowD365SIntegrationCues: Boolean;
        ShowDataIntegrationCues: Boolean;
        ShowIntegrationErrorsCue: Boolean;
}

