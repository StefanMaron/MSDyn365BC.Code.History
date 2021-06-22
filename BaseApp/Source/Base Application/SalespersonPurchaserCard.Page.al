page 5116 "Salesperson/Purchaser Card"
{
    Caption = 'Salesperson/Purchaser Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Navigate,Salesperson';
    SourceTable = "Salesperson/Purchaser";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code for the salesperson or purchaser.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the salesperson or purchaser.';
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the salesperson''s job title.';
                }
                field("Commission %"; "Commission %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the percentage to use to calculate the salesperson''s commission.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the salesperson''s telephone number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = RelationshipMgmt;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the salesperson''s email address.';
                }
                field("Next Task Date"; "Next Task Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date of the next task assigned to the salesperson.';
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
            }
        }
        area(factboxes)
        {
            part(Control3; "Salesperson/Purchaser Picture")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Code = FIELD(Code);
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
            group("&Salesperson")
            {
                Caption = '&Salesperson';
                Image = SalesPerson;
                action("Tea&ms")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Tea&ms';
                    Image = TeamSales;
                    Promoted = true;
                    PromotedCategory = Category4;
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Contact List";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View a list of contacts that are associated with the salesperson/purchaser.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(13),
                                  "No." = FIELD(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category5;
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
                    Promoted = true;
                    PromotedCategory = Category4;
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Segment List";
                    RunPageLink = "Salesperson Code" = FIELD(Code);
                    RunPageView = SORTING("Salesperson Code");
                    ToolTip = 'View a list of all segments.';
                }
                separator(Action33)
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
                    ToolTip = 'View interaction log entries for the salesperson/purchaser.';
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
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(RecordId);
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
            action("Create &Interaction")
            {
                AccessByPermission = TableData Attachment = R;
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create &Interaction';
                Image = CreateInteraction;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create an interaction with a specified contact.';

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
        if CRMIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
            if Code <> xRec.Code then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if xRec.Code = '' then
            Reset;
    end;

    trigger OnOpenPage()
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
}

