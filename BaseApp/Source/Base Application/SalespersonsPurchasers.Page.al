page 14 "Salespersons/Purchasers"
{
    AdditionalSearchTerms = 'sales representative';
    ApplicationArea = Basic, Suite;
    Caption = 'Salespeople/Purchasers';
    CardPageID = "Salesperson/Purchaser Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Salesperson';
    SourceTable = "Salesperson/Purchaser";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("Commission %"; "Commission %")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the percentage to use to calculate the salesperson''s commission.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the salesperson''s or purchaser''s telephone number.';
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
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
            group("&Salesperson")
            {
                Caption = '&Salesperson';
                Image = SalesPerson;
                action("Tea&ms")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Tea&ms';
                    Image = TeamSales;
                    RunObject = Page "Salesperson Teams";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View or edit any teams that the salesperson/purchaser is a member of.';
                }
                action("Con&tacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Con&tacts';
                    Image = CustomerContact;
                    RunObject = Page "Contact List";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View a list of contacts that are associated with the salesperson/purchaser.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        Promoted = true;
                        PromotedCategory = Category4;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(13),
                                      "No." = FIELD(Code);
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        Promoted = true;
                        PromotedCategory = Category4;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            SalespersonPurchaser: Record "Salesperson/Purchaser";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(SalespersonPurchaser);
                            DefaultDimMultiple.SetMultiRecord(SalespersonPurchaser, FieldNo(Code));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Salesperson Statistics";
                    RunPageLink = Code = FIELD(Code);
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("C&ampaigns")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'C&ampaigns';
                    Image = Campaign;
                    RunObject = Page "Campaign List";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View or edit any campaigns that the salesperson/purchaser is assigned to.';
                }
                action("S&egments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'S&egments';
                    Image = Segment;
                    RunObject = Page "Segment List";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View a list of all segments.';
                }
                separator(Action22)
                {
                    Caption = '';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View postponed interactions for the salesperson/purchaser.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Salesperson Code" = FIELD(Code),
                                  "System To-do Type" = FILTER(Organizer | "Salesperson Attendee");
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View tasks for the salesperson/purchaser.';
                }
                action("Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Oppo&rtunities';
                    Image = OpportunitiesList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View opportunities for the salesperson/purchaser.';
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGotoSystemUser)
                {
                    ApplicationArea = Suite;
                    Caption = 'User';
                    Image = CoupledUser;
                    ToolTip = 'Open the coupled Dynamics 365 Sales system user.';

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
                        SalespersonPurchaser: Record "Salesperson/Purchaser";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        SalespersonPurchaserRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(SalespersonPurchaser);
                        SalespersonPurchaser.Next;

                        if SalespersonPurchaser.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId)
                        else begin
                            SalespersonPurchaserRecordRef.GetTable(SalespersonPurchaser);
                            CRMIntegrationManagement.UpdateMultipleNow(SalespersonPurchaserRecordRef);
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
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales user.';

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
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales user.';

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
                    ToolTip = 'View integration synchronization jobs for the salesperson/purchaser table.';

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
            action(CreateInteraction)
            {
                AccessByPermission = TableData Attachment = R;
                ApplicationArea = All;
                Caption = 'Create &Interaction';
                Ellipsis = true;
                Image = CreateInteraction;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Use a batch job to help you create interactions for the involved salespeople or purchasers.';
                Visible = CreateInteractionVisible;

                trigger OnAction()
                begin
                    CreateInteraction;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CRMIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
    end;

    trigger OnInit()
    var
        SegmentLine: Record "Segment Line";
    begin
        CreateInteractionVisible := SegmentLine.ReadPermission;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
    end;

    var
        [InDataSet]
        CreateInteractionVisible: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;

    procedure GetSelectionFilter(): Text
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(SalespersonPurchaser);
        exit(SelectionFilterManagement.GetSelectionFilterForSalesPersonPurchaser(SalespersonPurchaser));
    end;
}

