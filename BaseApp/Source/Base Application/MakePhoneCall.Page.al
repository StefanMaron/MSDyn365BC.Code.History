page 5147 "Make Phone Call"
{
    Caption = 'Make Phone Call';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Segment Line";

    layout
    {
        area(content)
        {
            group("Phone Call")
            {
                Caption = 'Phone Call';
                field("Wizard Contact Name"; "Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    Editable = WizardContactNameEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a contact name from the wizard.';
                }
                field("Contact Via"; "Contact Via")
                {
                    ApplicationArea = RelationshipMgmt;
                    AssistEdit = true;
                    Caption = 'Contact Phone No.';
                    ExtendedDatatype = PhoneNo;
                    Importance = Promoted;
                    ToolTip = 'Specifies the telephone number you used when calling the contact, or the email address you used when sending an email to the contact.';

                    trigger OnAssistEdit()
                    var
                        TAPIManagement: Codeunit TAPIManagement;
                    begin
                        Clear(TAPIManagement);
                        "Contact Via" :=
                          CopyStr(TAPIManagement.ShowNumbers("Contact No.", "Contact Alt. Address Code"), 1, MaxStrLen("Contact Via"));
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Phone Call Description';
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the description of the segment line.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salesperson Code';
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the salesperson responsible for this segment line and/or interaction.';
                }
                field("Initiated By"; "Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Initiated By';
                    Importance = Additional;
                    ToolTip = 'Specifies whether the interaction recorded for this segment line was initiated by your company or by one of your contacts. The Us option indicates that your company was the initiator; the Them option indicates that a contact was the initiator.';
                }
                field(Date; Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Date';
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the contact was called.';
                }
                field("Time of Interaction"; "Time of Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Time of Interaction';
                    Importance = Promoted;
                    ToolTip = 'Specifies the time when the call to the contact started.';
                }                                
            }
            group("Phone Call Result")
            {
                Caption = 'Phone Call Result';
                field(Description2; Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Phone Call Result Description';
                    ToolTip = 'Specifies the description of the segment line.';
                }
                field("Cost (LCY)"; "Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Cost (LCY)';
                    Importance = Additional;
                    ToolTip = 'Specifies the cost of the interaction with the contact that this segment line applies to.';
                }
                field("Duration (Min.)"; "Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Duration (Min.)';
                    ToolTip = 'Specifies the duration of the interaction with the contact to which this segment line applies.';
                }
                field(Evaluation; Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Phone Call Evaluation';
                    ToolTip = 'Specifies the evaluation of the interaction involving the contact in the segment.';
                }
                field("Interaction Successful"; "Interaction Successful")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Successful Attempt';
                    ToolTip = 'Specifies if the interaction was successful. Clear this check box to indicate that the interaction was not a success.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Campaign Description"; "Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign Description';
                    Editable = CampaignDescriptionEditable;
                    Importance = Promoted;
                    Lookup = false;
                    TableRelation = Campaign;
                    ToolTip = 'Specifies a description of the campaign that is related to the segment. The description is copied from the campaign card.';

                    trigger OnAssistEdit()
                    var
                        Campaign: Record Campaign;
                    begin
                        if Campaign.Get("Campaign No.") then;
                        if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                            Validate("Campaign No.", Campaign."No.");
                            "Campaign Description" := Campaign.Description;
                            CurrPage.SetSelectionFilter(Rec);
                        end;
                    end;
                }
                field("Campaign Target"; "Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign Target';
                    Editable = CampaignTargetEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies that the segment involved in this interaction is the target of a campaign. This is used to measure the response rate of a campaign.';
                }
                field("Campaign Response"; "Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign Response';
                    Editable = CampaignResponseEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies that the interaction created for the segment is the response to a campaign. For example, coupons that are sent as a response to a campaign.';
                }
                field("Opportunity Description"; "Opportunity Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity Description';
                    Editable = OpportunityDescriptionEditable;
                    Importance = Promoted;
                    Lookup = false;
                    TableRelation = Opportunity;
                    ToolTip = 'Specifies a description of the opportunity that is related to the segment. The description is copied from the opportunity card.';

                    trigger OnAssistEdit()
                    var
                        Opportunity: Record Opportunity;
                    begin
                        FilterContactCompanyOpportunities(Opportunity);
                        if PAGE.RunModal(0, Opportunity) = ACTION::LookupOK then begin
                            Validate("Opportunity No.", Opportunity."No.");
                            "Opportunity Description" := Opportunity.Description;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Make Phone Call")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Make Phone Call';
                Image = Calls;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Call the selected contact.';

                trigger OnAction()
                begin
                    CheckPhoneCallStatus;
                    HyperLink(StrSubstNo('tel:%1', "Contact Via"));
                end;
            }
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    LogCall;
                    CurrPage.Close;
                end;
            }
            action(OpenCommentsPage)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Co&mments';
                Image = ViewComments;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View or add comments for the record.';

                trigger OnAction()
                begin
                    ShowComment;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        CampaignTargetEditable := true;
        CampaignResponseEditable := true;
        OpportunityDescriptionEditable := true;
        CampaignDescriptionEditable := true;
    end;

    trigger OnOpenPage()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        CampaignDescriptionEditable := false;
        OpportunityDescriptionEditable := false;
        WizardContactNameEditable := (GetFilter("Contact No.") = '') and (GetFilter("Contact Company No.") = '');
        if Campaign.Get(GetFilter("Campaign No.")) then begin
            CampaignResponseEditable := false;
            CampaignTargetEditable := false;
        end;
        IsOnMobile := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            if Confirm(CreateOpportunityQst) then
                Validate("Opportunity No.", CreateOpportunity);

            LogCall;
        end;
    end;

    var
        Text001: Label 'untitled';
        Campaign: Record Campaign;
        [InDataSet]
        CampaignDescriptionEditable: Boolean;
        [InDataSet]
        OpportunityDescriptionEditable: Boolean;
        [InDataSet]
        WizardContactNameEditable: Boolean;
        [InDataSet]
        CampaignResponseEditable: Boolean;
        [InDataSet]
        CampaignTargetEditable: Boolean;
        IsOnMobile: Boolean;
        CreateOpportunityQst: Label 'Do you want to create an opportunity?';

    procedure Caption(): Text
    var
        Contact: Record Contact;
        CaptionStr: Text;
    begin
        if Contact.Get(GetFilter("Contact Company No.")) then
            CaptionStr := CopyStr(Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if Contact.Get(GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text001;

        exit(CaptionStr);
    end;

    local procedure LogCall()
    begin
        CheckPhoneCallStatus;
        LogPhoneCall;
    end;
}

