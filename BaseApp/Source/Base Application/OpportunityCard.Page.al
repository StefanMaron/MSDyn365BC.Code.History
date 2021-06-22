page 5124 "Opportunity Card"
{
    Caption = 'Opportunity Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Opportunity';
    RefreshOnActivate = true;
    SourceTable = Opportunity;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the opportunity.';
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = ContactNoEditable;
                    ToolTip = 'Specifies the number of the contact that this opportunity is linked to.';

                    trigger OnValidate()
                    var
                        Contact: Record Contact;
                    begin
                        if "Contact No." <> '' then
                            if Contact.Get("Contact No.") then
                                Contact.CheckIfPrivacyBlockedGeneric;
                        ContactNoOnAfterValidate;
                    end;
                }
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the contact to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the No. field.';
                }
                field("Contact Company Name"; "Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the company of the contact person to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the Contact Company No. field.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Editable = SalespersonCodeEditable;
                    ToolTip = 'Specifies the code of the salesperson that is responsible for the opportunity.';
                }
                field("Sales Document Type"; "Sales Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesDocumentTypeEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the type of the sales document (Quote, Order, Posted Invoice). The combination of Sales Document No. and Sales Document Type specifies which sales document is assigned to the opportunity.';
                    ValuesAllowed = " ", Quote, Order;
                }
                field("Sales Document No."; "Sales Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesDocumentNoEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the sales document that has been created for this opportunity.';
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = CampaignNoEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the campaign to which this opportunity is linked.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = PriorityEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the priority of the opportunity. There are three options:';
                }
                field("Sales Cycle Code"; "Sales Cycle Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = SalesCycleCodeEditable;
                    ToolTip = 'Specifies the code of the sales cycle that the opportunity is linked to.';
                }
                field(Status; Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the opportunity. There are four options:';
                }
                field(Closed; Closed)
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies that the opportunity is closed.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the date that the opportunity was created.';
                }
                field("Date Closed"; "Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date the opportunity was closed.';
                }
                field("Segment No."; "Segment No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the segment (if any) that is linked to the opportunity.';
                }
            }
            part(Control25; "Opportunity Subform")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "Opportunity No." = FIELD("No.");
            }
        }
        area(factboxes)
        {
            part(Control7; "Opportunity Statistics FactBox")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Statistics';
                SubPageLink = "No." = FIELD("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Oppo&rtunity")
            {
                Caption = 'Oppo&rtunity';
                Image = Opportunity;
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Opportunity Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Opportunity No." = FIELD("No.");
                    RunPageView = SORTING("Opportunity No.", Date);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Opportunity No." = FIELD("No.");
                    RunPageView = SORTING("Opportunity No.", Date);
                    ToolTip = 'View postponed interactions for opportunities.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Task List";
                    RunPageLink = "Opportunity No." = FIELD("No."),
                                  "System To-do Type" = FILTER(Organizer);
                    RunPageView = SORTING("Opportunity No.");
                    ToolTip = 'View all marketing tasks that involve the opportunity.';
                }
                action("Co&mments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Opportunity),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Show Sales Quote")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Show Sales Quote';
                    Image = Quote;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Show the assigned sales quote.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        if ("Sales Document Type" <> "Sales Document Type"::Quote) or
                           ("Sales Document No." = '')
                        then
                            Error(Text001);

                        if SalesHeader.Get(SalesHeader."Document Type"::Quote, "Sales Document No.") then
                            PAGE.Run(PAGE::"Sales Quote", SalesHeader)
                        else
                            Error(Text002, "Sales Document No.");
                    end;
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGotoOpportunity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunity';
                    Image = CoupledContactPerson;
                    ToolTip = 'Open the coupled Dynamics 365 Sales opportunity.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        Opportunity: Record Opportunity;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        OpportunityRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Opportunity);
                        Opportunity.Next;

                        if Opportunity.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Opportunity.RecordId)
                        else begin
                            OpportunityRecordRef.GetTable(Opportunity);
                            CRMIntegrationManagement.UpdateMultipleNow(OpportunityRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales opportunity.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales opportunity.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the opportunity table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(RecordId);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Activate the First Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activate First Stage';
                    Image = "Action";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Specify if the opportunity is to be activated. The status is set to In Progress.';
                    Visible = NOT Started;

                    trigger OnAction()
                    begin
                        StartActivateFirstStage;
                    end;
                }
                action(Update)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Update';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Update all the actions that are related to your opportunity.';
                    Visible = Started;

                    trigger OnAction()
                    begin
                        UpdateOpportunity;
                    end;
                }
                action(CloseOpportunity)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Close';
                    Image = Close;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Close all the actions that are related to your opportunity.';
                    Visible = Started;

                    trigger OnAction()
                    begin
                        CloseOpportunity;
                    end;
                }
                action(CreateSalesQuote)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Sales &Quote';
                    Enabled = OppInProgress;
                    Image = Allocate;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create a new sales quote with the opportunity inserted as the customer.';

                    trigger OnAction()
                    begin
                        CreateQuote;
                    end;
                }
                action("Print Details")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print Details';
                    Image = Print;
                    ToolTip = 'View information about your sales stages, activities and planned tasks for an opportunity.';

                    trigger OnAction()
                    var
                        Opp: Record Opportunity;
                    begin
                        Opp := Rec;
                        Opp.SetRecFilter;
                        REPORT.Run(REPORT::"Opportunity - Details", true, false, Opp);
                    end;
                }
                action("Create &Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create &Interaction';
                    Image = CreateInteraction;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create an interaction with a specified opportunity.';

                    trigger OnAction()
                    var
                        TempSegmentLine: Record "Segment Line" temporary;
                    begin
                        TempSegmentLine.CreateInteractionFromOpp(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Contact: Record Contact;
    begin
        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric;
        if "Contact Company No." <> '' then
            if Contact.Get("Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric;
        UpdateEditable;
        OppInProgress := Status = Status::"In Progress";
        OppNo := "No.";
    end;

    trigger OnAfterGetRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CRMIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
    end;

    trigger OnInit()
    begin
        ContactNoEditable := true;
        PriorityEditable := true;
        CampaignNoEditable := true;
        SalespersonCodeEditable := true;
        SalesDocumentTypeEditable := true;
        SalesDocumentNoEditable := true;
        SalesCycleCodeEditable := true;
        Started := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Creation Date" := WorkDate;
        if "Segment No." = '' then
            SetSegmentFromFilter;
        if "Contact No." = '' then
            SetContactFromFilter;
        if "Campaign No." = '' then
            SetCampaignFromFilter;
        SetDefaultSalesCycle;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        OppNo := "No.";
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Get("No.") then
            if ("No." <> OppNo) and (Status = Status::"Not Started") then
                StartActivateFirstStage;
    end;

    var
        Text001: Label 'There is no sales quote assigned to this opportunity.';
        Text002: Label 'Sales quote %1 doesn''t exist.';
        OppNo: Code[20];
        [InDataSet]
        SalesCycleCodeEditable: Boolean;
        [InDataSet]
        SalesDocumentNoEditable: Boolean;
        [InDataSet]
        SalesDocumentTypeEditable: Boolean;
        [InDataSet]
        SalespersonCodeEditable: Boolean;
        [InDataSet]
        CampaignNoEditable: Boolean;
        [InDataSet]
        PriorityEditable: Boolean;
        [InDataSet]
        ContactNoEditable: Boolean;
        Started: Boolean;
        OppInProgress: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;

    local procedure UpdateEditable()
    begin
        Started := (Status <> Status::"Not Started");
        SalesCycleCodeEditable := Status = Status::"Not Started";
        SalespersonCodeEditable := Status < Status::Won;
        CampaignNoEditable := Status < Status::Won;
        PriorityEditable := Status < Status::Won;
        ContactNoEditable := Status < Status::Won;
        SalesDocumentNoEditable := Status = Status::"In Progress";
        SalesDocumentTypeEditable := Status = Status::"In Progress";
    end;

    local procedure ContactNoOnAfterValidate()
    begin
        CalcFields("Contact Name", "Contact Company Name");
    end;
}

