page 5123 "Opportunity List"
{
    AdditionalSearchTerms = 'prospects';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Opportunities';
    CardPageID = "Opportunity Card";
    DataCaptionExpression = Caption;
    Editable = false;
    PageType = List;
    SourceTable = Opportunity;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Closed; Closed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the opportunity is closed.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date that the opportunity was created.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the opportunity.';
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact that this opportunity is linked to.';
                }
                field("Contact Company No."; "Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the company that is linked to this opportunity.';
                    Visible = false;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the salesperson that is responsible for the opportunity.';
                }
                field(Status; Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the opportunity. There are four options:';
                }
                field("Sales Cycle Code"; "Sales Cycle Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the sales cycle that the opportunity is linked to.';
                    Visible = false;
                }
                field(CurrSalesCycleStage; CurrSalesCycleStage)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Current Sales Cycle Stage';
                    ToolTip = 'Specifies the current sales cycle stage of the opportunity.';
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign to which this opportunity is linked.';
                }
                field("Campaign Description"; "Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the campaign to which the opportunity is linked. The program automatically fills in this field when you have entered a number in the Campaign No. field.';
                }
                field("Sales Document Type"; "Sales Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the sales document (Quote, Order, Posted Invoice). The combination of Sales Document No. and Sales Document Type specifies which sales document is assigned to the opportunity.';
                }
                field("Sales Document No."; "Sales Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the sales document that has been created for this opportunity.';
                }
                field("Estimated Closing Date"; "Estimated Closing Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated closing date of the opportunity.';
                }
                field("Estimated Value (LCY)"; "Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of the opportunity.';
                }
                field("Calcd. Current Value (LCY)"; "Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the current calculated value of the opportunity.';
                }
            }
            group(Control45)
            {
                ShowCaption = false;
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the No. field.';
                }
                field("Contact Company Name"; "Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the company of the contact person to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the Contact Company No. field.';
                }
            }
        }
        area(factboxes)
        {
            part(Control5; "Opportunity Statistics FactBox")
            {
                ApplicationArea = RelationshipMgmt;
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Opportunity)
            {
                Caption = 'Oppo&rtunity';
                Image = Opportunity;
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
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
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Opportunity No." = FIELD("No.");
                    RunPageView = SORTING("Opportunity No.", Date);
                    Scope = Repeater;
                    ToolTip = 'View postponed interactions for opportunities.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Opportunity No." = FIELD("No."),
                                  "System To-do Type" = FILTER(Organizer);
                    RunPageView = SORTING("Opportunity No.");
                    ToolTip = 'View all marketing tasks that involve the opportunity. ';
                }
                action("Co&mments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Co&mments';
                    Image = ViewComments;
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
                    Scope = Repeater;
                    ToolTip = 'Show the assigned sales quote.';

                    trigger OnAction()
                    begin
                        ShowSalesQuoteWithCheck;
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
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Update)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Update';
                    Enabled = OppInProgress;
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Update all the actions that are related to your opportunities.';

                    trigger OnAction()
                    begin
                        UpdateOpportunity;
                    end;
                }
                action(Close)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Close';
                    Enabled = OppNotStarted OR OppInProgress;
                    Image = Close;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Close all the actions that are related to your opportunities.';

                    trigger OnAction()
                    begin
                        CloseOpportunity;
                    end;
                }
                action("Activate First Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activate First Stage';
                    Enabled = OppNotStarted;
                    Image = "Action";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Specify if the opportunity is to be activated. The status is set to In Progress.';

                    trigger OnAction()
                    begin
                        StartActivateFirstStage;
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
                    Scope = Repeater;
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
                    Scope = Repeater;
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
    begin
        CalcFields("Contact Name", "Contact Company Name");
        OppNotStarted := Status = Status::"Not Started";
        OppInProgress := Status = Status::"In Progress";
    end;

    trigger OnAfterGetRecord()
    var
        SalesCycleStage: Record "Sales Cycle Stage";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CalcFields("Current Sales Cycle Stage");
        CurrSalesCycleStage := '';
        if SalesCycleStage.Get("Sales Cycle Code", "Current Sales Cycle Stage") then
            CurrSalesCycleStage := SalesCycleStage.Description;

        if CRMIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        RecordsFound: Boolean;
    begin
        RecordsFound := Find(Which);
        exit(RecordsFound);
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CurrPage.Editable := true;
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
    end;

    var
        Text001: Label 'untitled';
        OppNotStarted: Boolean;
        OppInProgress: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        CurrSalesCycleStage: Text;

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        case true of
            BuildCaptionContact(CaptionStr, GetFilter("Contact Company No.")),
          BuildCaptionContact(CaptionStr, GetFilter("Contact No.")),
          BuildCaptionSalespersonPurchaser(CaptionStr, GetFilter("Salesperson Code")),
          BuildCaptionCampaign(CaptionStr, GetFilter("Campaign No.")),
          BuildCaptionSegmentHeader(CaptionStr, GetFilter("Segment No.")):
                exit(CaptionStr)
        end;

        exit(Text001);
    end;

    local procedure BuildCaptionContact(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        Contact: Record Contact;
    begin
        with Contact do
            exit(BuildCaption(CaptionText, Contact, Filter, FieldNo("No."), FieldNo(Name)));
    end;

    local procedure BuildCaptionSalespersonPurchaser(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        with SalespersonPurchaser do
            exit(BuildCaption(CaptionText, SalespersonPurchaser, Filter, FieldNo(Code), FieldNo(Name)));
    end;

    local procedure BuildCaptionCampaign(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        Campaign: Record Campaign;
    begin
        with Campaign do
            exit(BuildCaption(CaptionText, Campaign, Filter, FieldNo("No."), FieldNo(Description)));
    end;

    local procedure BuildCaptionSegmentHeader(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        SegmentHeader: Record "Segment Header";
    begin
        with SegmentHeader do
            exit(BuildCaption(CaptionText, SegmentHeader, Filter, FieldNo("No."), FieldNo(Description)));
    end;

    local procedure BuildCaption(var CaptionText: Text[260]; RecVar: Variant; "Filter": Text; IndexFieldNo: Integer; TextFieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        IndexFieldRef: FieldRef;
        TextFieldRef: FieldRef;
    begin
        Filter := DelChr(Filter, '<>', '''');
        if Filter <> '' then begin
            RecRef.GetTable(RecVar);
            IndexFieldRef := RecRef.Field(IndexFieldNo);
            IndexFieldRef.SetRange(Filter);
            if RecRef.FindFirst then begin
                TextFieldRef := RecRef.Field(TextFieldNo);
                CaptionText := CopyStr(Format(IndexFieldRef.Value) + ' ' + Format(TextFieldRef.Value), 1, MaxStrLen(CaptionText));
            end;
        end;

        exit(Filter <> '');
    end;
}

